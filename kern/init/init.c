#include <defs.h>
#include <x86.h>

#define LPTPORT         0x378

static void lpt_putc(int c);
static void printf(char* str);

int kern_init(void){
    char str[10] = "hello!\n";
    printf(str);
    while(1);
}

static void
delay(void) {
    inb(0x84);
}

/*
 * parallel port here is printer port
 *
 * 0x378: char to output
 * 0x379: state of lpt
 * 0x37A: control command for lpt
 *
 */
static void
lpt_putc_sub(int c) {
    int i;
    for (i = 0; !(inb(LPTPORT + 1) & 0x80) && i < 12800; i ++) {
        delay();
    }
    outb(LPTPORT + 0, c);
    outb(LPTPORT + 2, 0x08 | 0x04 | 0x01);
    outb(LPTPORT + 2, 0x08);
}

static void
lpt_putc(int c) {
    if (c != '\b') {
        lpt_putc_sub(c);
    }
    else {
        lpt_putc_sub('\b');
        lpt_putc_sub(' ');
        lpt_putc_sub('\b');
    }
}

static void
printf(char* str) {
    char* p = str;

    while(*p != '\0'){
        lpt_putc(*p);
        p++;
    }
}

