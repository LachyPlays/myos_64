rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

C_SOURCES = $(call rwildcard,src,*.c)
HEADERS = $(call rwildcard,src,*.h)
ASM = $(call rwildcard,src,*.asm)

OBJ = ${C_SOURCES:.c=.o} ${ASM:.asm=.o}

CC = amd64-elf-gcc
CFLAGS = -ffreestanding -mcmodel=large -mno-red-zone -mno-mmx -mno-sse -mno-sse2
LFLAGS = -T src/linker.ld -ffreestanding -O2 -nostdlib -lgcc

%.o: %.c ${HEADERS}
	${CC} ${CFLAGS} -c $< -o $@

%.o: %.asm ${ASM}
	nasm -felf64 -o $@ $<

all: run

myos.bin: ${OBJ}
	amd64-elf-gcc ${LFLAGS} -o $@ $^ 

run: myos.bin
	qemu-system-x86_64  -hda myos.bin

clean:
	rm *.bin *.o ${OBJ}