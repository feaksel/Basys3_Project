OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
    RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 64K
}

SECTIONS {
    . = 0x80000000;
    
    .text : { 
        *(.text.start) 
        *(.text*) 
    } > RAM
    
    .rodata : { *(.rodata*) } > RAM
    .data : { 
        _data_start = .; 
        *(.data*) 
        _data_end = .; 
    } > RAM
    
    .bss : { 
        _bss_start = .;
        *(.bss*) 
        *(COMMON) 
        _bss_end = .;
    } > RAM
    
    /* Stack allocation - FIXED! */
    .stack : {
        . = ALIGN(16);
        _stack_bottom = .;
        . = . + 0x1000;    /* 4KB stack */
        _stack_top = .;
    } > RAM
    
    /* Ensure these symbols are available to the program */
    PROVIDE(_stack_top = .);
    PROVIDE(_stack_bottom = _stack_top - 0x1000);
}
