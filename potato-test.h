// The Potato Processor
// (c) Kristian Klomsten Skordal 2017 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/potato/issues>

#ifndef POTATO_TEST_H
#define POTATO_TEST_H

// Ensure that the following define is set to use this header in assembly code:
// #define POTATO_TEST_ASSEMBLY

// Address of the test and debug CSR:
#define POTATO_TEST_CSR		0xbf0

// Value of the test state field when no test is running:
#define POTATO_TEST_STATE_IDLE		0x0
// Value of the test state field when a test is running:
#define POTATO_TEST_STATE_RUNNING	0x1
// Value of the test state field when a test has failed:
#define POTATO_TEST_STATE_FAILED	0x2
// Value of the test state field when a test has passed:
#define POTATO_TEST_STATE_PASSED	0x3

#ifdef POTATO_TEST_ASSEMBLY

#define POTATO_TEST_START(testnum, tempreg) \
	li tempreg, testnum; \
	slli tempreg, tempreg, 2; \
	ori tempreg, tempreg, POTATO_TEST_STATE_RUNNING; \
	csrw POTATO_TEST_CSR, tempreg;

#define POTATO_TEST_FAIL() \
	csrci POTATO_TEST_CSR, 3; \
	csrsi POTATO_TEST_CSR, POTATO_TEST_STATE_FAILED;

#define POTATO_TEST_PASS() \
	csrci POTATO_TEST_CSR, 3; \
	csrsi POTATO_TEST_CSR, POTATO_TEST_STATE_PASSED;
#else

#define POTATO_TEST_START(testnum) \
	do { \
		uint32_t temp = testnum << 3 | POTATO_TEST_STATE_RUNNING; \
		asm volatile("csrw %[regname], %[regval]\n\t" :: [regname] "i" (POTATO_TEST_CSR), [regval] "r" (temp)); \
	} while(0)

#define POTATO_TEST_FAIL() \
	asm volatile("csrrci x0, %[regname], 3\n\tcsrrsi x0, %[regname], %[state]\n\t" \
		:: [regname] "i" (POTATO_TEST_CSR), [state] "i" (POTATO_TEST_STATE_FAILED))
#define POTATO_TEST_PASS() \
	asm volatile("csrrci x0, %[regname], 3\n\tcsrrsi x0, %[regname], %[state]\n\t" \
		:: [regname] "i" (POTATO_TEST_CSR), [state] "i" (POTATO_TEST_STATE_PASSED))
#endif

#endif

