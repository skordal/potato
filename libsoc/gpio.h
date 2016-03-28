// The Potato SoC Library
// (c) Kristian Klomsten Skordal 2016 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/potato/issues>

#ifndef PAEE_GPIO_H
#define PAEE_GPIO_H

#include <stdbool.h>
#include <stdint.h>

#define PAEE_GPIO_REG_INPUT	0
#define PAEE_GPIO_REG_OUTPUT	4
#define PAEE_GPIO_REG_DIRECTION	8

struct gpio
{
	volatile uint32_t * registers;
};

/**
 * Initializes a GPIO instance.
 * @param module Pointer to a GPIO instance structure.
 * @param base   Pointer to the base address of the GPIO hardware instance.
 */
static inline void gpio_initialize(struct gpio * module, volatile void * base)
{
	module->registers = base;
}

/**
 * Sets the GPIO direction register.
 *
 * A value of 1 in the direction bitmask indicates that the pin is an output,
 * while a value of 0 indicates that the pin is an input.
 *
 * @param module Pointer to a GPIO instance structure.
 * @param dir    Direction bitmask for the GPIO direction register.
 */
static inline void gpio_set_direction(struct gpio * module, uint32_t dir)
{
	module->registers[PAEE_GPIO_REG_DIRECTION >> 2] = dir;
}

static inline uint32_t gpio_get_input(struct gpio * module)
{
	return module->registers[PAEE_GPIO_REG_INPUT >> 2];
}

static inline void gpio_set_output(struct gpio * module, uint32_t output)
{
	module->registers[PAEE_GPIO_REG_OUTPUT >> 2] = output;
}

/**
 * Sets (turns on) the specified GPIO pin.
 * @param module Pointer to the GPIO instance structure.
 * @param pin    Pin number for the pin to turn on.
 */
static inline void gpio_set_pin(struct gpio * module, uint8_t pin)
{
	module->registers[PAEE_GPIO_REG_OUTPUT >> 2] |= (1 << pin);
}

/**
 * Clears (turns off) the specified GPIO pin.
 * @param module Pointer to the PGIO instance structure.
 * @param pin    Pin number for the pin to turn off.
 */
static inline void gpio_clear_pin(struct gpio * module, uint8_t pin)
{
	module->registers[PAEE_GPIO_REG_OUTPUT >> 2] &= ~(1 << pin);
}

#endif

