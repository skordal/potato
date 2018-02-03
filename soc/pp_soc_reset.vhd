-- The Potato Processor - SoC design for the Arty FPGA board
-- (c) Kristian Klomsten Skordal 2018 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;

--! @brief System reset unit.
--! Because most resets in the processor core are synchronous, at least one
--! clock pulse has to be given to the processor while the reset signal is
--! asserted. However, if the clock generator is being reset at the same time,
--! the system clock might not run during reset, preventing the processor from
--! properly resetting.
entity pp_soc_reset is
	generic(
		RESET_CYCLE_COUNT : natural := 2
	);
	port(
		reset_n : in std_logic;
		reset_out : out std_logic;

		system_clk : in std_logic;
		system_clk_locked : in std_logic
	);
end entity pp_soc_reset;

architecture behaviour of pp_soc_reset is

	subtype counter_type is natural range 0 to RESET_CYCLE_COUNT;
	signal counter : counter_type;

	signal delayed_reset : std_logic;
begin

	delayed_reset <= '1' when counter /= 0 else '0';
	reset_out <= not system_clk_locked or not reset_n or delayed_reset;

	process(system_clk_locked, reset_n, system_clk)
	begin
		if system_clk_locked = '0' or reset_n = '0' then
			counter <= RESET_CYCLE_COUNT;
		elsif rising_edge(system_clk) then
			if counter /= 0 then
				counter <= counter - 1;
			end if;
		end if;
	end process;

end architecture behaviour;
