// Enhanced main.c with better UART handling
#define GPIO_BASE   0x10000000
#define UART_BASE   0x10001000

// Use precise volatile pointers
volatile unsigned int * const leds = (volatile unsigned int *)GPIO_BASE;
volatile unsigned int * const uart_tx = (volatile unsigned int *)UART_BASE;
volatile unsigned int * const uart_status = (volatile unsigned int *)(UART_BASE + 0x04);

void uart_send(char c) {
    *uart_tx = c;
    // Wait for TX ready - important!
    while (!(*uart_status & 0x01)) {
        // Empty wait
    }
}

int main() {
    // Turn on LEDs immediately - should see this!
    *leds = 0xAAAA;
    
    // Simple UART output - should see this!
    uart_send('S');
    uart_send('T');
    uart_send('A');
    uart_send('R');
    uart_send('T');
    uart_send('\n');
    
    // Simple blink loop
    while (1) {
        *leds = ~(*leds);
        // Short delay for simulation
        for (volatile int i = 0; i < 1000; i++);
    }
    
    return 0;
}