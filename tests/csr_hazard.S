// The Potato Processor
// (c) Kristian Klomsten Skordal 2017 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/potato/issues>

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32M
RVTEST_CODE_BEGIN

	li TESTNUM, 1
	li x1, 4
	li x2, 5
	li x3, 6
	csrw mscratch, x1
	csrr x4, mscratch
	bne x4, x1, fail

	li TESTNUM, 2
	csrw mscratch, x1
	csrw mscratch, x2
	csrr x4, mscratch
	bne x4, x2, fail

	li TESTNUM, 3
	csrw mscratch, x1
	csrw mscratch, x2
	csrw mscratch, x3
	csrr x4, mscratch
	bne x4, x3, fail

	TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END


