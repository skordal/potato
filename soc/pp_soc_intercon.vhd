-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2016 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! @brief Module for registering and retrieving information about bus errors.
--!
--! The following registers are available:
--! |---------|------------------------------------------|
--! | Address | Description                              |
--! |---------|------------------------------------------|
--! | 0x00    | Status/control register                  |
--! | 0x04    | Read error address                       |
--! | 0x08    | Read error mask (SEL-bits for transfer)  |
--! | 0x0c    | Write error address                      |
--! | 0x10    | Write error mask (SEL-bits for transfer) |
--! | 0x14    | Write error data                         |
--! |---------|------------------------------------------|
--!
--! The bits in the status/control register have the following
--! meanings:
--! - Bit 0: IRQ status (read) / IRQ reset (write)
--! - Bit 1: Read error (read-only) - the previous erroneous access was a read access
--! - Bit 2: Write error (read-only) - the previous erroneous access was a write access
--!
--! Invalid bus accesses are registered using a dedicated Wishbone interface; the SoC
--! interconnect has to make sure that erroneous accesses are routed to this interface in
--! order for the details to be registered.
entity pp_soc_intercon is
	port(
		clk   : in std_logic;
		reset : in std_logic;

		-- Bus error interrupt:
		error_irq : out std_logic;

		-- Wishbone interface:
		wb_adr_in  : in  std_logic_vector(11 downto 0);
		wb_dat_in  : in  std_logic_vector(31 downto 0);
		wb_dat_out : out std_logic_vector(31 downto 0);
		wb_cyc_in  : in  std_logic;
		wb_stb_in  : in  std_logic;
		wb_we_in   : in  std_logic;
		wb_ack_out : out std_logic;

		-- Interface for registering bus errors:
		err_adr_in  : in  std_logic_vector(31 downto 0);
		err_dat_in  : in  std_logic_vector(31 downto 0);
		err_sel_in  : in  std_logic_vector( 3 downto 0);
		err_cyc_in  : in  std_logic;
		err_stb_in  : in  std_logic;
		err_we_in   : in  std_logic;
		err_ack_out : out std_logic
	);
end entity pp_soc_intercon;

architecture behaviour of pp_soc_intercon is

	-- Previous erroneous bus access:
	type error_access_type is (ACCESS_READ, ACCESS_WRITE, ACCESS_NONE);
	signal prev_error_access : error_access_type;

	-- Read error details:
	signal read_error_address : std_logic_vector(31 downto 0);
	signal read_error_sel     : std_logic_vector( 3 downto 0);

	-- Write error details:
	signal write_error_address : std_logic_vector(31 downto 0);
	signal write_error_sel     : std_logic_vector( 3 downto 0);
	signal write_error_data    : std_logic_vector(31 downto 0);

	signal irq_reset : std_logic := '0';
	signal ack : std_logic;
	signal error_ack : std_logic;

begin
	wb_ack_out <= ack and wb_cyc_in and wb_stb_in;
	err_ack_out <= error_ack and err_cyc_in and err_stb_in;

	error_irq <= '1' when prev_error_access /= ACCESS_NONE else '0';

	wishbone: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				wb_dat_out <= (others => '0');
				ack <= '0';
				irq_reset <= '0';
			else
				if irq_reset = '1' then
					irq_reset <= '0';
				end if;

				if wb_cyc_in = '1' and wb_stb_in = '1' and ack = '0' then
					if wb_we_in = '1' then -- Write
						case wb_adr_in is
							when x"000" => -- Status/control register
								if wb_dat_in(0) = '1' then
									irq_reset <= '1';
								end if;
							when others =>
								-- Ignore invalid writes
						end case;
						ack <= '1';
					else -- Read
						case wb_adr_in is
							when x"000" =>
								wb_dat_out(31 downto 3) <= (others => '0');
								case prev_error_access is
									when ACCESS_READ =>
										wb_dat_out(2 downto 1) <= b"01";
									when ACCESS_WRITE =>
										wb_dat_out(2 downto 1) <= b"10";
									when ACCESS_NONE =>
										wb_dat_out(2 downto 1) <= b"00";
								end case;

								if prev_error_access /= ACCESS_NONE then
									wb_dat_out(0) <= '1';
								else
									wb_dat_out(0) <= '0';
								end if;
							when x"004" =>
								wb_dat_out <= read_error_address;
							when x"008" =>
								wb_dat_out <= std_logic_vector(resize(unsigned(read_error_sel), wb_dat_out'length));
							when x"00c" =>
								wb_dat_out <= write_error_address;
							when x"010" =>
								wb_dat_out <= std_logic_vector(resize(unsigned(write_error_sel), wb_dat_out'length));
							when x"014" =>
								wb_dat_out <= write_error_data;
							when others =>
								wb_dat_out <= (others => '0');
						end case;
						ack <= '1';
					end if;
				elsif wb_stb_in = '0' then
					ack <= '0';
				end if;
			end if;
		end if;
	end process wishbone;
	
	error_if: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				error_ack <= '0';

				prev_error_access <= ACCESS_NONE;
				read_error_address <= (others => '0');
				read_error_sel <= (others => '0');
				write_error_address <= (others => '0');
				write_error_sel <= (others => '0');
				write_error_data <= (others => '0');
			elsif irq_reset = '1' then
				prev_error_access <= ACCESS_NONE;
			else
				if err_cyc_in = '1' and err_stb_in = '1' and error_ack = '0' then
					if err_we_in = '1' then -- Write
						prev_error_access <= ACCESS_WRITE;
						write_error_address <= err_adr_in;
						write_error_sel <= err_sel_in;
						write_error_data <= err_dat_in;
					else -- Read
						prev_error_access <= ACCESS_READ;
						read_error_address <= err_adr_in;
						read_error_sel <= err_sel_in;
					end if;
					error_ack <= '1';
				elsif wb_stb_in = '0' then
					error_ack <= '0';
				end if;
			end if;
		end if;
	end process error_if;

end architecture behaviour;
