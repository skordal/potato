// The Potato Processor Benchmark Applications
// (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/potato/issues>

#include "platform.h"
#include "timer.h"

void timer_set(volatile uint32_t * base, uint32_t compare)
{
	base[TIMER_COMPARE >> 2] = compare;
	timer_reset(base);
}

void timer_reset(volatile uint32_t * base)
{
	base[TIMER_CTRL >> 2] = 1 << TIMER_CTRL_RUN | 1 << TIMER_CTRL_CLEAR;
}

