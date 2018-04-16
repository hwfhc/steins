IMG := ./bin/steins.img

$(IMG): ./boot/bootasm.S
	mkdir -p bin
	as -o ./boot/bootasm.o ./boot/bootasm.S
	ld -e 0 -Ttext=0x7c00 -o ./bin/steins.img --oformat=binary ./boot/bootasm.o

debug: $(IMG)
	qemu-system-i386 -S -s -parallel stdio -hda $< -serial null &
	sleep 2
	gnome-terminal -e "gdb -q -tui -x tools/gdbinit"
