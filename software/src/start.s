.section .text.start
.global _start

_start:
    la sp, _stack_top
    la t0, _bss_start
    la t1, _bss_end
clear_bss:
    beq t0, t1, bss_done
    sw zero, 0(t0)
    addi t0, t0, 4
    j clear_bss
bss_done:
    call main
hang:
    j hang
