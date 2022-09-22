rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

C_SOURCES = $(call rwildcard,src,*.c)
C_HEADERS = $(call rwildcard,src,*.h)
INCLUDE_C = $(call rwildcard,src/includes,*.c)
INCLUDE_H = $(call rwildcard,src/includes,*.h)
HEADERS = ${C_HEADERS} ${INCLUDE_H}
ASM = $(call rwildcard,src,*.asm)

OBJ = ${INCLUDES:.c=.o} ${C_SOURCES:.c=.o} ${ASM:.asm=.o}

CC = amd64-elf-gcc
CFLAGS = -I./src/kernel/includes -I./src/kernel/libk/includes -ffreestanding -mcmodel=large -mno-red-zone -mno-mmx -mno-sse -mno-sse2
LFLAGS = -T src/linker.ld -ffreestanding -O2 -nostdlib -lgcc

%.o: %.c ${HEADERS}
	-@${CC} ${CFLAGS} -c $< -o $@

%.o: %.asm ${ASM}
	-@nasm -felf64 -o $@ $<

all: run

myos.bin: ${OBJ}
	-@amd64-elf-gcc ${LFLAGS} -o $@ $^ 

run: myos.bin
	-@qemu-system-x86_64  -hda myos.bin

clean:
	-@rm *.bin *.o ${OBJ}