// The Potato Processor Benchmark Applications
// (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <http://opencores.org/project,potato,bugtracker>

#include "seg7.h"
#include "platform.h"

void seg7_set_enabled_displays(volatile uint32_t * base, uint8_t mask)
{
	base[SEG7_ENABLE >> 2] = (uint32_t) mask;
}

void seg7_set_value(volatile uint32_t * base, uint32_t value)
{
	base[SEG7_VALUE >> 2] = value;
}


