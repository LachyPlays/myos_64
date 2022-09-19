;
;    File: boot_v2.asm
;    Author: Tanmay Verma
;    Date  : 12/01/2015
;    Writing a simple bootloader that prints 'Hello World on the screen'. 
;

section .boot
bits 16
global boot
boot:
	mov ax, 0x2401
	int 0x15

	mov ax, 0x3
	int 0x10

	mov [disk],dl

	mov ah, 0x2    ;read sectors
	mov al, 300    	;sectors to read
	mov ch, 0      ;cylinder idx
	mov dh, 0      ;head idx
	mov cl, 2      ;sector idx
	mov dl, [disk] ;disk idx
	mov bx, copy_target;target pointer
	int 0x13
	cli
	lgdt [gdt_pointer]
	mov eax, cr0
	or eax,0x1
	mov cr0, eax
	mov ax, DATA_SEG
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	jmp CODE_SEG:boot2
gdt_start:
	dq 0x0
gdt_code:
	dw 0xFFFF
	dw 0x0
	db 0x0
	db 10011010b
	db 11001111b
	db 0x0
gdt_data:
	dw 0xFFFF
	dw 0x0
	db 0x0
	db 10010010b
	db 11001111b
	db 0x0
gdt_end:
gdt_pointer:
	dw gdt_end - gdt_start
	dd gdt_start
disk:
	db 0x0
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

times 510 - ($-$$) db 0
dw 0xaa55
; 512 Bytes filled
copy_target:
bits 32

	pm32_msg: db "Entered 32-bit protected mode!",0
	longmodesupport_msg: db "Checking for long mode support...",0
	pagingenable_msg: db "Enabling long mode paging...", 0
	enteringcompatibilitylongmode_msg: db "Entering compatibility long mode...", 0
	switchinglongmode_msg: db "Switching to long mode...", 0
	nolongmode_msg: db "CPU does not support long mode!", 0
	nocpuid_msg: db "CPU does not support CPUID instruction!", 0
	panic_msg: db "[PANIC] CPU halted", 0

	success_msg: db "Success!", 0

boot2:
	lea ebx, pm32_msg
	call print_string_pm
	call print_string_pm_newline
halt:
	mov esp,kernel_stack_top

	mov ebx, longmodesupport_msg
	call print_string_pm
	call check_longmode_support ; If this doesn't panic, we have long mode support
	lea ebx, success_msg
	call print_string_pm
	call print_string_pm_newline

	mov ebx, pagingenable_msg
	call print_string_pm
	call setup_longmode_paging
	lea ebx, success_msg
	call print_string_pm
	call print_string_pm_newline

	lea ebx, enteringcompatibilitylongmode_msg
	call print_string_pm
	call enter_compatibility_long_mode
	lea ebx, success_msg
	call print_string_pm
	call print_string_pm_newline

	lea ebx, switchinglongmode_msg
	call print_string_pm

	lgdt [GDT64.Pointer]
	jmp GDT64.Code:Realm64

	jmp panic


;;;; Long mode code ;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Access bits
PRESENT        equ 1 << 7
NOT_SYS        equ 1 << 4
EXEC           equ 1 << 3
DC             equ 1 << 2
RW             equ 1 << 1
ACCESSED       equ 1 << 0
 
; Flags bits
GRAN_4K       equ 1 << 7
SZ_32         equ 1 << 6
LONG_MODE     equ 1 << 5
 
GDT64:
    .Null: equ $ - GDT64
        dq 0
    .Code: equ $ - GDT64
        dd 0xFFFF                                   ; Limit & Base (low, bits 0-15)
        db 0                                        ; Base (mid, bits 16-23)
        db PRESENT | NOT_SYS | EXEC | RW            ; Access
        db GRAN_4K | LONG_MODE | 0xF                ; Flags & Limit (high, bits 16-19)
        db 0                                        ; Base (high, bits 24-31)
    .Data: equ $ - GDT64
        dd 0xFFFF                                   ; Limit & Base (low, bits 0-15)
        db 0                                        ; Base (mid, bits 16-23)
        db PRESENT | NOT_SYS | RW                   ; Access
        db GRAN_4K | SZ_32 | 0xF                    ; Flags & Limit (high, bits 16-19)
        db 0                                        ; Base (high, bits 24-31)
    .TSS: equ $ - GDT64
        dd 0x00000068
        dd 0x00CF8900
    .Pointer:
        dw $ - GDT64 - 1
        dq GDT64

; Longmode functions
bits 64
Realm64:
    cli                           ; Clear the interrupt flag.
	mov rsp,kernel_stack_top	  ; Set stack to kstack
	mov rbp, rsp				  ; Set base to stack
	xor rax, rax				  ; Zero out RAX
    mov ax, GDT64.Data            ; Set the A-register to the data descriptor.
    mov ds, ax                    ; Set the data segment to the A-register.
    mov es, ax                    ; Set the extra segment to the A-register.
    mov fs, ax                    ; Set the F-segment to the A-register.
    mov gs, ax                    ; Set the G-segment to the A-register.
    mov ss, ax                    ; Set the stack segment to the A-register.
    mov edi, 0xB8000              ; Set the destination index to 0xB8000.
    mov rax, 0x0F200F200F200F20   ; Set the A-register to 0x1F201F201F201F20.
    mov ecx, 500                  ; Set the C-register to 500.
    rep stosq                     ; Clear the screen.
	extern kmain
	call kmain
    hlt                           ; Halt the processor.


bits 32
; Longmode setup routines
enter_compatibility_long_mode:
	pusha

	mov ecx, 0xC0000080          ; Set the C-register to 0xC0000080, which is the EFER MSR.
    rdmsr                        ; Read from the model-specific register.
    or eax, 1 << 8               ; Set the LM-bit which is the 9th bit (bit 8).
    wrmsr                        ; Write to the model-specific register.
	mov eax, cr0                 ; Set the A-register to control register 0.
    or eax, 1 << 31 | 1 << 0     ; Set the PG-bit, which is the 31nd bit, and the PM-bit, which is the 0th bit.
    mov cr0, eax                 ; Set control register 0 to the A-register.

	mov ecx, 0xC0000080          ; Set the C-register to 0xC0000080, which is the EFER MSR.
    rdmsr                        ; Read from the model-specific register.
    or eax, 1 << 8               ; Set the LM-bit which is the 9th bit (bit 8).
    wrmsr                        ; Write to the model-specific register.
	mov eax, cr0                 ; Set the A-register to control register 0.
    or eax, 1 << 31              ; Set the PG-bit, which is the 32nd bit (bit 31).
    mov cr0, eax                 ; Set control register 0 to the A-register.

	popa
	ret

setup_longmode_paging:
	pusha
	; Clear all PLM4 tables
	lea edi, kernel_pml4t_table
	mov cr3, edi
	xor eax, eax
	mov ecx, 1024
	rep stosd
	mov edi, cr3
	; Clear all PLM4[0]->PDPT tables
	lea edi, kernel_page_directory_pointer_table
	xor eax, eax
	mov ecx, 1024
	rep stosd
	; Clear all PDPT[0]-PDT tables
	lea edi, kernel_page_directory_table
	xor eax, eax
	mov ecx, 1024
	rep stosd
	; Clear all PDT[0]->PT tables
	lea edi, kernel_page_table
	xor eax, eax
	mov ecx, 1024
	rep stosd


	; Get PLM4 address 
	mov eax, kernel_page_directory_pointer_table
	shr eax, 12
	shl eax, 12
	or eax, 3
	mov DWORD [kernel_pml4t_table], eax

	; Get PDPT address
	mov eax, kernel_page_directory_table
	shr eax, 12
	shl eax, 12
	or eax, 3
	mov DWORD [kernel_page_directory_pointer_table], eax

	; Get PDT address
	mov eax, kernel_page_table
	shr eax, 12
	shl eax, 12
	or eax, 3
	mov DWORD [kernel_page_directory_table], eax

	; Set all page table entries
	lea ebx, kernel_page_table
	mov eax, 3
	mov ecx, 512
.setPageEntries:
	mov DWORD [ebx], eax
	add eax, 0x1000
	add ebx, 8
	loop .setPageEntries

	mov eax, cr4
	or eax, 1 << 5
	mov cr4, eax

	popa
	ret

check_longmode_support:
	pusha
	
	pushfd
    pushfd                               ;Store EFLAGS
    xor dword [esp],0x00200000           ;Invert the ID bit in stored EFLAGS
    popfd                                ;Load stored EFLAGS (with ID bit inverted)
    pushfd                               ;Store EFLAGS again (ID bit may or may not be inverted)
    pop eax                              ;eax = modified EFLAGS (ID bit may or may not be inverted)
    xor eax,[esp]                        ;eax = whichever bits were changed
    popfd                                ;Restore original EFLAGS
    and eax,0x00200000                   ;eax = zero if ID bit can't be changed, else non-zero
	cmp eax, 0
	je .NoCPUID

	mov eax, 0x80000000    ; Set the A-register to 0x80000000.
    cpuid                  ; CPU identification.
    cmp eax, 0x80000001    ; Compare the A-register with 0x80000001.
    jb .NoLongMode         ; It is less, there is no long mode.

	mov eax, 0x80000001    ; Set the A-register to 0x80000001.
    cpuid                  ; CPU identification.
    test edx, 1 << 29      ; Test if the LM-bit, which is bit 29, is set in the D-register.
    jz .NoLongMode         ; They aren't, there is no long mode.

	popa
	ret

.NoLongMode:
	lea ebx, nolongmode_msg
	call print_string_pm
	call print_string_pm_newline
	jmp panic

.NoCPUID:
	lea ebx, nocpuid_msg
	call print_string_pm
	call print_string_pm_newline
	jmp panic

panic:
	lea ebx, panic_msg
	call print_string_pm
	call print_string_pm_newline
	cli 
	hlt

; String routines
VIDEO_MEMORY equ 0xb8000
WHITE_ON_BLACK equ 0x0f
VIDEO_COL	db 0
VIDEO_ROW	db 0

; Protected mode print routine
; Description: Prints a string pointed to by EBX, containing a null byte
; Parameters: EBX (String address)
; Clobbers: None
print_string_pm:
	pusha
	push ebx
	; cl = x, ch = y
	lea edx, VIDEO_COL
	xor ecx, ecx
	mov cl, [edx]
	lea edx, VIDEO_ROW
	mov ch, [edx]

	; edx = ((y * 80) * 2) + x
	xor edx, edx
	xor eax, eax
	xor ebx, ebx
	mov bl, ch
	xor ebx, ebx
	mov bl, BYTE [VIDEO_ROW]
	mov eax, 80 * 2
	mul ebx	; EAX = (y * 80) * 2
	mov edx, eax

	; edx += x * 2
	xor eax, eax
	mov al, BYTE [VIDEO_COL]
	shl eax, 1
	add edx, eax

	add edx, VIDEO_MEMORY
	mov ah, WHITE_ON_BLACK
	pop ebx
print_string_pm_loop:
	; Get next char of string
	mov al, [ebx]

	; Check for null byte
	cmp al, 0
	je print_string_pm_done

	; Store character and attribute to EDX
	mov [edx], ax
	
	; Increment String ptr and VMEM ptr respectively
	add ebx, 1
	add edx, 2
	inc BYTE [VIDEO_COL]

	; Go again
	jmp print_string_pm_loop
print_string_pm_done:
	;cmp BYTE [VIDEO_COL], 80 
	;jge .increment_row
	popa
	ret
.increment_row:
	mov al, 80
	sub [VIDEO_COL], al
	inc BYTE [VIDEO_ROW]
	popa
	ret
print_string_pm_newline:
	inc BYTE [VIDEO_ROW]
	mov BYTE [VIDEO_COL], 0
	ret

section .bss
align 4096
kernel_stack_bottom: equ $
	resb 16384 ; 16 KB
kernel_stack_top:

section .kernalpage
align 4096
kernel_pml4t_table: resq 512 
;align 4096
kernel_page_directory_pointer_table: resq 512
;align 4096
kernel_page_directory_table: resq 512
;align 4096
kernel_page_table: resq 512