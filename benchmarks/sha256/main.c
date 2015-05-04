// The Potato Processor Benchmark Applications
// (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <http://opencores.org/project,potato,bugtracker>

#include <stdbool.h>
#include <stdint.h>

#include "platform.h"
#include "potato.h"

#include "gpio.h"
#include "sha256.h"
#include "timer.h"
#include "uart.h"

static int led_status = 0;
static volatile int hashes_per_second = 0;

void exception_handler(uint32_t cause, void * epc)
{
	uart_puts(IO_ADDRESS(UART_BASE), "Hashes per second: ");
	uart_puth(IO_ADDRESS(UART_BASE), hashes_per_second);
	uart_puts(IO_ADDRESS(UART_BASE), "\n\r");

	if(led_status == 0)
	{
		gpio_set_output(IO_ADDRESS(GPIO2_BASE), 1);
		led_status = 1;
	} else {
		gpio_set_output(IO_ADDRESS(GPIO2_BASE), 0);
		led_status = 0;
	}

	timer_reset(IO_ADDRESS(TIMER_BASE));
	hashes_per_second = 0;
}

int main(void)
{
	// Configure GPIOs:
	gpio_set_direction(IO_ADDRESS(GPIO1_BASE), 0x0000); // Switches
	gpio_set_direction(IO_ADDRESS(GPIO2_BASE), 0xffff); // LEDs

	// Set up the timer:
	timer_set(IO_ADDRESS(TIMER_BASE), 50000000);

	// Print a startup message:
	uart_puts(IO_ADDRESS(UART_BASE), "The Potato Processor SHA256 Benchmark\n\r\n\r");

	// Enable interrupts:
	potato_enable_irq(TIMER_IRQ);
	potato_enable_interrupts();

	struct sha256_context context;

	// Prepare a block for hashing:
	uint32_t block[16];
	uint8_t * block_ptr = (uint8_t *) block;
	block_ptr[0] = 'a';
	block_ptr[1] = 'b';
	block_ptr[2] = 'c';
	sha256_pad_le_block(block_ptr, 3, 3);

	// Repeatedly hash the same data over and over again:
	while(true)
	{
		uint8_t hash[32];

		sha256_reset(&context);
		sha256_hash_block(&context, block);
		sha256_get_hash(&context, hash);
		++hashes_per_second;
	}

	return 0;
}

