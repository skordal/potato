-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;

use work.pp_types.all;
use work.pp_constants.all;

package pp_utilities is

	--! Converts a boolean to an std_logic.
	function to_std_logic(input : in boolean) return std_logic;

	-- Checks if a number is 2^n:
	function is_pow2(input : in natural) return boolean;

	--! Calculates log2 with integers.
	function log2(input : in natural) return natural;

end package pp_utilities;

package body pp_utilities is

	function to_std_logic(input : in boolean) return std_logic is
	begin
		if input then
			return '1';
		else
			return '0';
		end if;
	end function to_std_logic;

	function is_pow2(input : in natural) return boolean is
		variable c : natural := 1;
	begin
		for i in 0 to 31 loop
			if input = i then
				return true;
			end if;

			c := c * 2;
		end loop;

		return false;
	end function is_pow2;

	function log2(input : in natural) return natural is
		variable retval : natural := 0;
		variable temp   : natural := input;
	begin
		while temp > 1 loop
			retval := retval + 1;
			temp := temp / 2;
		end loop;

		return retval;
	end function log2;

end package body pp_utilities;
