#include <defs.h>
#include <x86.h>

void
bootmain(void) {
    asm volatile (
            "movb $0x83,%eax\n"
            );

    while (1);
}

