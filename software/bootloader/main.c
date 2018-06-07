// The Potato Processor Benchmark Applications
// (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/potato/issues>

#include <stdint.h>

#include "platform.h"
#include "uart.h"

#define APP_START (0x00000000)
#define APP_LEN   (0x20000)
#define APP_ENTRY (0x00000000)

static struct uart uart0;

void exception_handler(uint32_t cause, void * epc, void * regbase)
{
	while(uart_tx_fifo_full(&uart0));
	uart_tx(&uart0, 'E');
}

int main(void)
{
	uart_initialize(&uart0, (volatile void *) PLATFORM_UART0_BASE);
	uart_set_divisor(&uart0, uart_baud2divisor(115200, PLATFORM_SYSCLK_FREQ));

	/* Print welcome message */
	uart_tx_string(&uart0, "\n\r** Potato Bootloader - waiting for application image **\n\r");

	/* Read application from UART and store it in RAM */
	for(int i = 0; i < APP_LEN; i++){
		while(uart_rx_fifo_empty(&uart0));
		*((volatile uint8_t*)(APP_START + i)) = uart_rx(&uart0);

		/* Print some dots */
		if(((i & 0x7ff) == 0) && !uart_tx_fifo_full(&uart0))
			uart_tx(&uart0, '.');
	}

	/* Print booting message */
	uart_tx_string(&uart0, "\n\rBooting\n\r");

	/* Jump in RAM */
	goto *APP_ENTRY;

	return 0;
}

