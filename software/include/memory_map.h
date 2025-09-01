#ifndef MEMORY_MAP_H
#define MEMORY_MAP_H

#define GPIO_BASE       0x10000000
#define UART_BASE       0x10001000

#define REG32(addr)     (*(volatile unsigned int*)(addr))
#define GPIO_LEDS()     REG32(GPIO_BASE + 0x00)
#define GPIO_SWITCHES() REG32(GPIO_BASE + 0x04)
#define UART_DATA()     REG32(UART_BASE + 0x00)
#define UART_STATUS()   REG32(UART_BASE + 0x04)

#define UART_TX_READY   (1 << 0)
#define UART_RX_VALID   (1 << 1)

#endif
