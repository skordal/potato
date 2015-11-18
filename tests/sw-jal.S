# The Potato Processor - A simple RISC-V based processor for FPGAs
# (c) Kristian Klomsten Skordal 2014 - 2015 <kristian.skordal@wafflemail.net>
# Report bugs and issues on <https://github.com/skordal/potato/issues>

#include "riscv_test.h"
#include "test_macros.h"

.section .text
RVTEST_RV32M
RVTEST_CODE_BEGIN

test_1:
	li TESTNUM, 1

	la ra, test_failed
	la sp, temp
	sw ra, 0(sp)
	jal ra, test_cmp

1:
	j fail
	j pass

test_cmp:
	la t0, 1b
	bne ra, t0, fail
	addi ra, ra, 4
	ret

TEST_PASSFAIL
RVTEST_CODE_END

test_failed:
	RVTEST_FAIL
	
.section .data
RVTEST_DATA_BEGIN
	TEST_DATA

# Allocate a 32-bit word to store some data into
#.section .data
temp:
	.word 0x00000000

RVTEST_DATA_END

