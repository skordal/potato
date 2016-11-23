-- The Potato Processor - SoC design for the Arty FPGA board
-- (c) Kristian Klomsten Skordal 2016 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_utilities.all;

entity aee_rom_wrapper is
	generic(
		MEMORY_SIZE : natural := 4096 --! Memory size in bytes.
	);
	port(
		clk   : in std_logic;
		reset : in std_logic;

		-- Wishbone interface:
		wb_adr_in  : in  std_logic_vector(log2(MEMORY_SIZE) - 1 downto 0);
		wb_dat_out : out std_logic_vector(31 downto 0);
		wb_cyc_in  : in  std_logic;
		wb_stb_in  : in  std_logic;
		wb_sel_in  : in  std_logic_vector(3 downto 0);
		wb_ack_out : out std_logic
	);
end entity aee_rom_wrapper;

architecture behaviour of aee_rom_wrapper is
	signal ack : std_logic;

	signal read_data : std_logic_vector(31 downto 0);
	signal data_mask : std_logic_vector(31 downto 0);

begin

	rom: entity work.aee_rom
		port map(
			clka => clk,
			addra => wb_adr_in(log2(MEMORY_SIZE) - 1 downto 2),
			douta => read_data
		);

	data_mask <= (31 downto 24 => wb_sel_in(3), 23 downto 16 => wb_sel_in(2),
		15 downto 8 => wb_sel_in(1), 7 downto 0 => wb_sel_in(0));

	wb_dat_out <= read_data and data_mask;

	wb_ack_out <= ack and wb_cyc_in and wb_stb_in;

	wishbone: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				ack <= '0';
			else
				if wb_cyc_in = '1' and wb_stb_in = '1' then
					ack <= '1';
				else
					ack <= '0';
				end if;
			end if;
		end if;
	end process wishbone;

end architecture behaviour;
