.code16

movb $0xe, %ah
movb $'H', %al
int $0x10
movb $'e', %al
int $0x10
movb $'l', %al
int $0x10
movb $'l', %al
int $0x10
movb $'o', %al
int $0x10
movb $'!', %al
int $0x10

jmp .
.org 510
.word 0xaa55
