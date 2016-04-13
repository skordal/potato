/* Linker script for standalone test applications for the Potato SoC
 * (c) Kristian Klomsten Skordal 2016 <kristian.skordal@wafflemail.net>
 * Report bugs and issues on <https://github.com/skordal/potato/issues>
 */

ENTRY(_start)

MEMORY
{
	RAM (rwx)    : ORIGIN = 0x00000000, LENGTH = 0x10000000 /* Not implemented! */
	AEE_ROM (rx) : ORIGIN = 0xffff8000, LENGTH = 0x00004000
	AEE_RAM (rw) : ORIGIN = 0xffffc000, LENGTH = 0x00004000
}

SECTIONS
{
	.text 0xffff8100 :
	{
		*(.init)
		*(.text*)
		__text_end = .;
	} > AEE_ROM

	.data : AT(ADDR(.text) + SIZEOF(.text))
	{
		__data_begin = .;
		*(.eh_frame*)
		/* The .rodata could be placed in ROM, but the ROM module does not
		 * currently support anything other than 32-bit accesses, so it must
		 * be placed in .data until this has been fixed.
		 */
		*(.rodata*)
		*(.data*)
		__data_end = ALIGN(4);
	} > AEE_RAM

	.bss ALIGN(4) :
	{
		__bss_begin = .;
		*(.bss*)
		*(.sbss)
		__bss_end = ALIGN(4);
	} > AEE_RAM

	/DISCARD/ :
	{
		*(.comment)
	}
}

