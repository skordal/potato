// The Potato SoC Library
// (c) Kristian Klomsten Skordal 2016 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/potato/issues>

#ifndef LIBSOC_TIMER_H
#define LIBSOC_TIMER_H

#include <stdint.h>

// Timer register offsets:
#define TIMER_REG_CONTROL	0x00
#define TIMER_REG_COMPARE	0x04
#define TIMER_REG_COUNTER	0x08

// Timer control register bits:
#define TIMER_CONTROL_RUN	0
#define TIMER_CONTROL_CLEAR	1

struct timer
{
	volatile uint32_t * registers;
};

/**
 * Initializes a timer instance.
 * @param module       Pointer to a timer instance structure.
 * @param base_address Base address of the timer hardware module.
 */
static inline void timer_initialize(struct timer * module, volatile void * base_address)
{
	module->registers = base_address;
}

/**
 * Resets a timer.
 * This stops the timer and resets its counter value to 0.
 * @param module Pointer to a timer instance structure.
 */
static inline void timer_reset(struct timer * module)
{
	module->registers[TIMER_REG_CONTROL >> 2] = 1 << TIMER_CONTROL_CLEAR;
}

/**
 * Starts a timer.
 * @param module Pointer to a timer instance structure.
 */
static inline void timer_start(struct timer * module)
{
	module->registers[TIMER_REG_CONTROL >> 2] = 1 << TIMER_CONTROL_RUN | 1 << TIMER_CONTROL_CLEAR;
}

/**
 * Stops a timer.
 * @param module Pointer to a timer instance structure.
 */
static inline void timer_stop(struct timer * module)
{
	module->registers[TIMER_REG_CONTROL >> 2] = 0;
}

/**
 * Clears a timer.
 * @param module Pointer to a timer instance structure.
 */
static inline void timer_clear(struct timer * module)
{
	module->registers[TIMER_REG_CONTROL >> 2] |= 1 << TIMER_CONTROL_CLEAR;
}

/**
 * Sets the compare register of a timer.
 * @param module  Pointer to a timer instance structure.
 * @param compare Value to write to the timer compare register.
 * @warning Using this function while the timer is running could cause undefined bahviour.
 */
static inline void timer_set_compare(struct timer * module, uint32_t compare)
{
	module->registers[TIMER_REG_COMPARE >> 2] = compare;
}

/**
 * Reads the current value of a timer's counter.
 * @param module Pointer to a timer instance structure.
 * @returns The value of the timer's counter register.
 */
static inline uint32_t timer_get_count(struct timer  * module)
{
	return module->registers[TIMER_REG_COUNTER >> 2];
}

/**
 * Sets the value of a timer's counter register.
 * @param module  Pointer to a timer instance structure.
 * @param counter New value of the timer's counter register.
 * @warning This function should only be used when the timer is stopped to avoid undefined behaviour.
 */
 static inline void timer_set_count(struct timer * module, uint32_t counter)
 {
	module->registers[TIMER_REG_COUNTER >> 2] = counter;
 }

#endif

