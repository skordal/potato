// The Potato Processor Benchmark Applications
// (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/potato/issues>

#include <stdbool.h>
#include <stdint.h>

#include "platform.h"
#include "potato.h"

#include "gpio.h"
#include "timer.h"
#include "uart.h"

#include "sha256.h"

static struct gpio gpio0;
static struct uart uart0;
static struct timer timer0;

static int led_status = 0;
static volatile int hashes_per_second = 0;

static void int2string(int i, char * s);

void exception_handler(uint32_t mcause, uint32_t mepc, uint32_t sp)
{
	if((mcause & (1 << POTATO_MCAUSE_INTERRUPT_BIT)) && (mcause & (1 << POTATO_MCAUSE_IRQ_BIT)))
	{
		uint8_t irq = mcause & 0x0f;

		if(irq == PLATFORM_IRQ_TIMER0)
		{
			// Blink LED0 once per second:
			if(led_status == 0)
			{
				gpio_set_output(&gpio0, 0x100);
				led_status = 1;
			} else {
				gpio_set_output(&gpio0, 0x000);
				led_status = 0;
			}

			timer_clear(&timer0);

			// Print the number of hashes since last interrupt:
			char hps_dec[11] = {0};
			int2string(hashes_per_second, hps_dec);
			uart_tx_string(&uart0, hps_dec);
			uart_tx_string(&uart0, " H/s\n\r");
			hashes_per_second = 0;
		} else
			potato_disable_irq(irq);
	}
}

int main(void)
{
	// Configure GPIOs:
	gpio_initialize(&gpio0, (volatile void *) PLATFORM_GPIO_BASE);
	gpio_set_direction(&gpio0, 0xf00);	// Set LEDs to output, buttons and switches to input
	gpio_set_output(&gpio0, 0x100);		// Turn LED0 on.

	// Configure the UART:
	uart_initialize(&uart0, (volatile void *) PLATFORM_UART0_BASE);
	uart_set_divisor(&uart0, uart_baud2divisor(115200, PLATFORM_SYSCLK_FREQ));
	uart_tx_string(&uart0, "--- SHA256 Benchmark Application ---\r\n\n");

	// Set up the timer at 1 Hz:
	timer_initialize(&timer0, (volatile void *) PLATFORM_TIMER0_BASE);
	timer_reset(&timer0);
	timer_set_compare(&timer0, PLATFORM_SYSCLK_FREQ);
	timer_start(&timer0);

	// Enable interrupts:
	potato_enable_irq(PLATFORM_IRQ_TIMER0);
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

static void int2string(int n, char * s)
{
	bool first = true;

	if(n == 0)
	{
		*s = '0';
		return;
	}

	if(n & (1 << 31))
	{
		n = ~n + 1;
		*(s++) = '-';
	}

	for(int i = 1000000000; i > 0; i /= 10)
	{
		if(n / i == 0 && !first)
			*(s++) = '0';
		else if(n / i != 0)
		{
			*(s++) = '0' + n / i;
			n %= i;
			first = false;
		}
	}
}

