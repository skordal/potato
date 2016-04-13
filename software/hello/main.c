// The Potato Processor Benchmark Applications
// (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/potato/issues>

#include <stdint.h>

#include "platform.h"
#include "uart.h"

void exception_handler(uint32_t cause, void * epc, void * regbase)
{
	// Not used in this application
}

static struct uart uart0;

int main(void)
{
	const char * hello_string = "Hello world\n\r";

	uart_initialize(&uart0, (volatile void *) PLATFORM_UART0_BASE);
	uart_set_divisor(&uart0, uart_baud2divisor(115200, PLATFORM_SYSCLK_FREQ));

	for(int i = 0; hello_string[i] != 0; ++i)
	{
		while(uart_tx_fifo_full(&uart0));
		uart_tx(&uart0, hello_string[i]);
	}

	return 0;
}

