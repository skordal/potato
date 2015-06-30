// The Potato Processor
// (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <http://opencores.org/project,potato,bugtracker>

#ifndef POTATO_H
#define POTATO_H

// Exception cause values:
#define CAUSE_INSTR_MISALIGN	0x00
#define CAUSE_INSTR_FETCH	0x01
#define CAUSE_INVALID_INSTR	0x02
#define CAUSE_BREAKPOINT	0x03
#define CAUSE_LOAD_MISALIGN	0x04
#define CAUSE_LOAD_ERROR	0x05
#define CAUSE_STORE_MISALIGN	0x06
#define CAUSE_STORE_ERROR	0x07
#define CAUSE_ECALL		0x0b

#define CAUSE_IRQ_BASE		0x10

// Interrupt bit in the cause register:
#define CAUSE_INTERRUPT_BIT	31

// Status register bit indices:
#define STATUS_IE	0		// Enable Interrupts
#define STATUS_IE1	3		// Previous value of Enable Interrupts

#define potato_enable_interrupts()	asm volatile("csrsi mstatus, 1 << %[ie_bit]\n" \
		:: [ie_bit] "i" (STATUS_IE))
#define potato_disable_interrupts()	asm volatile("csrci mstatus, 1 << %[ie_bit] | 1 << %[ie1_bit]\n" \
		:: [ie_bit] "i" (STATUS_IE), [ie1_bit] "i" (STATUS_IE1))

#define potato_write_host(data)	\
	do { \
		register uint32_t temp = data; \
		asm volatile("csrw mtohost, %[temp]\n" \
			:: [temp] "r" (temp)); \
	} while(0);

#define potato_enable_irq(n) \
	do { \
		register uint32_t temp = 0; \
		asm volatile( \
			"li %[temp], 1 << %[shift]\n" \
			"csrs mie, %[temp]\n" \
			:: [temp] "r" (temp), [shift] "i" (n + 24)); \
	} while(0)

#define potato_disable_irq(n) \
	do { \
		register uint32_t temp = 0; \
		asm volatile( \
			"li %[temp], 1 << %[shift]\n" \
			"csrc mie, %[temp]\n" \
			:: [temp] "r" (temp), [shift] "i" (n + 24);) \
	} while(0)

#define potato_get_badaddr(n) \
	do { \
		register uint32_t __temp = 0; \
		asm volatile ( \
			"csrr %[temp], mbadaddr\n" \
			: [temp] "=r" (__temp)); \
		n = __temp; \
	} while(0)

#endif

