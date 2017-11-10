-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 - 2015 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;

package pp_types is

	--! Type used for register addresses.
	subtype register_address is std_logic_vector(4 downto 0);

	--! The available ALU operations.
	type alu_operation is (
			ALU_AND, ALU_OR, ALU_XOR,
			ALU_SLT, ALU_SLTU,
			ALU_ADD, ALU_SUB,
			ALU_SRL, ALU_SLL, ALU_SRA,
			ALU_NOP, ALU_INVALID
		);

	--! Types of branches.
	type branch_type is (
			BRANCH_NONE, BRANCH_JUMP, BRANCH_JUMP_INDIRECT, BRANCH_CONDITIONAL, BRANCH_SRET
		);

	--! Source of an ALU operand.
	type alu_operand_source is (
			ALU_SRC_REG, ALU_SRC_IMM, ALU_SRC_SHAMT, ALU_SRC_PC, ALU_SRC_PC_NEXT, ALU_SRC_NULL, ALU_SRC_CSR
		);

	--! Type of memory operation:
	type memory_operation_type is (
			MEMOP_TYPE_NONE, MEMOP_TYPE_INVALID, MEMOP_TYPE_LOAD, MEMOP_TYPE_LOAD_UNSIGNED, MEMOP_TYPE_STORE
		);

	-- Determines if a memory operation is a load:
	function memop_is_load(input : in memory_operation_type) return boolean;

	--! Size of a memory operation:
	type memory_operation_size is (
			MEMOP_SIZE_BYTE, MEMOP_SIZE_HALFWORD, MEMOP_SIZE_WORD
		);

	--! Wishbone master output signals:
	type wishbone_master_outputs is record	
			adr : std_logic_vector(31 downto 0);
			sel : std_logic_vector( 3 downto 0);
			cyc : std_logic;
			stb : std_logic;
			we  : std_logic;
			dat : std_logic_vector(31 downto 0);
		end record; 

	--! Wishbone master input signals:
	type wishbone_master_inputs is record
			dat : std_logic_vector(31 downto 0);
			ack : std_logic;
		end record;

	--! State of the currently running test:
	type test_state is (TEST_IDLE, TEST_RUNNING, TEST_FAILED, TEST_PASSED);

	--! Current test context:
	type test_context is record
			state  : test_state;
			number : std_logic_vector(29 downto 0);
		end record;

	--! Converts a test context to an std_logic_vector:
	function test_context_to_std_logic(input : in test_context) return std_logic_vector;

	--! Converts an std_logic_vector to a test context:
	function std_logic_to_test_context(input : in std_logic_vector(31 downto 0)) return test_context;

end package pp_types;

package body pp_types is

	function memop_is_load(input : in memory_operation_type) return boolean is
	begin
		return (input = MEMOP_TYPE_LOAD or input = MEMOP_TYPE_LOAD_UNSIGNED);
	end function memop_is_load;

	function test_context_to_std_logic(input : in test_context) return std_logic_vector is
		variable retval : std_logic_vector(31 downto 0);
	begin
		case input.state is
			when TEST_IDLE =>
				retval(1 downto 0) := b"00";
			when TEST_RUNNING =>
				retval(1 downto 0) := b"01";
			when TEST_FAILED =>
				retval(1 downto 0) := b"10";
			when TEST_PASSED =>
				retval(1 downto 0) := b"11";
		end case;

		retval(31 downto 2) := input.number;
		return retval;
	end function test_context_to_std_logic;

	function std_logic_to_test_context(input : in std_logic_vector(31 downto 0)) return test_context is
		variable retval : test_context;
	begin
		case input(1 downto 0) is
			when b"00" =>
				retval.state := TEST_IDLE;
			when b"01" =>
				retval.state := TEST_RUNNING;
			when b"10" =>
				retval.state := TEST_FAILED;
			when b"11" =>
				retval.state := TEST_PASSED;
			when others =>
				retval.state := TEST_FAILED;
		end case;

		retval.number := input(31 downto 2);
		return retval;
	end function std_logic_to_test_context;

end package body pp_types;
