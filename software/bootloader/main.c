// The Potato Processor Benchmark Applications
// (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/potato/issues>

#include <stdint.h>

#include "platform.h"
#include "uart.h"

#define RED     "\033[0;31m"
#define GREEN   "\033[0;32m"
#define BLUE    "\033[1;34m"
#define YEL     "\033[1;33m"
#define CYAN    "\033[0;36m"
#define WHITE   "\033[1;37m"
#define PURPLE  "\033[0;35m"
#define NC      "\033[0m"   // No Color

#define APP_START (0xffffc000)
#define APP_LEN   (0x2000)
#define APP_ENTRY (0xffffc000)

static struct uart uart0;


void exception_handler(uint32_t cause, void * epc, void * regbase)
{
	while(uart_tx_fifo_full(&uart0));
	uart_tx(&uart0, 'E');
}


int main(void)
{
	const char* hello_string = PURPLE "\n\r** Welcome to Potato chip ! **\n\r" NC;
	const char* boot_string = GREEN "\n\rBooting\n\r" NC;

	uart_initialize(&uart0, (volatile void *) PLATFORM_UART0_BASE);
	uart_set_divisor(&uart0, uart_baud2divisor(115200, PLATFORM_SYSCLK_FREQ));

	/* Print welcome message */
	for(int i = 0; hello_string[i] != 0; ++i){
		while(uart_tx_fifo_full(&uart0));
		uart_tx(&uart0, hello_string[i]);
	}
	
	/* Read application from UART and store it in RAM */
	for(int i = 0; i<APP_LEN; i++){
		while(uart_rx_fifo_empty(&uart0));
		*((uint8_t*)(APP_START + i)) = uart_rx(&uart0);

		/* Print some dots */
		if(((i & 0x7f) == 0) && !uart_tx_fifo_full(&uart0))
			uart_tx(&uart0, '.');
	}

	/* Print booting message */
	for(int i = 0; boot_string[i] != 0; ++i){
		while(uart_tx_fifo_full(&uart0));
		uart_tx(&uart0, boot_string[i]);
	}

	/* Jump in RAM */
	goto *APP_ENTRY;

	return 0;
}

