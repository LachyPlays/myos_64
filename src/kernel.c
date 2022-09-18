#include "arch/amd64/vga.h"

void kmain()
{
    const short color = 0x0F00;
    const char* hello = "Hello from C!";
    for(int i = 0; i < 14; i++){
        writeChar(hello[i], WHITE_ON_BLACK);
    }
}