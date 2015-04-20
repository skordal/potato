-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 - 2015 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <http://opencores.org/project,potato,bugtracker>

library ieee;
use ieee.std_logic_1164.all;

--! @brief The Potato Processor.
--! This file provides a Wishbone-compatible interface to the Potato processor.
entity pp_potato is
	generic(
		PROCESSOR_ID           : std_logic_vector(31 downto 0) := x"00000000"; --! Processor ID.
		RESET_ADDRESS          : std_logic_vector(31 downto 0) := x"00000000"  --! Address of the first instruction to execute.
	);
	port(
		clk   : in std_logic;
		reset : in std_logic;

		-- Interrupts:
		irq : in std_logic_vector(7 downto 0);

		-- Host/Target interface:
		fromhost_data    : in std_logic_vector(31 downto 0);
		fromhost_updated : in std_logic;
		tohost_data      : out std_logic_vector(31 downto 0);
		tohost_updated   : out std_logic;

		-- Wishbone interface:
		wb_adr_out : out std_logic_vector(31 downto 0);
		wb_sel_out : out std_logic_vector( 3 downto 0);
		wb_cyc_out : out std_logic;
		wb_stb_out : out std_logic;
		wb_we_out  : out std_logic;
		wb_dat_out : out std_logic_vector(31 downto 0);
		wb_dat_in  : in  std_logic_vector(31 downto 0);
		wb_ack_in  : in  std_logic
	);
end entity pp_potato;

architecture behaviour of pp_potato is

	-- Instruction memory signals:
	signal imem_address : std_logic_vector(31 downto 0);
	signal imem_data    : std_logic_vector(31 downto 0);
	signal imem_req, imem_ack : std_logic;

	-- Data memory signals:
	signal dmem_address   : std_logic_vector(31 downto 0);
	signal dmem_data_in   : std_logic_vector(31 downto 0);
	signal dmem_data_out  : std_logic_vector(31 downto 0);
	signal dmem_data_size : std_logic_vector( 1 downto 0);
	signal dmem_read_req  : std_logic;
	signal dmem_read_ack  : std_logic;
	signal dmem_write_req : std_logic;
	signal dmem_write_ack : std_logic;

begin
	processor: entity work.pp_core
		generic map(
			PROCESSOR_ID => PROCESSOR_ID,
			RESET_ADDRESS => RESET_ADDRESS
		) port map(
			clk => clk,
			reset => reset,
			timer_clk => clk,
			imem_address => imem_address,
			imem_data_in => imem_data,
			imem_req => imem_req,
			imem_ack => imem_ack,
			dmem_address => dmem_address,
			dmem_data_in => dmem_data_in,
			dmem_data_out => dmem_data_out,
			dmem_data_size => dmem_data_size,
			dmem_read_req => dmem_read_req,
			dmem_read_ack => dmem_read_ack,
			dmem_write_req => dmem_write_req,
			dmem_write_ack => dmem_write_ack,
			fromhost_data => fromhost_data,
			fromhost_write_en => fromhost_updated,
			tohost_data => tohost_data,
			tohost_write_en => tohost_updated,
			irq => irq
		);

	wb_if: entity work.pp_wb_adapter
		port map(
			clk => clk,
			reset => reset,
			imem_address => imem_address,
			imem_data_out => imem_data,
			imem_read_req => imem_req,
			imem_read_ack => imem_ack,
			dmem_address => dmem_address,
			dmem_data_in => dmem_data_out,
			dmem_data_out => dmem_data_in,
			dmem_data_size => dmem_data_size,
			dmem_read_req => dmem_read_req,
			dmem_write_req => dmem_write_req,
			dmem_read_ack => dmem_read_ack,
			dmem_write_ack => dmem_write_ack,
			wb_adr_out => wb_adr_out,
			wb_sel_out => wb_sel_out,
			wb_cyc_out => wb_cyc_out,
			wb_stb_out => wb_stb_out,
			wb_we_out => wb_we_out,
			wb_dat_out => wb_dat_out,
			wb_dat_in => wb_dat_in,
			wb_ack_in => wb_ack_in
		);

end architecture behaviour;
