-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 - 2016 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;

entity tb_soc_uart is
end entity tb_soc_uart;

architecture testbench of tb_soc_uart is

	-- Clock signal:
	signal clk : std_logic := '0';
	constant clk_period : time := 10 ns;

	-- Reset signal:
	signal reset : std_logic := '1';

	-- UART ports:
	signal txd : std_logic;
	signal rxd : std_logic := '1';

	-- interrupt signals:
	signal irq : std_logic;

	-- Wishbone ports:
	signal wb_adr_in  : std_logic_vector(11 downto 0) := (others => '0');
	signal wb_dat_in  : std_logic_vector( 7 downto 0) := (others => '0');
	signal wb_dat_out : std_logic_vector( 7 downto 0);
	signal wb_we_in   : std_logic := '0';
	signal wb_cyc_in  : std_logic := '0';
	signal wb_stb_in  : std_logic := '0';
	signal wb_ack_out : std_logic;

begin

	uut: entity work.pp_soc_uart
		port map(
			clk => clk,
			reset => reset,
			txd => txd,
			rxd => rxd,
			irq => irq,
			wb_adr_in => wb_adr_in,
			wb_dat_in => wb_dat_in,
			wb_dat_out => wb_dat_out,
			wb_we_in => wb_we_in,
			wb_cyc_in => wb_cyc_in,
			wb_stb_in => wb_stb_in,
			wb_ack_out => wb_ack_out
		);

	clock: process
	begin
		clk <= '1';
		wait for clk_period / 2;
		clk <= '0';
		wait for clk_period / 2;
	end process clock;

	stimulus: process

		procedure uart_write(address : in std_logic_vector(11 downto 0); data : in std_logic_vector(7 downto 0)) is
		begin
			wb_adr_in <= address;
			wb_dat_in <= data;
			wb_we_in <= '1';
			wb_cyc_in <= '1';
			wb_stb_in <= '1';

			wait until wb_ack_out = '1';
			wait for clk_period;
			wb_stb_in <= '0';
			wb_cyc_in <= '0';
			wait for clk_period;
		end procedure uart_write;

	begin
		wait for clk_period * 2;
		reset <= '0';

		-- Set the sample clock to obtain a 1 Mbps transfer rate:
		uart_write(x"00c", x"06");

		-- Enable the data received interrupt:
		uart_write(x"010", x"01");

		-- Send a byte on the UART:
		rxd <= '0'; -- Start bit
		wait for 1 us;
		rxd <= '0';
		wait for 1 us;
		rxd <= '1';
		wait for 1 us;
		rxd <= '0';
		wait for 1 us;
		rxd <= '1';
		wait for 1 us;
		rxd <= '0';
		wait for 1 us;
		rxd <= '0';
		wait for 1 us;
		rxd <= '0';
		wait for 1 us;
		rxd <= '0';
		wait for 1 us;
		rxd <= '1'; -- Stop bit
		wait for 1 us;

		wait until irq = '1';

		-- Disable the IRQ:
		uart_write(x"010", x"00");
		wait until irq = '0';

		-- Output a "Potato" on the UART:
		uart_write(x"000", x"50");
		uart_write(x"000", x"6f");
		uart_write(x"000", x"74");
		uart_write(x"000", x"61");
		uart_write(x"000", x"74");
		uart_write(x"000", x"6f");

		wait;
	end process stimulus;

end architecture testbench;
