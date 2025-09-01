.section .text.start
.global _start

_start:
    # Set stack pointer
    li sp, 0x80010000
    
    # Simple main call - NO BSS CLEARING
    jal main
    
    # If main returns, hang
hang:
    j hang
