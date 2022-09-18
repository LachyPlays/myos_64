#ifndef VGA_H
#define VGA_H

#define WHITE_ON_BLACK 0x0F

void writeChar(char character, char colourCode);
void newLine();

#endif