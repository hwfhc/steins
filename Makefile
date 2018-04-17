bootblock := ./bin/bootblock
kernel := ./bin/kernel
IMG := ./bin/steins.img
MKDIR := mkdir -p

$(kernel): ./kern/init/init.o
	mkdir -p bin
	mkdir -p obj
	mkdir -p obj/boot
	mkdir -p obj/kern
	mkdir -p obj/kern/init
	mkdir -p obj/sign
	mkdir -p obj/sign/tools
	gcc -Ikern/init/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -c kern/init/init.c -o obj/kern/init/init.o
	ld -m elf_i386 -nostdlib -o ./bin/kernel obj/kern/init/init.o
	
$(bootblock): ./boot/bootasm.S ./boot/bootmain.c
	gcc -Itools/ -g -Wall -O2 -c tools/sign.c -o obj/sign/tools/sign.o
	gcc -g -Wall -O2 obj/sign/tools/sign.o -o bin/sign
	gcc -Iboot/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -c boot/bootmain.c -o obj/boot/bootmain.o
	as --32 -o ./obj/boot/bootasm.o ./boot/bootasm.S
	ld -m elf_i386 -nostdlib -N -e start -Ttext 0x7C00 obj/boot/bootasm.o obj/boot/bootmain.o -o obj/bootblock.o
	objdump -S obj/bootblock.o > obj/bootblock.asm
	objcopy -S -O binary obj/bootblock.o obj/bootblock.out
	bin/sign obj/bootblock.out $@

$(IMG): $(kernel) $(bootblock)
	touch $@
	dd if=$(bootblock) of=$@ conv=notrunc
	dd if=$(kernel) of=$@ seek=1 conv=notrunc

.DEFAULT_GOAL = $(IMG)

.PHONY: debug
debug: $(IMG)
	qemu-system-i386 -S -s -parallel stdio -hda $< -serial null &
	sleep 2
	gnome-terminal -e "gdb -q -tui -x tools/gdbinit"

.PHONY: clean
clean:
	rm -r bin obj
