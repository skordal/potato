// The Potato Processor Benchmark Applications
// (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/potato/issues>

// This file contains various platform details. The default defines in this file
// correspond to the "official" test platform, the Potato SoC for the Nexys4 board.

#ifndef PLATFORM_H
#define PLATFORM_H

// Clock frequency in Hz:
#define SYSTEM_CLK_FREQ	50000000

// Macro for using the addresses below in C code:
#define IO_ADDRESS(x)	((volatile void *) x)

// Base addresses for the various peripherals in the system:
#define IMEM_BASE	0x00000000
#define DMEM_BASE	0x00002000
#define GPIO1_BASE	0x00004000 
#define GPIO2_BASE	0x00004800
#define UART_BASE	0x00005000
#define TIMER_BASE	0x00005800
#define SEG7_BASE	0x00006000

// IRQs:
#define IRQ_EXTERNAL	0
#define IRQ_UART_RTS	1
#define IRQ_UART_RECV	2
#define IRQ_TIMER	5

// GPIO register offsets:
#define GPIO_INPUT	0
#define GPIO_OUTPUT	4
#define GPIO_DIR	8

// UART register offsets:
#define UART_TX		0
#define UART_RX		4
#define UART_STATUS	8

// UART status register bits:
#define UART_STATUS_RXBUF_EMPTY	0
#define UART_STATUS_TXBUF_EMPTY	1
#define UART_STATUS_RXBUF_FULL	2
#define UART_STATUS_TXBUF_FULL	3

// Timer register offsets:
#define TIMER_CTRL	0
#define TIMER_COMPARE	4
#define TIMER_COUNTER	8

// Timer control register bits:
#define TIMER_CTRL_RUN		0
#define TIMER_CTRL_CLEAR	1

// 7-Segment register offsets:
#define SEG7_ENABLE	0
#define SEG7_VALUE	4

#endif

