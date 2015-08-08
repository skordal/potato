// The Potato Processor Benchmark Applications
// (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <http://opencores.org/project,potato,bugtracker>

#ifndef SEG7_H
#define SEG7_H

#include <stdint.h>

// Sets which 7-segment displays are enabled:
void seg7_set_enabled_displays(volatile uint32_t * base, uint8_t mask);
// Sets the value to be displayed on the displays:
void seg7_set_value(volatile uint32_t * base, uint32_t value);

#endif

