kernel := bin/kernel
IMG := bin/steins.img

GCCFLAGS := -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector
LDFLAGS := -m elf_i386 -nostdlib -N -e start
CTYPES := c S

ToObj = $(addprefix obj/,$(addsuffix .o,$(basename $(1))))
ToBin = $(addprefix bin/,$(1))
ToOut = $(addprefix obj/,$(addsuffix .out,$(basename $(1))))
ToAsm = $(addprefix obj/,$(addsuffix .asm,$(basename $(1))))

listf = $(filter $(if $(2),$(addprefix %.,$(2)),%),\
		  $(wildcard $(addsuffix /*,$(1))))
ListFiles = $(call listf,$(1),$(CTYPES))

compile = gcc -Iboot/ $(GCCFLAGS) -c $(1) -o $(2)\n

$(kernel): ./kern/init/init.o
	mkdir -p bin
	mkdir -p obj/boot
	mkdir -p obj/kern/init
	gcc -Ikern/init/ -fno-builtin -Wall -ggdb -m32 -gstabs -nostdinc  -fno-stack-protector -c kern/init/init.c -o obj/kern/init/init.o
	ld -m elf_i386 -nostdlib -o ./bin/kernel obj/kern/init/init.o

bootfiles = $(call ListFiles,boot)
bootblock = $(call ToBin,bootblock)

sign = $(call ToBin,sign)

$(sign) : tools/sign.c
	mkdir -p $(call ToObj,$(dir $^))
	gcc -Itools/ -g -Wall -O2 -c $^ -o $(call ToObj,$^)
	gcc -g -Wall -O2 $(call ToObj,$^) -o $@

$(bootblock): $(bootfiles) | $(sign)
	$(foreach f,$(bootfiles),gcc -Iboot/ $(GCCFLAGS) -c $(f) -o $(call ToObj,$(f)) | ) :
	ld $(LDFLAGS) -Ttext 0x7C00 $(call ToObj,$^) -o $(call ToObj,bootblock)
	objdump -S $(call ToObj,bootblock) > $(call ToAsm,bootblock)
	objcopy -S -O binary $(call ToObj,bootblock) $(call ToOut,bootblock)
	$(sign) $(call ToOut,bootblock) $@

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
