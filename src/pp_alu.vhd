-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_types.all;

--! @brief
--!	Arithmetic Logic Unit (ALU).
--!
--! @details
--! 	Performs logic and arithmetic calculations. The operation to perform
--!	is specified by the user of the module.
entity pp_alu is
	port(
		x, y      : in  std_logic_vector(31 downto 0); --! Input operand.
		result    : out std_logic_vector(31 downto 0); --! Operation result.
		operation : in alu_operation                   --! Operation type.
	);
end entity pp_alu;

--! @brief Behavioural description of the ALU.
architecture behaviour of pp_alu is
begin

	--! Performs the ALU calculation.
	calculate: process(operation, x, y)
	begin
		case operation is
			when ALU_AND =>
				result <= x and y;
			when ALU_OR =>
				result <= x or y;
			when ALU_XOR =>
				result <= x xor y;
			when ALU_SLT =>
				if signed(x) < signed(y) then
					result <= (0 => '1', others => '0');
				else
					result <= (others => '0');
				end if;
			when ALU_SLTU =>
				if unsigned(x) < unsigned(y) then
					result <= (0 => '1', others => '0');
				else
					result <= (others => '0');
				end if;
			when ALU_ADD =>
				result <= std_logic_vector(unsigned(x) + unsigned(y));
			when ALU_SUB =>
				result <= std_logic_vector(unsigned(x) - unsigned(y));
			when ALU_SRL =>
				result <= std_logic_vector(shift_right(unsigned(x), to_integer(unsigned(y(4 downto 0)))));
			when ALU_SLL =>
				result <= std_logic_vector(shift_left(unsigned(x), to_integer(unsigned(y(4 downto 0)))));
			when ALU_SRA =>
				result <= std_logic_vector(shift_right(signed(x), to_integer(unsigned(y(4 downto 0)))));
			when others =>
				result <= (others => '0');
		end case;
	end process calculate;

end architecture behaviour;
