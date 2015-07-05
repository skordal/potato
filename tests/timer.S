# The Potato Processor - A simple RISC-V based processor for FPGAs
# (c) Kristian Klomsten Skordal 2014 - 2015 <kristian.skordal@wafflemail.net>
# Report bugs and issues on <http://opencores.org/project,potato,bugtracker>

# Simplified timer interrupt test.

#include "riscv_test.h"
#include "test_macros.h"

#define TIMER_DELTA_T	10
#define MIE_STIE MIP_STIP

RVTEST_RV32M
RVTEST_CODE_BEGIN

	li s8, 0  # Number of timer interrupts taken
	li s9, 10 # Number of timer interrupts to wait for

	# Set the time of the next timer interrupt:
	csrr a0, mtime
	addi a0, a0, TIMER_DELTA_T
	csrw mtimecmp, a0

	# Enable the timer interrupt:
	li a0, (1 << 7)
	csrs mie, a0
	csrs mstatus, MSTATUS_IE

wait_for_count:
	# TODO: wfi not yet supported	
	j wait_for_count

mtvec_handler:
	li t0, (1 << 31) + 1 # Interrupt bit set + timer interrupt exception code

	csrr t1, mcause
	bne t0, t1, fail # Fail if not timer interrupt
	
	addi s8, s8, 1
	beq s8, s9, pass # Pass the test if the correct number of interrupts have been taken

	# Reset the timer:
	csrr a0, mtime
	addi a0, a0, TIMER_DELTA_T
	csrw mtimecmp, a0

	eret

TEST_PASSFAIL
RVTEST_CODE_END

.data
RVTEST_DATA_BEGIN
	TEST_DATA
RVTEST_DATA_END

