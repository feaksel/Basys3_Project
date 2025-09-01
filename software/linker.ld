OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
    RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 64K
}

SECTIONS {
    . = 0x80000000;
    
    .text : {
        *(.text.start)
        *(.text .text.*)
    } > RAM
    
    .rodata : {
        *(.rodata .rodata.*)
    } > RAM
    
    .data : {
        *(.data .data.*)
    } > RAM
    
    .bss : {
        *(.bss .bss.*)
    } > RAM
    
    /* Stack allocation */
    .stack : {
        . = ALIGN(16);
        _stack_bottom = .;
        . = . + 0x1000;
        _stack_top = .;
    } > RAM
}
