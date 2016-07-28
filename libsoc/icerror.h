// The Potato SoC Library
// (c) Kristian Klomsten Skordal 2016 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/potato/issues>

#ifndef LIBSOC_ICERROR_H
#define LIBSOC_ICERROR_H

// Interconnect Error Module registers:
#define ICERROR_REG_STATUS		0x00
#define ICERROR_REG_CONTROL		0x00
#define ICERROR_REG_READ_ADDRESS	0x04
#define ICERROR_REG_READ_MASK		0x08
#define ICERROR_REG_WRITE_ADDRESS	0x0c
#define ICERROR_REG_WRITE_MASK		0x10
#define ICERROR_REG_WRITE_DATA		0x14

// Interconnect Error Module control register bits:
#define ICERROR_CONTROL_IRQ_RESET	0

// Interconnect Error Module status register bits:
#define ICERROR_STATUS_IRQ_STATUS	0
#define ICERROR_STATUS_READ_ERROR	1
#define ICERROR_STATUS_WRITE_ERROR	2

struct icerror
{
	volatile uint32_t * registers;
};

enum icerror_access_type
{
	ICERROR_ACCESS_READ,
	ICERROR_ACCESS_WRITE,
	ICERROR_ACCESS_NONE
};

/**
 * Initializes an interconnect error instance.
 * @param module       Pointer to an interconnect error instance structure.
 * @param base_address Base address of the hardware module.
 */
static inline void icerror_initialize(struct icerror * module, volatile void * base_address)
{
	module->registers = base_address;
}

/**
 * Resets an interconnect error instance.
 * @param module Pointer to an interconnect error instance structure.
 */
static inline void icerror_reset(struct icerror * module)
{
	module->registers[ICERROR_REG_CONTROL >> 2] = 1 << ICERROR_CONTROL_IRQ_RESET;
}

/**
 * Gets the access type for the previous access error.
 * @param module Pointer to an interconnect error instance structure.
 * @returns The access type for the previous access error.
 */
static inline enum icerror_access_type icerror_get_access_type(struct icerror * module)
{
	if(module->registers[ICERROR_REG_STATUS >> 2] & (1 << ICERROR_STATUS_READ_ERROR))
		return ICERROR_ACCESS_READ;
	else if(module->registers[ICERROR_REG_STATUS >> 2] & (1 << ICERROR_STATUS_WRITE_ERROR))
		return ICERROR_ACCESS_WRITE;
	else
		return ICERROR_ACCESS_NONE;
}

/**
 * Gets the access address for the previous read error.
 * @param module Pointer to an interconnect error instance structure.
 * @returns The address of the previous read error.
 */
static inline uint32_t icerror_get_read_address(struct icerror * module)
{
	return module->registers[ICERROR_REG_READ_ADDRESS >> 2];
}

/**
 * Gets the access address for the previous write error.
 * @param module Pointer to an interconnect error instance structure.
 * @returns The address of the previous write error.
 */
static inline uint32_t icerror_get_write_address(struct icerror * module)
{
	return module->registers[ICERROR_REG_WRITE_ADDRESS >> 2];
}

#endif

