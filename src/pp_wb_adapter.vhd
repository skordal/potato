-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 - 2015 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! @brief Wishbone adapter, for connecting the processor to a Wishbone bus when not using caches.
entity pp_wb_adapter is
	port(
		clk   : in std_logic;
		reset : in std_logic;

		-- Processor instruction memory signals:
		signal imem_address  : in  std_logic_vector(31 downto 0);
		signal imem_data_out : out std_logic_vector(31 downto 0);
		signal imem_read_req : in  std_logic;
		signal imem_read_ack : out std_logic;
		
		-- Processor data memory signals:
		signal dmem_address   : in  std_logic_vector(31 downto 0);
		signal dmem_data_in   : in  std_logic_vector(31 downto 0); -- Data in to the bus
		signal dmem_data_out  : out std_logic_vector(31 downto 0); -- Data out to the bus
		signal dmem_data_size : in  std_logic_vector( 1 downto 0);
		signal dmem_read_req  : in  std_logic;
		signal dmem_read_ack  : out std_logic;
		signal dmem_write_req : in  std_logic;
		signal dmem_write_ack : out std_logic;

		-- Wishbone interface:
		wb_adr_out : out std_logic_vector(31 downto 0);
		wb_dat_out : out std_logic_vector(31 downto 0);
		wb_sel_out : out std_logic_vector( 3 downto 0);
		wb_cyc_out : out std_logic;
		wb_stb_out : out std_logic;
		wb_we_out  : out std_logic;
		wb_dat_in  : in  std_logic_vector(31 downto 0);
		wb_ack_in  : in  std_logic
	);
end entity pp_wb_adapter;

architecture behaviour of pp_wb_adapter is

	type states is (IDLE, READ_WAIT_ACK, WRITE_WAIT_ACK, IREAD_WAIT_ACK);
	signal state : states;

	signal dmem_r_ack : std_logic;

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

	imem_read_ack <= '1' when state = IREAD_WAIT_ACK and wb_ack_in = '1' else '0';
	imem_data_out <= wb_dat_in;

	dmem_write_ack <= '1' when state = WRITE_WAIT_ACK and wb_ack_in = '1' else '0';
	dmem_read_ack <= dmem_r_ack;

	wishbone: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				state <= IDLE;
				wb_cyc_out <= '0';
				wb_stb_out <= '0';
				dmem_r_ack <= '0';
			else
				case state is
					when IDLE =>
						dmem_r_ack <= '0';

						-- Prioritize requests from the data memory:
						if dmem_write_req = '1' then
							wb_adr_out <= dmem_address;
							wb_dat_out <= std_logic_vector(shift_left(unsigned(dmem_data_in),
								get_data_shift(dmem_data_size, dmem_address)));
							wb_sel_out <= get_data_sel(dmem_data_size, dmem_address);
							wb_cyc_out <= '1';
							wb_stb_out <= '1';
							wb_we_out <= '1';
							state <= WRITE_WAIT_ACK;
						elsif dmem_read_req = '1' and dmem_r_ack = '0' then
							wb_adr_out <= dmem_address;
							wb_sel_out <= get_data_sel(dmem_data_size, dmem_address);
							wb_cyc_out <= '1';
							wb_stb_out <= '1';
							wb_we_out <= '0';
							state <= READ_WAIT_ACK;
						elsif imem_read_req = '1' then
							wb_adr_out <= imem_address;
							wb_sel_out <= (others => '1');
							wb_cyc_out <= '1';
							wb_stb_out <= '1';
							wb_we_out <= '0';
							state <= IREAD_WAIT_ACK;
						end if;
					when READ_WAIT_ACK =>
						if wb_ack_in = '1' then
							dmem_data_out <= std_logic_vector(shift_right(unsigned(wb_dat_in),
								get_data_shift(dmem_data_size, dmem_address)));
							wb_cyc_out <= '0';
							wb_stb_out <= '0';
							dmem_r_ack <= '1';
							state <= IDLE;
						end if;
					when WRITE_WAIT_ACK | IREAD_WAIT_ACK =>
						if wb_ack_in = '1' then
							wb_cyc_out <= '0';
							wb_stb_out <= '0';
							wb_we_out <= '0';
							state <= IDLE;
						end if;
				end case;
			end if;
		end if;
	end process wishbone;

end architecture behaviour;
