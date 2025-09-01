.section .text.start
.global _start

_start:
    # Set stack pointer
    li sp, 0x80010000
    
    # Set up proper return address for main
    # If main returns, we want to hang, not jump to 0
    la ra, hang
    
    # Clear critical registers that might contain garbage
    li a0, 0
    li a1, 0
    li a2, 0
    li a3, 0
    li t0, 0
    li t1, 0
    li t2, 0
    
    # Jump to main (not call, so we don't set ra)
    j main

hang:
    j hang