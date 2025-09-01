// Enhanced main.c - finite test program
#define GPIO_BASE   0x10000000
#define UART_BASE   0x10001000

volatile unsigned int * const leds = (volatile unsigned int *)GPIO_BASE;
volatile unsigned int * const uart_tx = (volatile unsigned int *)UART_BASE;

void uart_send(char c) {
    *uart_tx = c;
}

int main() {
    // Initial LED pattern
    *leds = 0xAAAA;
    
    // Send test message
    uart_send('T'); uart_send('E'); uart_send('S'); uart_send('T'); uart_send('\n');
    
    // LED blink sequence - NO DELAYS
    for (int blinks = 0; blinks < 6; blinks++) {
        *leds = ~(*leds);
        // Remove this: for (volatile int i = 0; i < 20; i++);
    }
    
    // Send completion message
    uart_send('D'); uart_send('O'); uart_send('N'); uart_send('E'); uart_send('\n');
    
    // Set final LED pattern
    *leds = 0x0F0F;
    
    // Program complete
    while(1);
    
    return 0;
}