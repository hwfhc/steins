#include <asm.h>

.set PROT_MODE_CSEG,0x8
.set PROT_MODE_DSEG,0x10
.set CR0_PE_ON,0x1

.globl start
start:
.code16
    cli
    cld

    # init register
    xorw %ax,%ax
    movw %ax,%ds
    movw %ax,%es
    movw %ax,%ss

seta20.1:
    # get status of 8042
    # input buffer empty, represented by 0x2
    # then test the status again

    inb $0x64,%al
    testb $0x2,%al
    jnz seta20.1

    # tell 8042 that i want to write data to Output Port
    movb $0xd1,%al
    outb %al,$0x64

seta20.2:
    inb $0x64,%al
    testb $0x2,%al
    jnz seta20.2

    # write 0xdf to Output Port, and A20's bit is 1
    movb $0xdf,%al
    outb %al,$0x60

prob_init:
    movl $0,%ebx
    // size of memory
    movl $0,0x8000
    // address of memory dscriptor block
    movw $0x8004,%di

prob:
    movl $0xE820,%eax
    movl $0x534D4150,%edx
    movl $20,%ecx

    int $0x15
    jnc prob_continue
    movw $1234,0x8000
    jmp prob_finish

prob_continue:
    addw $20,%di
    incl 0x8000
    cmpl $0,%ebx
    jnz prob

prob_finish:
    # switch from real mode to protected mode,
    # through set %cr0 to 1
    lgdt gdtdesc
    movl %cr0,%eax
    orl $CR0_PE_ON,%eax
    movl %eax,%cr0

    ljmp $PROT_MODE_CSEG, $protcseg

.code32
protcseg:
    movw $PROT_MODE_DSEG,%ax
    movw %ax,%ds
    movw %ax,%es
    movw %ax,%fs
    movw %ax,%gs
    movw %ax,%ss

    movl $0x0,%ebp
    movl $start,%esp
    call bootmain

.p2align 2
gdt:
    SEG_NULLASM
    SEG_ASM(STA_X|STA_R,0x0,0xffffffff)
    SEG_ASM(STA_W,0x0,0xffffffff)

gdtdesc:
    .word 0x17
    .long gdt
