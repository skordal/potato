// The Potato SoC Library
// (c) Kristian Klomsten Skordal 2016 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/potato/issues>

#ifndef LIBSOC_UART_H
#define LIBSOC_UART_H

#include <stdbool.h>
#include <stdint.h>

#define UART_REG_TRANSMIT	0x00
#define UART_REG_RECEIVE	0x04
#define UART_REG_STATUS		0x08
#define UART_REG_DIVISOR	0x0c
#define UART_REG_INTERRUPT	0x10

// Status register bit names:
#define UART_STATUS_TX_FULL	3
#define UART_STATUS_RX_FULL	2
#define UART_STATUS_TX_EMPTY	1
#define UART_STATUS_RX_EMPTY	0

// Interrupt enable register bit names:
#define UART_REG_INTERRUPT_TX_READY	1
#define UART_REG_INTERRUPT_RECV		0

struct uart
{
	volatile uint32_t * registers;
};

/**
 * Initializes a UART instance.
 * @param module       Pointer to a UART instance structure.
 * @param base_address Base address of the UART hardware instance.
 */
static inline void uart_initialize(struct uart * module, volatile void * base_address)
{
	module->registers = base_address;
}

/**
 * Sets the UART divisor.
 * @param module  Instance object.
 * @param divisor Value of the divisor register. A baudrate can be converted into
 *                a divisor value using the @c uart_baud2divisor function.
 */
static inline void uart_set_divisor(struct uart * module, uint32_t divisor)
{
	module->registers[UART_REG_DIVISOR >> 2] = divisor;
}

/**
 * Enables or disables UART IRQs.
 * @param module   Instance object.
 * @param tx_ready Specifies whether to enable or disable the `TX ready` interrupt.
 * @param recv     Specifies whether to enable or disable the `Data received` interrupt.
 */
static inline void uart_enable_interrupt(struct uart * module, bool tx_ready, bool recv)
{
	module->registers[UART_REG_INTERRUPT >> 2] = 0
		| (tx_ready << UART_REG_INTERRUPT_TX_READY)
		| (recv << UART_REG_INTERRUPT_RECV);
}

/**
 * Checks if the UART transmit buffer is ready to accept more data.
 * @param module Instance object.
 * @return `true` if the UART transmit FIFO has free space, `false` otherwise.
 */
static inline bool uart_tx_ready(struct uart * module)
{
	return !(module->registers[UART_REG_STATUS >> 2]  & (1 << UART_STATUS_TX_FULL));
}

/**
 * Checks if the UART transmit buffer is empty.
 * @param module Instance object.
 * @return `true` if the UART transmit FIFO is empty, `false` otherwise.
 */
static inline bool uart_tx_fifo_empty(struct uart * module)
{
	return module->registers[UART_REG_STATUS >> 2] & (1 << UART_STATUS_TX_EMPTY);
}

/**
 * Checks if the UART transmit buffer is full.
 * @param module Instance object.
 * @return `true` if the UART transmit FIFO is full, `false` otherwise.
 */
static inline bool uart_tx_fifo_full(struct uart * module)
{
	return module->registers[UART_REG_STATUS >> 2] & (1 << UART_STATUS_TX_FULL);
}

/**
 * Transmits a byte over the UART.
 * This function does not check if the UART buffer is full; use the @ref uart_tx_ready()
 * function to check if the UART can accept more data.
 * @param module Instance object.
 * @param byte   Byte to print to the UART.
 */
static inline void uart_tx(struct uart * module, uint8_t byte)
{
	module->registers[UART_REG_TRANSMIT >> 2] = byte;
}

/**
 * Transmits an array of bytes over the UART.
 * This function blocks until the entire array has been queued for transfer.
 * @param module Instance object.
 * @param array  Pointer to the aray to send on the UART.
 * @param length Length of the array.
 * @see uart_tx_string()
 */
static inline void uart_tx_array(struct uart * module, const uint8_t * array, uint32_t length)
{
	for(uint32_t i = 0; i < length; ++i)
	{
		while(uart_tx_fifo_full(module));
		uart_tx(module, array[i]);
	}
}

/**
 * Transmits a character string over the UART.
 * This function blocks until the entire array has been queued for transfer.
 * @param module Instance object.
 * @param string Pointer to the string to send on the UART. The string must be
 *               NULL-terminated.
 * @see uart_tx_array()
 */
static inline void uart_tx_string(struct uart * module, const char * string)
{
	for(uint32_t i = 0; string[i] != 0; ++i)
	{
		while(uart_tx_fifo_full(module));
		uart_tx(module, string[i]);
	}
}

/**
 * Reads a byte from the UART.
 * This function does not check if a byte is available in the UART buffer; use the
 * @ref uart_rx_ready() function to check if the UART has received anything.
 * @param module Instance object.
 * @return Byte retrieved from the UART.
 */
static inline uint8_t uart_rx(struct uart * module)
{
	return module->registers[UART_REG_RECEIVE >> 2];
}

/**
 * Checks if the UART receive buffer is empty.
 * @param module Instance object.
 * @return `true` if the UART receive FIFO is empty, `false` otherwise.
 */
static inline bool uart_rx_fifo_empty(struct uart * module)
{
	return module->registers[UART_REG_STATUS >> 2] & (1 << UART_STATUS_RX_EMPTY);
}

/**
 * Utility function for calculating the UART baudrate divisor.
 * @param baudrate   The desired baudrate.
 * @param system_clk Frequency of the system clock in Hz.
 * @return The value needed for the UART divisor register to obtain the requested baudrate.
 */
static inline uint32_t uart_baud2divisor(uint32_t baudrate, uint32_t system_clk)
{
	return (system_clk / (baudrate * 16)) - 1;
}

#endif

