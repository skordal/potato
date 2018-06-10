-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 - 2015 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;

use work.pp_constants.all;
use work.pp_csr.all;
use work.pp_types.all;
use work.pp_utilities.all;

--! @brief
--! 	Instruction decoding and control unit.
--! @details
--!	Decodes incoming instructions and sets control signals accordingly.
--!	Unknown or otherwise invalid instructions will cause an exception to
--!	be signaled.
entity pp_control_unit is
	port(
		-- Inputs, indices correspond to instruction word indices:
		opcode  : in std_logic_vector( 4 downto 0); --! Instruction opcode field.
		funct3  : in std_logic_vector( 2 downto 0); --! Instruction @c funct3 field.
		funct7  : in std_logic_vector( 6 downto 0); --! Instruction @c funct7 field.
		funct12 : in std_logic_vector(11 downto 0); --! Instruction @c funct12 field.

		-- Control signals:
		rd_write            : out std_logic;   --! Signals that the instruction writes to a destination register.
		branch              : out branch_type; --! Signals that the instruction is a branch.

		-- Exception signals:
		decode_exception       : out std_logic;           --! Signals an instruction decode exception.
		decode_exception_cause : out csr_exception_cause; --! Specifies the cause of a decode exception.

		-- Control register signals:
		csr_write : out csr_write_mode; --! Write mode for instructions accessing CSRs.
		csr_imm   : out std_logic;      --! Indicates an immediate variant of a CSR instruction.

		-- Sources of operands to the ALU:
		alu_x_src, alu_y_src : out alu_operand_source; --! ALU operand source.

		-- ALU operation:
		alu_op : out alu_operation; --! ALU operation to perform for the instruction.

		-- Memory transaction parameters:
		mem_op   : out memory_operation_type; --! Memory operation to perform for the instruction.
		mem_size : out memory_operation_size  --! Size of the memory operation to perform.
	);
end entity pp_control_unit;

--! @brief Behavioural description of the instruction decoding and control unit.
architecture behaviour of pp_control_unit is
	signal exception       : std_logic;
	signal exception_cause : csr_exception_cause;
	signal alu_op_temp     : alu_operation;
begin

	csr_imm <= funct3(2);
	alu_op <= alu_op_temp;

	decode_exception <= exception or to_std_logic(alu_op_temp = ALU_INVALID);
	decode_exception_cause <= exception_cause when alu_op_temp /= ALU_INVALID
		else CSR_CAUSE_INVALID_INSTR;

	--! @brief   ALU control unit.
	--! @details Decodes arithmetic and logic instructions and sets the
	--!          control signals relating to the ALU.
	alu_control: entity work.pp_alu_control_unit
		port map(
			opcode => opcode,
			funct3 => funct3,
			funct7 => funct7,
			alu_x_src => alu_x_src,
			alu_y_src => alu_y_src,
			alu_op => alu_op_temp
		);

	--! @brief Decodes instructions.
	decode_ctrl: process(opcode, funct3, funct12)
	begin
		case opcode is
			when b"01101" => -- Load upper immediate
				rd_write <= '1';
				exception <= '0';
				exception_cause <= CSR_CAUSE_NONE;
				branch <= BRANCH_NONE;
			when b"00101" => -- Add upper immediate to PC
				rd_write <= '1';
				exception <= '0';
				exception_cause <= CSR_CAUSE_NONE;
				branch <= BRANCH_NONE;
			when b"11011" => -- Jump and link
				rd_write <= '1';
				exception <= '0';
				exception_cause <= CSR_CAUSE_NONE;
				branch <= BRANCH_JUMP;
			when b"11001" => -- Jump and link register
				rd_write <= '1';
				exception <= '0';
				exception_cause <= CSR_CAUSE_NONE;
				branch <= BRANCH_JUMP_INDIRECT;
			when b"11000" => -- Branch operations
				rd_write <= '0';
				exception <= '0';
				exception_cause <= CSR_CAUSE_NONE;
				branch <= BRANCH_CONDITIONAL;
			when b"00000" => -- Load instructions
				rd_write <= '1';
				exception <= '0';
				exception_cause <= CSR_CAUSE_NONE;
				branch <= BRANCH_NONE;
			when b"01000" => -- Store instructions
				rd_write <= '0';
				exception <= '0';
				exception_cause <= CSR_CAUSE_NONE;
				branch <= BRANCH_NONE;
			when b"00100" => -- Register-immediate operations
				rd_write <= '1';
				exception <= '0';
				exception_cause <= CSR_CAUSE_NONE;
				branch <= BRANCH_NONE;
			when b"01100" => -- Register-register operations
				rd_write <= '1';
				exception <= '0';
				exception_cause <= CSR_CAUSE_NONE;
				branch <= BRANCH_NONE;
			when b"00011" => -- Fence instructions, ignored
				rd_write <= '0';
				exception <= '0';
				exception_cause <= CSR_CAUSE_NONE;
				branch <= BRANCH_NONE;
			when b"11100" => -- System instructions
				if funct3 = b"000" then
					rd_write <= '0';

					if funct12 = x"000" then
						exception <= '1';
						exception_cause <= CSR_CAUSE_ECALL;
						branch <= BRANCH_NONE;
					elsif funct12 = x"001" then
						exception <= '1';
						exception_cause <= CSR_CAUSE_BREAKPOINT;
						branch <= BRANCH_NONE;
					elsif funct12 = CSR_EPC_MRET then
						exception <= '0';
						exception_cause <= CSR_CAUSE_NONE;
						branch <= BRANCH_SRET;
					elsif funct12 = x"105" then -- WFI, currently ignored
						exception <= '0';
						exception_cause <= CSR_CAUSE_NONE;
						branch <= BRANCH_NONE;
					else
						exception <= '1';
						exception_cause <= CSR_CAUSE_INVALID_INSTR;
						branch <= BRANCH_NONE;
					end if;
				else
					rd_write <= '1';
					exception <= '0';
					exception_cause <= CSR_CAUSE_NONE;
					branch <= BRANCH_NONE;
				end if;
			when others =>
				rd_write <= '0';
				exception <= '1';
				exception_cause <= CSR_CAUSE_INVALID_INSTR;
				branch <= BRANCH_NONE;
		end case;
	end process decode_ctrl;

	--! @brief Determines the write mode of instructions accessing the CSR registers.
	decode_csr: process(opcode, funct3)
	begin
		if opcode = b"11100" then
			case funct3 is
				when b"001" | b"101" => -- csrrw/i
					csr_write <= CSR_WRITE_REPLACE;
				when b"010" | b"110" => -- csrrs/i
					csr_write <= CSR_WRITE_SET;
				when b"011" | b"111" => -- csrrc/i
					csr_write <= CSR_WRITE_CLEAR;
				when others =>
					csr_write <= CSR_WRITE_NONE;
			end case;
		else
			csr_write <= CSR_WRITE_NONE;
		end if;
	end process decode_csr;

	--! @brief Decodes the memory operation for instructions accessing memory.
	decode_mem: process(opcode, funct3)
	begin
		case opcode is
			when b"00000" => -- Load instructions
				case funct3 is
					when b"000" => -- lw
						mem_size <= MEMOP_SIZE_BYTE;
						mem_op <= MEMOP_TYPE_LOAD;
					when b"001" => -- lh
						mem_size <= MEMOP_SIZE_HALFWORD;
						mem_op <= MEMOP_TYPE_LOAD;
					when b"010" | b"110" => -- lw
						mem_size <= MEMOP_SIZE_WORD;
						mem_op <= MEMOP_TYPE_LOAD;
					when b"100" => -- lbu
						mem_size <= MEMOP_SIZE_BYTE;
						mem_op <= MEMOP_TYPE_LOAD_UNSIGNED;
					when b"101" => -- lhu
						mem_size <= MEMOP_SIZE_HALFWORD;
						mem_op <= MEMOP_TYPE_LOAD_UNSIGNED;
					when others => -- FIXME: Treat others as lw.
						mem_size <= MEMOP_SIZE_WORD;
						mem_op <= MEMOP_TYPE_INVALID;
				end case;
			when b"01000" => -- Store instructions
				case funct3 is
					when b"000" =>
						mem_op <= MEMOP_TYPE_STORE;
						mem_size <= MEMOP_SIZE_BYTE;
					when b"001" =>
						mem_op <= MEMOP_TYPE_STORE;
						mem_size <= MEMOP_SIZE_HALFWORD;
					when b"010" =>
						mem_op <= MEMOP_TYPE_STORE;
						mem_size <= MEMOP_SIZE_WORD;
					when others =>
						mem_op <= MEMOP_TYPE_INVALID;
						mem_size <= MEMOP_SIZE_WORD;
				end case;
			when others =>
				mem_op <= MEMOP_TYPE_NONE;
				mem_size <= MEMOP_SIZE_WORD;
		end case;
	end process decode_mem;

end architecture behaviour;
