ENTRY(boot)
OUTPUT_FORMAT("binary")
SECTIONS {
    . = 0x7c00;

    .boot :
    {
        _boot = .;
        *(.boot)
        _bootheader = .;
        *(.bootheader)
        . = ALIGN(4096);
        *(.kernelpage)
        . = ALIGN(4096);
    } 

    .text : ALIGN(4K)
    {
        _text = .;
        *(.text)
        . = ALIGN(4096);
    }

    .rodata : ALIGN(4K)
    {
        _rodata = .;
        *(.rodata*)
        . = ALIGN(4096);
    }

    .data : ALIGN(4K)
    {
        _data = .;
        *(.data)
        . = ALIGN(4096);
    }
    .bss : ALIGN(4K)
    {
        _bss = .;
        *(.bss)
        *(COMMON)
        . = ALIGN(4096);
    }

    _end = .;
}