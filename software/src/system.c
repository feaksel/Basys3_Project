#include "system.h"

void delay(unsigned int cycles) {
    for (volatile unsigned int i = 0; i < cycles; i++) {
        __asm__("nop");
    }
}

void uart_putc(char c) {
    while (!(UART_STATUS() & UART_TX_READY));
    UART_DATA() = (unsigned int)c;
}

void uart_puts(const char* str) {
    while (*str) {
        if (*str == '\n') uart_putc('\r');
        uart_putc(*str++);
    }
}

void uart_put_hex(unsigned int value) {
    uart_puts("0x");
    for (int i = 7; i >= 0; i--) {
        unsigned int nibble = (value >> (i * 4)) & 0xF;
        uart_putc(nibble < 10 ? '0' + nibble : 'A' + nibble - 10);
    }
}

void set_leds(unsigned int pattern) {
    GPIO_LEDS() = pattern;
}

unsigned int get_switches(void) {
    return GPIO_SWITCHES();
}

