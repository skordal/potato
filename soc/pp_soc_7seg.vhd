-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pp_soc_7seg is
	generic(
		NUM_DISPLAYS         : natural := 8;     -- Number of 7-segment displays connected to the module.
		SWITCH_COUNT         : natural;          -- How many ticks of the input clock to count before switching displays.
		CATHODE_ENABLE_VALUE : std_logic := '0'; -- Value of the cathode output when enabled.
		ANODE_ENABLE_VALUE   : std_logic := '0'  -- Value of the anode output when enabled.
	);
	port(
		clk   : in std_logic;
		reset : in std_logic;

		-- Connections to the displays:
		seg7_anode   : out std_logic_vector(NUM_DISPLAYS - 1 downto 0); -- One for each display
		seg7_cathode : out std_logic_vector(6 downto 0);

		-- Wishbone interface:
		wb_adr_in  : in  std_logic_vector( 0 downto 0);
		wb_dat_in  : in  std_logic_vector(31 downto 0);
		wb_dat_out : out std_logic_vector(31 downto 0);
		wb_cyc_in  : in  std_logic;
		wb_stb_in  : in  std_logic;
		wb_we_in   : in  std_logic;
		wb_ack_out : out std_logic
	);
end entity pp_soc_7seg;

architecture behaviour of pp_soc_7seg is
	signal ctrl_value  : std_logic_vector(NUM_DISPLAYS * 4 - 1 downto 0);
	signal ctrl_enable : std_logic_vector(NUM_DISPLAYS - 1 downto 0);

	type seg7_array is array (0 to NUM_DISPLAYS - 1) of std_logic_vector(6 downto 0);
	signal output_array : seg7_array;

	subtype display_counter_type is natural range 0 to NUM_DISPLAYS - 1;
	signal active_display : display_counter_type := 0;

	constant ANODE_DISABLE_VALUE : std_logic := not ANODE_ENABLE_VALUE;

	subtype switch_counter_type is natural range 0 to SWITCH_COUNT - 1;
	signal switch_counter : switch_counter_type := 0;

	signal anodes : std_logic_vector(NUM_DISPLAYS - 1 downto 0);

	-- Wishbone controller acknowledge signal:
	signal ack : std_logic;
begin

	assert NUM_DISPLAYS <= 8 and NUM_DISPLAYS > 0
		report "Only 1 - 8 displays are supported by the 7-seg module!"
		severity FAILURE;

	-- Connect display outputs:
	seg7_cathode <= output_array(active_display) when CATHODE_ENABLE_VALUE = '0' else not output_array(active_display);
	seg7_anode <= anodes and not ctrl_enable when ANODE_ENABLE_VALUE = '1' else anodes and ctrl_enable;

	-- Create one decoder for each display:
	generate_decoders: for i in 0 to NUM_DISPLAYS - 1
	generate
		decoder: entity work.pp_seg7dec
			port map(
				input => ctrl_value(i * 4 + 3 downto i * 4),
				output => output_array(i)
			);
	end generate;

	-- Switch between the displays:
	switch_displays: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				anodes <= (0 => ANODE_ENABLE_VALUE, others => ANODE_DISABLE_VALUE);
				active_display <= 0;
			else
				if switch_counter = SWITCH_COUNT - 1 then
					anodes <= std_logic_vector(rotate_left(unsigned(anodes), 1));
					switch_counter <= 0;
					if active_display = NUM_DISPLAYS - 1 then
						active_display <= 0;
					else
						active_display <= active_display + 1;
					end if;
				else
					switch_counter <= switch_counter + 1;
				end if;
			end if;
		end if;
	end process switch_displays;

	----- Wishbone controller: -----
	wb_ack_out <= ack and wb_cyc_in and wb_stb_in;
	wishbone: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				ctrl_value <= (others => '0');
				ctrl_enable <= (others => '1');
				wb_dat_out <= (others => '0');
				ack <= '0';
			else
				if wb_cyc_in = '1' and wb_stb_in = '1' and ack = '0' then
					if wb_we_in = '1' then
						case wb_adr_in is
							when b"0" =>
								ctrl_enable <= wb_dat_in(NUM_DISPLAYS - 1 downto 0);
							when b"1" =>
								ctrl_value <= wb_dat_in(NUM_DISPLAYS * 4 - 1 downto 0);
							when others =>
						end case;
						ack <= '1';
					else
						case wb_adr_in is
							when b"0" =>
								wb_dat_out <= std_logic_vector(resize(unsigned(ctrl_enable), wb_dat_out'length));
							when b"1" =>
								wb_dat_out <= std_logic_vector(resize(unsigned(ctrl_value), wb_dat_out'length)); 
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
