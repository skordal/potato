# The Potato Application Execution Environment (PAEE)
# (c) Kristian Klomsten Skordal 2016 <kristian.skordal@wafflemail.net>
# Report bugs and issues on <https://github.com/skordal/potato/issues>

.section .init

.align 6
tvec_user: // User mode is not supported by Potato
	j tvec_machine
.align 6
tvec_supervisor: // Supervisor mode is not supported by Potato
	j tvec_machine
.align 6
tvec_hypervisor: // Hypervisor mode is not supported by Potato
	j tvec_machine
.align 6
tvec_machine:
	j _machine_exception_handler

.align 6
.global _start
_start:

// Sets the exception handler address:
.hidden init_mtvec
init_mtvec:
	la x1, tvec_user
	csrw mtvec, x1

// Copies the .data section into the data memory section:
.hidden copy_data
copy_data:
	la x1, __text_end	// Copy source address
	la x2, __data_begin	// Copy destination address
	la x3, __data_end	// Copy destination end address

	beq x2, x3, 2f		// Skip if there is no data to copy

1:
	lb x4, (x1)
	sb x4, (x2)
	addi x1, x1, 1
	addi x2, x2, 1

	bne x2, x3, 1b		// Repeat as long as there is more data to copy
2:

// Clears the .bss (zero initialized data) section:
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

// Sets up the stack pointer:
.hidden init_stack
init_stack:
	xor sp, sp, sp		// Zero the stack pointer to start from the top of RAM

.hidden call_main
call_main:
	call main

1:
	j 1b

.global _machine_exception_handler
_machine_exception_handler:
	// Save all registers (to aid in debugging):
	addi sp, sp, -124
	sw x1, 0(sp)
	sw x2, 4(sp)
	sw x3, 8(sp)
	sw x4, 12(sp)
	sw x5, 16(sp)
	sw x6, 20(sp)
	sw x7, 24(sp)
	sw x8, 28(sp)
	sw x9, 32(sp)
	sw x10, 36(sp)
	sw x11, 40(sp)
	sw x12, 44(sp)
	sw x13, 48(sp)
	sw x14, 52(sp)
	sw x15, 56(sp)
	sw x16, 60(sp)
	sw x17, 64(sp)
	sw x18, 68(sp)
	sw x19, 72(sp)
	sw x20, 76(sp)
	sw x21, 80(sp)
	sw x22, 84(sp)
	sw x23, 88(sp)
	sw x24, 92(sp)
	sw x25, 96(sp)
	sw x26, 100(sp)
	sw x27, 104(sp)
	sw x28, 108(sp)
	sw x29, 112(sp)
	sw x30, 116(sp)
	sw x31, 120(sp)

	csrr a0, mcause # First parameter: cause
	csrr a1, mepc   # Second parameter: exception location
	mv a2, sp	# Third parameter: start of stored register array
	call exception_handler

.hidden _machine_exception_return
_machine_exception_return:
	// Restore all registers:
	lw x1, 0(sp)
	# lw x2, 4(sp) <- x2 = sp, so do not load this register
	lw x3, 8(sp)
	lw x4, 12(sp)
	lw x5, 16(sp)
	lw x6, 20(sp)
	lw x7, 24(sp)
	lw x8, 28(sp)
	lw x9, 32(sp)
	lw x10, 36(sp)
	lw x11, 40(sp)
	lw x12, 44(sp)
	lw x13, 48(sp)
	lw x14, 52(sp)
	lw x15, 56(sp)
	lw x16, 60(sp)
	lw x17, 64(sp)
	lw x18, 68(sp)
	lw x19, 72(sp)
	lw x20, 76(sp)
	lw x21, 80(sp)
	lw x22, 84(sp)
	lw x23, 88(sp)
	lw x24, 92(sp)
	lw x25, 96(sp)
	lw x26, 100(sp)
	lw x27, 104(sp)
	lw x28, 108(sp)
	lw x29, 112(sp)
	lw x30, 116(sp)
	lw x31, 120(sp)
	addi sp, sp, 124

	mret

