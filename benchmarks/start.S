// The Potato Processor Benchmark Applications
// (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <http://opencores.org/project,potato,bugtracker>

// This file contains startup and initialization code for the Potato benchmark
// applications.

#include "platform.h"

.section .init

.global _start
_start:

// Copies the .data section into the data memory section:
.hidden copy_data
copy_data:
	la x1, __text_end	// Copy source address
	la x2, __data_begin	// Copy destination address
	la x3, __data_end	// Copy destination end address

	beq x2, x3, 2f		// Skip if there is no data to copy

1:
	lw x4, (x1)
	sw x4, (x2)
	addi x1, x1, 4
	addi x2, x2, 4

	bne x2, x3, 1b		// Repeat as long as there is more data to copy
2:

.hidden clear_bss
clear_bss:
	la x1, __bss_begin
	la x2, __bss_end
	beq x1, x2, 2f		// Skip if there is no .bss section

1:
	sw x0, (x1)
	addi x1, x1, 4
	bne x1, x2, 1b

2:

.hidden set_evec
set_evec:
	// Set up an exception handler:
	la x1, exception_handler_wrapper
	csrw evec, x1

.hidden call_main
call_main:
	la sp, __stack_top
	jal main
	csrw tohost, a0
1:
	j 1b

.section .text

.global exception_handler_wrapper
exception_handler_wrapper:
	// Save all registers that aren't saved by the IRQ handler function:
	addi sp, sp, -64
	sw ra, 0(sp)
	sw t0, 4(sp)
	sw t1, 8(sp)
	sw t2, 12(sp)
	sw t3, 16(sp)
	sw t4, 20(sp)
	sw t5, 24(sp)
	sw t6, 28(sp)
	sw a0, 32(sp)
	sw a1, 36(sp)
	sw a2, 40(sp)
	sw a3, 44(sp)
	sw a4, 48(sp)
	sw a5, 52(sp)
	sw a6, 56(sp)
	sw a7, 60(sp)

	csrr a0, cause
	csrr a1, epc
	jal exception_handler

	// Restore the current state:
	lw ra, 0(sp)
	lw t0, 4(sp)
	lw t1, 8(sp)
	lw t2, 12(sp)
	lw t3, 16(sp)
	lw t4, 20(sp)
	lw t5, 24(sp)
	lw t6, 28(sp)
	lw a0, 32(sp)
	lw a1, 36(sp)
	lw a2, 40(sp)
	lw a3, 44(sp)
	lw a4, 48(sp)
	lw a5, 52(sp)
	lw a6, 56(sp)
	lw a7, 60(sp)
	addi sp, sp, 64

	sret

