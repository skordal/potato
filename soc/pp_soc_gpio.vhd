-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 - 2016 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! @brief Generic Wishbone GPIO Module.
--!
--! The following registers are defined:
--! |---------|---------------------------------------------------------------|
--! | Address | Description                                                   |
--! |---------|---------------------------------------------------------------|
--! | 0x00    | Input values, one bit per pin (read-only)                     |
--! | 0x04    | Output values, one bit per pin (read/write)                   |
--! | 0x08    | Direction register, one bit per pin. 0 is input, 1 is output. |
--! |---------|---------------------------------------------------------------|
--!
--! Writes to the output register for input pins are ignored.
entity pp_soc_gpio is
	generic(
		NUM_GPIOS : natural := 32
	);
	port(
		clk : in std_logic;
		reset : in std_logic;

		-- GPIO interface:
		gpio : inout std_logic_vector(NUM_GPIOS - 1 downto 0);

		-- Wishbone interface:
		wb_adr_in  : in  std_logic_vector(11 downto 0);
		wb_dat_in  : in  std_logic_vector(31 downto 0);
		wb_dat_out : out std_logic_vector(31 downto 0);
		wb_cyc_in  : in  std_logic;
		wb_stb_in  : in  std_logic;
		wb_we_in   : in  std_logic;
		wb_ack_out : out std_logic
	);
end entity pp_soc_gpio;

architecture behaviour of pp_soc_gpio is

	signal direction_register : std_logic_vector(NUM_GPIOS - 1 downto 0);
	signal output_register : std_logic_vector(NUM_GPIOS - 1 downto 0);
	signal input_register : std_logic_vector(NUM_GPIOS - 1 downto 0);

	signal ack : std_logic := '0';

begin

	assert NUM_GPIOS > 0 and NUM_GPIOS <= 32
		report "Only a number between 1 and 32 (inclusive) GPIOs are supported!"
		severity FAILURE;

	io_setup: for i in 0 to NUM_GPIOS - 1 generate
		gpio(i) <= 'Z' when direction_register(i) = '0' else output_register(i);
		input_register(i) <= gpio(i) when direction_register(i) = '0' else '0'; 
	end generate;

	wb_ack_out <= ack and wb_cyc_in and wb_stb_in;

	wishbone: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				direction_register <= (others => '0');
				output_register <= (others => '0');
				wb_dat_out <= (others => '0');
				ack <= '0';
			else
				if wb_cyc_in = '1' and wb_stb_in = '1' and ack = '0' then
					if wb_we_in = '1' then
						case wb_adr_in is
							when x"004" =>
								output_register <= wb_dat_in(NUM_GPIOS - 1 downto 0);
							when x"008" =>
								direction_register <= wb_dat_in(NUM_GPIOS - 1 downto 0);
							when others =>
						end case;
						ack <= '1';
					else
						case wb_adr_in is
							when x"000" =>
								wb_dat_out <= std_logic_vector(resize(unsigned(input_register), wb_dat_out'length));
							when x"004" =>
								wb_dat_out <= std_logic_vector(resize(unsigned(output_register), wb_dat_out'length));
							when x"008" =>
								wb_dat_out <= std_logic_vector(resize(unsigned(direction_register), wb_dat_out'length)); 
							when others =>
						end case;
						ack <= '1';
					end if;
				elsif wb_stb_in = '0' then
					ack <= '0';
				end if;
			end if;
		end if;
	end process wishbone;

end architecture behaviour;
