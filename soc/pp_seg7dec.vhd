-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;

-- @brief 7-Segment Display Decoder
entity pp_seg7dec is
	port(
		input  : in  std_logic_vector(3 downto 0);
		output : out std_logic_vector(6 downto 0)
	);
end entity pp_seg7dec;

architecture behaviour of pp_seg7dec is
begin

	decoder: process(input)
	begin
		case input is
			when x"0" =>
				output <= b"1000000";
			when x"1" =>
				output <= b"1111001";
			when x"2" =>
				output <= b"0100100";
			when x"3" =>
				output <= b"0110000";
			when x"4" =>
				output <= b"0011001";
			when x"5" =>
				output <= b"0010010";
			when x"6" =>
				output <= b"0000010";
			when x"7" =>
				output <= b"1111000";
			when x"8" =>
				output <= b"1111111";
			when x"9" =>
				output <= b"0011000";
			when x"a" =>
				output <= b"0001000";
			when x"b" =>
				output <= b"0000011";
			when x"c" =>
				output <= b"1000110";
			when x"d" =>
				output <= b"0100001";
			when x"e" =>
				output <= b"0000110";
			when x"f" =>
				output <= b"0001110";
		end case;
	end process decoder;

end architecture behaviour;
