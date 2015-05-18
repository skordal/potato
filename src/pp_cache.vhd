-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 - 2015 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <http://opencores.org/project,potato,bugtracker>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_types.all;
use work.pp_utilities.all;

--! @brief Simple cache module.
entity pp_cache is
	generic(
		LINE_SIZE : natural := 8;  --! Number of words per cache way
		NUM_WAYS  : natural := 2;  --! Number of ways per set
		NUM_SETS  : natural := 128 --! Number of sets in the cache
	);
	port(
		clk   : in std_logic;
		reset : in std_logic;

		-- Control interface:
		cache_enable    : in std_logic;
		cache_flush     : in std_logic;
		cached_areas    : in std_logic_vector(31 downto 0);

		-- Memory interface:
		mem_address_in   : in  std_logic_vector(31 downto 0);
		mem_data_in      : in  std_logic_vector(31 downto 0);
		mem_data_out     : out std_logic_vector(31 downto 0);
		mem_data_size    : in  std_logic_vector( 1 downto 0);
		mem_read_req     : in  std_logic;
		mem_read_ack     : out std_logic;
		mem_write_req    : in  std_logic;
		mem_write_ack    : out std_logic;

		-- Wishbone interface:
		wb_inputs  : in wishbone_master_inputs;
		wb_outputs : out wishbone_master_outputs
	);
end entity pp_cache;

architecture behaviour of pp_cache is

	-- Input-related signals:
	signal input_address_set    : std_logic_vector(log2(NUM_SETS) - 1 downto 0);
	signal input_address_word   : std_logic_vector(log2(LINE_SIZE / 4) - 1 downto 0);
	signal input_address_tag    : std_logic_vector(31 - log2(NUM_SETS) - log2(LINE_SIZE / 4) downto 0);
	signal input_address_cached : boolean;

	-- Cache controller signals:
	type state_type is (IDLE, SINGLE_READ, SINGLE_WRITE);
	signal state : state_type := IDLE;

	-- Gets the amount to shift output data to the processor with for requests of size != 32 bits:
	function get_data_shift(size : in std_logic_vector(1 downto 0); address : in std_logic_vector)
		return natural is
	begin
		case size is
			when b"01" =>
				case address(1 downto 0) is
					when b"00" =>
						return 0;
					when b"01" =>
						return 8;
					when b"10" =>
						return 16;
					when b"11" =>
						return 24;
					when others =>
						return 0;
				end case;
			when b"10" =>
				if address(1) = '0' then
					return 0;
				else
					return 16;
				end if;
			when others =>
				return 0;
		end case;
	end function get_data_shift;

	-- Gets the value of the sel signals to the wishbone interconnect for the specified
	-- operand size and address.
	function get_data_sel(size : in std_logic_vector(1 downto 0); address : in std_logic_vector)
		return std_logic_vector is
	begin
		case size is
			when b"01" =>
				case address(1 downto 0) is
					when b"00" =>
						return b"0001";
					when b"01" =>
						return b"0010";
					when b"10" =>
						return b"0100";
					when b"11" =>
						return b"1000";
					when others =>
						return b"0001";
				end case;
			when b"10" =>
				if address(1) = '0' then
					return b"0011";
				else
					return b"1100";
				end if;
			when others =>
				return b"1111";
		end case;
	end function get_data_sel;

begin

	-- Decompose the input address:
	input_address_word <= mem_address_in(log2(LINE_SIZE / 4) - 1 downto 0);
	input_address_set <= mem_address_in(log2(NUM_SETS) + log2(LINE_SIZE / 4) - 1 downto log2(LINE_SIZE / 4));
	input_address_tag <= mem_address_in(31 downto log2(NUM_SETS) + log2(LINE_SIZE / 4));

	-- Check if the current input address should be/is in the cache:
	input_address_cached <= cached_areas(to_integer(unsigned(mem_address_in(31 downto 27)))) = '1';

	-- Acknowledge signals:
	mem_write_ack <= '1' when state = SINGLE_WRITE and wb_inputs.ack = '1' else '0'; 

	controller: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				state <= IDLE;
				wb_outputs.cyc <= '0';
				wb_outputs.stb <= '0';
				mem_read_ack <= '0';
			else
				case state is
					when IDLE =>
						mem_read_ack <= '0';

						--if input_address_cached and cache_enable = '1' then
						--	if mem_read_req = '1' then
						--	elsif mem_write_req = '1' then
						--	end if;
						--else
							if mem_read_req = '1' then		-- Do an uncached read
								wb_outputs.adr <= mem_address_in;
								wb_outputs.sel <= get_data_sel(mem_data_size, mem_address_in);
								wb_outputs.cyc <= '1';
								wb_outputs.stb <= '1';
								wb_outputs.we <= '0';
								state <= SINGLE_READ;
							elsif mem_write_req = '1' then	-- Do an uncached write
								wb_outputs.adr <= mem_address_in;
								wb_outputs.dat <= std_logic_vector(shift_left(unsigned(mem_data_in),
									get_data_shift(mem_data_size, mem_address_in)));
								wb_outputs.sel <= get_data_sel(mem_data_size, mem_address_in);
								wb_outputs.cyc <= '1';
								wb_outputs.stb <= '1';
								wb_outputs.we <= '1';
								state <= SINGLE_WRITE;
							end if;
						--end if;
					when SINGLE_READ =>
						if wb_inputs.ack = '1' then
							mem_data_out <= std_logic_vector(shift_right(unsigned(wb_inputs.dat),
								get_data_shift(mem_data_size, mem_address_in)));
							wb_outputs.cyc <= '0';
							wb_outputs.stb <= '0';
							mem_read_ack <= '1';
							state <= IDLE;
						end if;
					when SINGLE_WRITE =>
						if wb_inputs.ack = '1' then
							wb_outputs.cyc <= '0';
							wb_outputs.stb <= '0';
							wb_outputs.we <= '0';
							state <= IDLE;
						end if;
				end case;
			end if;
		end if;
	end process controller;

end architecture behaviour;
