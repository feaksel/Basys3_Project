#include "system.h"

int main(void) {
    uart_puts("VexRiscv Blink Test!\n");
    
    unsigned int pattern = 0x0001;
    
    while (1) {
        set_leds(pattern);
        uart_puts("LEDs: ");
        uart_put_hex(pattern);
        uart_puts("\n");
        
        pattern = (pattern << 1) | (pattern >> 15);
        if (pattern == 0) pattern = 1;
        
        delay(200000);
    }
    
    return 0;
}
