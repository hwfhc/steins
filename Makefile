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
	gcc -Ikern/init/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -c kern/init/init.c -o obj/kern/init/init.o
	ld -m elf_i386 -nostdlib -o ./bin/kernel obj/kern/init/init.o
	
$(bootblock): ./boot/bootasm.S
	mkdir -p bin
	as -o ./obj/boot/bootasm.o ./boot/bootasm.S
	#gcc -Iboot/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc -fno-stack-protector -c ./boot/bootmain.c -o ./obj/boot/bootmain.o
	ld -e 0 -Ttext=0x7c00 -o ./bin/bootblock --oformat=binary ./obj/boot/bootasm.o

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
