OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS {
    . = 0x00000000;
    .text : { *(.text.start) *(.text*) } > RAM
    .rodata : { *(.rodata*) } > RAM
    .data : { _data_start = .; *(.data*) _data_end = .; } > RAM
    .bss : { _bss_start = .; *(.bss*) *(COMMON) _bss_end = .; } > RAM
    . = ALIGN(16);
    _stack_bottom = .;
    . = . + 0x1000;
    _stack_top = .;
}
