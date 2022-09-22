#include <kstdio.h>
#include <kstdlib.h>

__attribute__((__noreturn__))
void abort(void) {
    kprintf("Kernel: panic: abort()\n");
    asm volatile("hlt");
}
