/*
 * Linker Script for the Potato Processor software applications
 * (c) Kristian Klomsten Skordal 2014 - 2016 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/potato/issues>
 */

/*
 * The linker script is intended to be used with the "official" test platform,
 * described in platform.h.
 */

ENTRY(_start);

SECTIONS
{
	.text 0x100 :
	{
		*(.init)
		*(.text*)
		__text_end = .;
	}

	.data 0x2000 : AT(ADDR(.text) + SIZEOF(.text))
	{
		__data_begin = .;
		*(.rodata*)
		*(.data*)
		__data_end = ALIGN(4);
	}

	.bss ALIGN(4):
	{
		__bss_begin = .;
		*(.bss*)
		__bss_end = ALIGN(4);
	}

	__stack_top = 0x4000;
}


