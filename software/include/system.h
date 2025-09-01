#ifndef SYSTEM_H
#define SYSTEM_H

#include "memory_map.h"

void delay(unsigned int cycles);
void uart_putc(char c);
void uart_puts(const char* str);
void uart_put_hex(unsigned int value);
void set_leds(unsigned int pattern);
unsigned int get_switches(void);

#endif
