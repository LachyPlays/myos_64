#include "vga.h"

#define VGA_MEMORY 0xb8000
#define VGA_MEMORY_WIDTH 80
#define VGA_MEMORY_HEIGHT 20

struct writer {
    int row;
    int column;
};

// Interface for VGA text buffer
static struct writer WRITER = {0, 0};

// Writes an ASCII character and colour code to the VGA text buffer
void writeChar(char character, char colourCode){
    volatile short* vgabuffer = (short*)VGA_MEMORY;
    int index = (WRITER.row * VGA_MEMORY_WIDTH) + WRITER.column;

    vgabuffer[index] = (short)character | (WHITE_ON_BLACK << 8);
    
    if(WRITER.column > VGA_MEMORY_WIDTH){
        WRITER.column = 0;
        if(WRITER.row >= VGA_MEMORY_HEIGHT){
            scroll();
        } else {
            WRITER.row += 1;
        }
    } else {
        WRITER.column += 1;
    }
}

// Sets writer to next line
void newLine(){
    WRITER.column = 0;
    if(WRITER.row >= VGA_MEMORY_HEIGHT){
        scroll();
    } else {
        WRITER.row += 1;
    }
}

// Scrolls the VGA text buffer
void scroll(){
    volatile short* vgabuffer = (short*)VGA_MEMORY;

    for(int i = 0; i < (VGA_MEMORY_WIDTH * VGA_MEMORY_HEIGHT) - VGA_MEMORY_WIDTH; i++){
        vgabuffer[i] = vgabuffer[i + VGA_MEMORY_WIDTH];    
    }
    WRITER.row -= 1;
}