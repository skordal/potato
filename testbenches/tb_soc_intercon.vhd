-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2016 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;

entity tb_soc_intercon is
end entity tb_soc_intercon;

architecture testbench of tb_soc_intercon is

	-- Clock signal:
	signal clk : std_logic := '0';
	constant clk_period : time := 10 ns;

	-- Reset signal:
	signal reset : std_logic := '1';

	-- IRQ signal:
	signal error_irq : std_logic;

	-- Wishbone interface:
	signal wb_adr_in  : std_logic_vector(11 downto 0) := (others => '0');
	signal wb_dat_in  : std_logic_vector(31 downto 0) := (others => '0');
	signal wb_dat_out : std_logic_vector(31 downto 0);
	signal wb_cyc_in  : std_logic := '0';
	signal wb_stb_in  : std_logic := '0';
	signal wb_we_in   : std_logic := '0';
	signal wb_ack_out : std_logic;

	-- Bus error interface:
	signal err_adr_in  : std_logic_vector(31 downto 0) := (others => '0');
	signal err_dat_in  : std_logic_vector(31 downto 0) := (others => '0');
	signal err_sel_in  : std_logic_vector( 3 downto 0) := (others => '0');
	signal err_cyc_in  : std_logic := '0';
	signal err_stb_in  : std_logic := '0';
	signal err_we_in   : std_logic := '0';
	signal err_ack_out : std_logic;

begin

	uut: entity work.pp_soc_intercon
		port map(
			clk => clk,
			reset => reset,
			error_irq => error_irq,
			wb_adr_in => wb_adr_in,
			wb_dat_in => wb_dat_in,
			wb_dat_out => wb_dat_out,
			wb_cyc_in => wb_cyc_in,
			wb_stb_in => wb_stb_in,
			wb_we_in => wb_we_in,
			wb_ack_out => wb_ack_out,
			err_adr_in => err_adr_in,
			err_dat_in => err_dat_in,
			err_sel_in => err_sel_in,
			err_cyc_in => err_cyc_in,
			err_stb_in => err_stb_in,
			err_we_in => err_we_in,
			err_ack_out => err_ack_out
		);

	clock: process
	begin
		clk <= '1';
		wait for clk_period / 2;
		clk <= '0';
		wait for clk_period / 2;
	end process clock;

	stimulus: process
	begin
		wait for clk_period * 2;
		reset <= '0';

		wait for clk_period;

		-- Do an invalid bus access to see what happens:
		err_cyc_in <= '1';
		err_stb_in <= '1';
		err_adr_in <= x"deadbeef";
		err_dat_in <= x"f000000d";
		err_we_in <= '1';
		wait until err_ack_out = '1';
		wait for clk_period;

		assert error_irq = '1';

		err_cyc_in <= '0';
		err_stb_in <= '0';
		wait for clk_period;

		-- Check the address:
		wb_adr_in <= x"00c";
		wb_we_in <= '0';
		wb_stb_in <= '1';
		wb_cyc_in <= '1';
		wait until wb_ack_out = '1';
		wait for clk_period;

		assert wb_dat_out = x"deadbeef";
		
		wb_stb_in <= '0';
		wb_cyc_in <= '0';
		wait for clk_period;

		-- Reset the interrupt:
		wb_adr_in <= x"000";
		wb_dat_in <= x"00000001";
		wb_we_in <= '1';
		wb_cyc_in <= '1';
		wb_stb_in <= '1';
		wait until wb_ack_out = '1';
		wait for clk_period;

		assert error_irq = '0';

		wb_stb_in <= '0';
		wb_cyc_in <= '0';

		wait;
	end process stimulus;

end architecture testbench;
