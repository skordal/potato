// The Potato Processor
// (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/potato/issues>

#ifndef POTATO_H
#define POTATO_H

#include <stdint.h>

// Number of IRQs supported:
#define POTATO_NUM_IRQS		8

// Exception cause values:
#define POTATO_MCAUSE_INSTR_MISALIGN	0x00
#define POTATO_MCAUSE_INSTR_FETCH	0x01
#define POTATO_MCAUSE_INVALID_INSTR	0x02
#define POTATO_MCAUSE_BREAKPOINT	0x03
#define POTATO_MCAUSE_LOAD_MISALIGN	0x04
#define POTATO_MCAUSE_LOAD_ERROR	0x05
#define POTATO_MCAUSE_STORE_MISALIGN	0x06
#define POTATO_MCAUSE_STORE_ERROR	0x07
#define POTATO_MCAUSE_ECALL		0x0b

// IRQ base value
#define POTATO_MCAUSE_IRQ_BASE		0x80000010

// IRQ number mask
#define POTATO_MCAUSE_IRQ_MASK		0x0f

// Interrupt bit in the cause register:
#define POTATO_MCAUSE_INTERRUPT_BIT	31

// IRQ bit in the cause register:
#define POTATO_MCAUSE_IRQ_BIT		 4

// Status register bit indices:
#define STATUS_MIE	3		// Enable Interrupts
#define STATUS_MPIE	7		// Previous value of Enable Interrupts

#define potato_enable_interrupts()	asm volatile("csrsi mstatus, 1 << %[mie_bit]\n" \
		:: [mie_bit] "i" (STATUS_MIE))
#define potato_disable_interrupts() \
	do { \
		uint32_t temp = 1 << STATUS_MIE | 1 << STATUS_MPIE; \
		asm volatile("csrc mstatus, %[temp]\n" :: [temp] "r" (temp)); \
	} while(0)

#define potato_write_host(data)	\
	do { \
		register uint32_t temp = data; \
		asm volatile("csrw mtohost, %[temp]\n" \
			:: [temp] "r" (temp)); \
	} while(0);

#define potato_wfi() asm volatile("wfi\n\t")

/**
 * Gets the value of the MCAUSE register.
 */
static inline uint32_t potato_get_mcause(void)
{
	register uint32_t retval = 0;
	asm volatile(
		"csrr %[retval], mcause\n"
		: [retval] "=r" (retval)
	);

	return retval;
}

/**
 * Enables a specific IRQ.
 * @note To globally enable IRQs, use the @ref potato_enable_interrupts() function.
 */
static inline void potato_enable_irq(uint8_t n)
{
	register uint32_t temp = 1 << (n + 24);
	asm volatile(
		"csrs mie, %[temp]\n"
		:: [temp] "r" (temp)
	);
}

/**
 * Disables a specific IRQ.
 */
static inline void potato_disable_irq(uint8_t n)
{
	register uint32_t temp = 1 << (n + 24);
	asm volatile(
		"csrc mie, %[temp]\n"
		:: [temp] "r" (temp)
	);
}

#define potato_get_badaddr(n) \
	do { \
		register uint32_t temp = 0; \
		asm volatile ( \
			"csrr %[temp], mbadaddr\n" \
			: [temp] "=r" (temp)); \
		n = temp; \
	} while(0)

#endif

