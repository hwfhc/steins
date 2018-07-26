#include <defs.h>
#include <x86.h>

#define LPTPORT         0x378
#define KERNBASE        0x00000000
#define E820MAX             20      // number of entries in E820MAP

static void lpt_putc(int c);
static void printf(char* str);

/* char* int2str(int num){
    char str[10];
    int temp = num % 10 + 48;
    str[0] = temp;

    return str;
} */
struct e820map {
    int nr_map;
    struct {
        uint64_t addr;
        uint64_t size;
        uint32_t type;
    } __attribute__((packed)) map[E820MAX];
};



int kern_init(void){
    char str[10] = "0000000000\n";
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);

    int addr = 0x8000 + KERNBASE;
    unsigned int temp;

    asm volatile("movl %0,%%eax"::"m"(addr));
    asm volatile("movl (%%eax),%0":"=r"(temp):);


    str[0] = temp % 10 + 48;
    temp = (temp - temp % 10)/10;
    str[1] = temp % 10 + 48;
    temp = (temp - temp % 10)/10;
    str[2] = temp % 10 + 48;
    temp = (temp - temp % 10)/10;
    str[3] = temp % 10 + 48;

    printf(str);

    // test();
    while(1);
}

void test(){
    char str[10] = "hello!\n";

    int value = 98;
    int temp;

    asm("movl %1,%0":"=r"(temp):"r"(value));
    str[0] = temp;

    printf(str);
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

