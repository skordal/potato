-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 - 2015 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <http://opencores.org/project,potato,bugtracker>

library ieee;
use ieee.std_logic_1164.all;

--! @brief Package containing constants and utility functions relating to status and control registers.
package pp_csr is

	--! Type used for specifying control and status register addresses.
	subtype csr_address is std_logic_vector(11 downto 0);

	--! Type used for exception cause values.
	subtype csr_exception_cause is std_logic_vector(5 downto 0); -- Upper bit is the interrupt bit

	--! Converts an exception cause to a std_logic_vector.
	function to_std_logic_vector(input : in csr_exception_cause) return std_logic_vector;

	--! Control/status register write mode:
	type csr_write_mode is (
			CSR_WRITE_NONE, CSR_WRITE_SET, CSR_WRITE_CLEAR, CSR_WRITE_REPLACE
		);

	-- Exception cause values:
	constant CSR_CAUSE_INSTR_MISALIGN : csr_exception_cause := b"000000";
	constant CSR_CAUSE_INSTR_FETCH    : csr_exception_cause := b"000001";
	constant CSR_CAUSE_INVALID_INSTR  : csr_exception_cause := b"000010";
	constant CSR_CAUSE_BREAKPOINT     : csr_exception_cause := b"000011";
	constant CSR_CAUSE_LOAD_MISALIGN  : csr_exception_cause := b"000100";
	constant CSR_CAUSE_LOAD_ERROR     : csr_exception_cause := b"000101";
	constant CSR_CAUSE_STORE_MISALIGN : csr_exception_cause := b"000110";
	constant CSR_CAUSE_STORE_ERROR    : csr_exception_cause := b"000111";
	constant CSR_CAUSE_ECALL          : csr_exception_cause := b"001011";
	constant CSR_CAUSE_NONE           : csr_exception_cause := b"011111";

	constant CSR_CAUSE_SOFTWARE_INT   : csr_exception_cause := b"100000";
	constant CSR_CAUSE_TIMER_INT      : csr_exception_cause := b"100001";
	constant CSR_CAUSE_IRQ_BASE       : csr_exception_cause := b"110000";

	-- Control register IDs, specified in the immediate field of csr* instructions:
	constant CSR_CYCLE    : csr_address := x"c00";
	constant CSR_CYCLEH   : csr_address := x"c80";
	constant CSR_TIME     : csr_address := x"c01";
	constant CSR_TIMEH    : csr_address := x"c81";
	constant CSR_INSTRET  : csr_address := x"c02";
	constant CSR_INSTRETH : csr_address := x"c82";

	constant CSR_MCPUID   : csr_address := x"f00";
	constant CSR_MIMPID   : csr_address := x"f01";
	constant CSR_MHARTID  : csr_address := x"f10";

	constant CSR_MSTATUS  : csr_address := x"300";
	constant CSR_MTVEC    : csr_address := x"301";
	constant CSR_MTDELEG  : csr_address := x"302";
	constant CSR_MIE      : csr_address := x"304";

	constant CSR_MTIMECMP : csr_address := x"321";
	constant CSR_MTIME    : csr_address := x"701";

	constant CSR_MSCRATCH : csr_address := x"340";
	constant CSR_MEPC     : csr_address := x"341";
	constant CSR_MCAUSE   : csr_address := x"342";
	constant CSR_MBADADDR : csr_address := x"343";
	constant CSR_MIP      : csr_address := x"344";

	constant CSR_MTOHOST   : csr_address := x"780";
	constant CSR_MFROMHOST : csr_address := x"781";

	-- Values used as control register IDs in ERET:
	constant CSR_EPC_ERET   : csr_address := x"100";

	-- Offset into the exception vector for handling machine-mode exceptions:
	constant CSR_MTVEC_M_OFFSET : natural := 192;

	-- Additional CSRs from supervisor mode that aliases machine mode registers
	-- in this implementation:
	--constant CSR_STVEC : csr_address := x"101";
	--constant CSR_SEPC  : csr_address := x"141";

	-- Status register bit indices:
	constant CSR_SR_IE  : natural := 0;
	constant CSR_SR_IE1 : natural := 3;

	-- MIE and MIP register bit indices:
	constant CSR_MIE_MSIE : natural := 3;
	constant CSR_MIE_MTIE : natural := 7;
	constant CSR_MIP_MSIP : natural := CSR_MIE_MSIE;
	constant CSR_MIP_MTIP : natural := CSR_MIE_MTIE;

	-- Exception context; this record contains all state that can be manipulated
	-- when an exception is taken.
	type csr_exception_context is
		record
			ie, ie1 : std_logic; -- Enable Interrupt bits
			cause   : csr_exception_cause;
			badaddr : std_logic_vector(31 downto 0);
		end record;

	--! Creates the value of the mstatus registe from the EI and EI1 bits.
	function csr_make_mstatus(ie, ie1 : in std_logic) return std_logic_vector;

end package pp_csr;

package body pp_csr is

	function to_std_logic_vector(input : in csr_exception_cause)
		return std_logic_vector is
	begin
		return (31 => input(5), 30 downto 5 => '0') & input(4 downto 0);
	end function to_std_logic_vector;

	function csr_make_mstatus(ie, ie1 : in std_logic) return std_logic_vector is
		variable retval : std_logic_vector(31 downto 0);
	begin
		retval := (
			11 downto 10 => '1', -- PRV3
			 8 downto  7 => '1', -- PRV2
			 5 downto  4 => '1', -- PRV1
			 CSR_SR_IE1 => ie1,  -- IE1
			 2 downto  1 => '1', -- PRV
			 CSR_SR_IE => ie,    -- IE
			others => '0');
		return retval;
	end function csr_make_mstatus;

end package body pp_csr;
