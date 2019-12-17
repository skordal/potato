-- The Potato Processor - SoC design for the Arty FPGA board
-- (c) Kristian Klomsten Skordal 2016 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;

-- This is a SoC design for the Arty development board. It has the following memory layout:
--
-- 0x00000000: Main memory (128 kB)
-- 0xc0000000: Timer0
-- 0xc0001000: Timer1
-- 0xc0002000: UART0 (for host communication)
-- 0xc0003000: UART1 (for connecting a GPS PMOD to JA)
-- 0xc0004000: GPIO0
-- 0xc0005000: Interconnect control/error module
-- 0xffff8000: Application execution environment ROM (16 kB)
-- 0xffffc000: Application execution environment RAM (16 kB)
entity toplevel is
	port(
		clk     : in  std_logic;
		reset_n : in  std_logic;

		-- GPIOs:
		-- 4x LEDs        (bits 11 downto 8)
		-- 4x Switches    (bits  7 downto 4)
		-- 4x Buttons     (bits  3 downto 0)
		gpio_pins : inout std_logic_vector(11 downto 0);

		-- UART0 signals:
		uart0_txd : out std_logic;
		uart0_rxd : in  std_logic;

		-- UART1 signals:
		uart1_txd : out std_logic;
		uart1_rxd : in  std_logic
	);
end entity toplevel;

architecture behaviour of toplevel is

	-- Reset signals:
	signal reset : std_logic;

	-- Internal clock signals:
	signal system_clk : std_logic;
	signal system_clk_locked : std_logic;

	-- Interrupt indices:
	constant IRQ_TIMER0_INDEX    : natural := 0;
	constant IRQ_TIMER1_INDEX    : natural := 1;
	constant IRQ_UART0_INDEX     : natural := 2;
	constant IRQ_UART1_INDEX     : natural := 3;
	constant IRQ_BUS_ERROR_INDEX : natural := 4;

	-- Interrupt signals:
	signal irq_array : std_logic_vector(7 downto 0);
	signal timer0_irq, timer1_irq : std_logic;
	signal uart0_irq, uart1_irq   : std_logic;
	signal intercon_irq_bus_error : std_logic;

	-- Processor signals:
	signal processor_adr_out : std_logic_vector(31 downto 0);
	signal processor_sel_out : std_logic_vector(3 downto 0);
	signal processor_cyc_out : std_logic;
	signal processor_stb_out : std_logic;
	signal processor_we_out  : std_logic;
	signal processor_dat_out : std_logic_vector(31 downto 0);
	signal processor_dat_in  : std_logic_vector(31 downto 0);
	signal processor_ack_in  : std_logic;

	-- Timer0 signals:
	signal timer0_adr_in : std_logic_vector(11 downto 0);
	signal timer0_dat_in : std_logic_vector(31 downto 0);
	signal timer0_dat_out : std_logic_vector(31 downto 0);
	signal timer0_cyc_in : std_logic;
	signal timer0_stb_in : std_logic;
	signal timer0_we_in : std_logic;
	signal timer0_ack_out : std_logic;

	-- Timer1 signals:
	signal timer1_adr_in : std_logic_vector(11 downto 0);
	signal timer1_dat_in : std_logic_vector(31 downto 0);
	signal timer1_dat_out : std_logic_vector(31 downto 0);
	signal timer1_cyc_in : std_logic;
	signal timer1_stb_in : std_logic;
	signal timer1_we_in : std_logic;
	signal timer1_ack_out : std_logic;

	-- UART0 signals:
	signal uart0_adr_in  : std_logic_vector(11 downto 0);
	signal uart0_dat_in  : std_logic_vector( 7 downto 0);
	signal uart0_dat_out : std_logic_vector( 7 downto 0);
	signal uart0_cyc_in  : std_logic;
	signal uart0_stb_in  : std_logic;
	signal uart0_we_in   : std_logic;
	signal uart0_ack_out : std_logic;

	-- UART1 signals:
	signal uart1_adr_in  : std_logic_vector(11 downto 0);
	signal uart1_dat_in  : std_logic_vector( 7 downto 0);
	signal uart1_dat_out : std_logic_vector( 7 downto 0);
	signal uart1_cyc_in  : std_logic;
	signal uart1_stb_in  : std_logic;
	signal uart1_we_in   : std_logic;
	signal uart1_ack_out : std_logic;

	-- GPIO signals:
	signal gpio_adr_in  : std_logic_vector(11 downto 0);
	signal gpio_dat_in  : std_logic_vector(31 downto 0);
	signal gpio_dat_out : std_logic_vector(31 downto 0);
	signal gpio_cyc_in  : std_logic;
	signal gpio_stb_in  : std_logic;
	signal gpio_we_in   : std_logic;
	signal gpio_ack_out : std_logic;

	-- Interconnect control module:
	signal intercon_adr_in  : std_logic_vector(11 downto 0);
	signal intercon_dat_in  : std_logic_vector(31 downto 0);
	signal intercon_dat_out : std_logic_vector(31 downto 0);
	signal intercon_cyc_in  : std_logic;
	signal intercon_stb_in  : std_logic;
	signal intercon_we_in   : std_logic;
	signal intercon_ack_out : std_logic;

	-- Interconnect error module:
	signal error_adr_in  : std_logic_vector(31 downto 0);
	signal error_dat_in  : std_logic_vector(31 downto 0);
	signal error_dat_out : std_logic_vector(31 downto 0);
	signal error_sel_in  : std_logic_vector( 3 downto 0);
	signal error_cyc_in  : std_logic;
	signal error_stb_in  : std_logic;
	signal error_we_in   : std_logic;
	signal error_ack_out : std_logic;

	-- AEE ROM signals:
	signal aee_rom_adr_in  : std_logic_vector(13 downto 0);
	signal aee_rom_dat_out : std_logic_vector(31 downto 0);
	signal aee_rom_cyc_in  : std_logic;
	signal aee_rom_stb_in  : std_logic;
	signal aee_rom_sel_in  : std_logic_vector(3 downto 0);
	signal aee_rom_ack_out : std_logic;

	-- AEE RAM signals:
	signal aee_ram_adr_in  : std_logic_vector(13 downto 0);
	signal aee_ram_dat_in  : std_logic_vector(31 downto 0);
	signal aee_ram_dat_out : std_logic_vector(31 downto 0);
	signal aee_ram_cyc_in  : std_logic;
	signal aee_ram_stb_in  : std_logic;
	signal aee_ram_sel_in  : std_logic_vector(3 downto 0);
	signal aee_ram_we_in   : std_logic;
	signal aee_ram_ack_out : std_logic;

	-- Main memory signals:
	signal main_memory_adr_in  : std_logic_vector(16 downto 0);
	signal main_memory_dat_in  : std_logic_vector(31 downto 0);
	signal main_memory_dat_out : std_logic_vector(31 downto 0);
	signal main_memory_cyc_in  : std_logic;
	signal main_memory_stb_in  : std_logic;
	signal main_memory_sel_in  : std_logic_vector(3 downto 0);
	signal main_memory_we_in   : std_logic;
	signal main_memory_ack_out : std_logic;

	-- Selected peripheral on the interconnect:
	type intercon_peripheral_type is (
		PERIPHERAL_TIMER0, PERIPHERAL_TIMER1,
		PERIPHERAL_UART0, PERIPHERAL_UART1, PERIPHERAL_GPIO,
		PERIPHERAL_AEE_ROM, PERIPHERAL_AEE_RAM, PERIPHERAL_INTERCON,
		PERIPHERAL_MAIN_MEMORY, PERIPHERAL_ERROR, PERIPHERAL_NONE);
	signal intercon_peripheral : intercon_peripheral_type := PERIPHERAL_NONE;

	-- Interconnect address decoder state:
	signal intercon_busy : boolean := false;

begin

	irq_array <= (
			IRQ_TIMER0_INDEX => timer0_irq,
			IRQ_TIMER1_INDEX => timer1_irq,
			IRQ_UART0_INDEX => uart0_irq,
			IRQ_UART1_INDEX => uart1_irq,
			IRQ_BUS_ERROR_INDEX => intercon_irq_bus_error,
			others => '0'
		);

	address_decoder: process(system_clk)
	begin
		if rising_edge(system_clk) then
			if reset = '1' then
				intercon_peripheral <= PERIPHERAL_NONE;
				intercon_busy <= false;
			else
				if not intercon_busy then
					if processor_cyc_out = '1' then
						intercon_busy <= true;

						if processor_adr_out(31 downto 16) = x"0000"
							or processor_adr_out(31 downto 16) = x"0001" then -- Main memory space
								intercon_peripheral <= PERIPHERAL_MAIN_MEMORY;
						elsif processor_adr_out(31 downto 16) = x"c000" then -- Peripheral memory space
							case processor_adr_out(15 downto 12) is
								when x"0" =>
									intercon_peripheral <= PERIPHERAL_TIMER0;
								when x"1" =>
									intercon_peripheral <= PERIPHERAL_TIMER1;
								when x"2" =>
									intercon_peripheral <= PERIPHERAL_UART0;
								when x"3" =>
									intercon_peripheral <= PERIPHERAL_UART1;
								when x"4" =>
									intercon_peripheral <= PERIPHERAL_GPIO;
								when x"5" =>
									intercon_peripheral <= PERIPHERAL_INTERCON;
								when others => -- Invalid address - delegated to the error peripheral
									intercon_peripheral <= PERIPHERAL_ERROR;
							end case;
						elsif processor_adr_out(31 downto 16) = x"ffff" then -- Firmware memory space
							if processor_adr_out(15 downto 14) = b"10" then    -- AEE ROM
								intercon_peripheral <= PERIPHERAL_AEE_ROM;
							elsif processor_adr_out(15 downto 14) = b"11" then -- AEE RAM
								intercon_peripheral <= PERIPHERAL_AEE_RAM;
							end if;
						else
							intercon_peripheral <= PERIPHERAL_ERROR;
						end if;
					else
						intercon_peripheral <= PERIPHERAL_NONE;
					end if;
				else
					if processor_cyc_out = '0' then
						intercon_busy <= false;
						intercon_peripheral <= PERIPHERAL_NONE;
					end if;
				end if;
			end if;
		end if;
	end process address_decoder;

	processor_intercon: process(intercon_peripheral,
		timer0_ack_out, timer0_dat_out, timer1_ack_out, timer1_dat_out,
		uart0_ack_out, uart0_dat_out, uart1_ack_out, uart1_dat_out,
		gpio_ack_out, gpio_dat_out,
		intercon_ack_out, intercon_dat_out, error_ack_out,
		aee_rom_ack_out, aee_rom_dat_out, aee_ram_ack_out, aee_ram_dat_out,
		main_memory_ack_out, main_memory_dat_out)
	begin
		case intercon_peripheral is
			when PERIPHERAL_TIMER0 =>
				processor_ack_in <= timer0_ack_out;
				processor_dat_in <= timer0_dat_out;
			when PERIPHERAL_TIMER1 =>
				processor_ack_in <= timer1_ack_out;
				processor_dat_in <= timer1_dat_out;
			when PERIPHERAL_UART0 =>
				processor_ack_in <= uart0_ack_out;
				processor_dat_in <= x"000000" & uart0_dat_out;
			when PERIPHERAL_UART1 =>
				processor_ack_in <= uart1_ack_out;
				processor_dat_in <= x"000000" & uart1_dat_out;
			when PERIPHERAL_GPIO =>
				processor_ack_in <= gpio_ack_out;
				processor_dat_in <= gpio_dat_out;
			when PERIPHERAL_INTERCON =>
				processor_ack_in <= intercon_ack_out;
				processor_dat_in <= intercon_dat_out;
			when PERIPHERAL_AEE_ROM =>
				processor_ack_in <= aee_rom_ack_out;
				processor_dat_in <= aee_rom_dat_out;
			when PERIPHERAL_AEE_RAM =>
				processor_ack_in <= aee_ram_ack_out;
				processor_dat_in <= aee_ram_dat_out;
			when PERIPHERAL_ERROR =>
				processor_ack_in <= error_ack_out;
				processor_dat_in <= (others => '0');
			when PERIPHERAL_MAIN_MEMORY =>
				processor_ack_in <= main_memory_ack_out;
				processor_dat_in <= main_memory_dat_out;
			when PERIPHERAL_NONE =>
				processor_ack_in <= '0';
				processor_dat_in <= (others => '0');
		end case;
	end process processor_intercon;

	reset_controller: entity work.pp_soc_reset
		port map(
			clk => clk,
			reset_n => reset_n,
			reset_out => reset,
			system_clk => system_clk,
			system_clk_locked => system_clk_locked
		);

	clkgen: entity work.clock_generator
		port map(
			clk => clk,
			resetn => reset_n,
			system_clk => system_clk,
			locked => system_clk_locked
		);

	processor: entity work.pp_potato
		generic map(
			RESET_ADDRESS => x"ffff8000",
			ICACHE_ENABLE => false
		) port map(
			clk => system_clk,
			reset => reset,
			irq => irq_array,
			test_context_out => open,
			wb_adr_out => processor_adr_out,
			wb_dat_out => processor_dat_out,
			wb_dat_in => processor_dat_in,
			wb_sel_out => processor_sel_out,
			wb_cyc_out => processor_cyc_out,
			wb_stb_out => processor_stb_out,
			wb_we_out => processor_we_out,
			wb_ack_in => processor_ack_in
		);

	timer0: entity work.pp_soc_timer
		port map(
			clk => system_clk,
			reset => reset,
			irq => timer0_irq,
			wb_adr_in => timer0_adr_in,
			wb_dat_in => timer0_dat_in,
			wb_dat_out => timer0_dat_out,
			wb_cyc_in => timer0_cyc_in,
			wb_stb_in => timer0_stb_in,
			wb_we_in => timer0_we_in,
			wb_ack_out => timer0_ack_out
		);
	timer0_adr_in <= processor_adr_out(timer0_adr_in'range);
	timer0_dat_in <= processor_dat_out;
	timer0_we_in <= processor_we_out;
	timer0_cyc_in <= processor_cyc_out when intercon_peripheral = PERIPHERAL_TIMER0 else '0';
	timer0_stb_in <= processor_stb_out when intercon_peripheral = PERIPHERAL_TIMER0 else '0';

	timer1: entity work.pp_soc_timer
		port map(
			clk => system_clk,
			reset => reset,
			irq => timer1_irq,
			wb_adr_in => timer1_adr_in,
			wb_dat_in => timer1_dat_in,
			wb_dat_out => timer1_dat_out,
			wb_cyc_in => timer1_cyc_in,
			wb_stb_in => timer1_stb_in,
			wb_we_in => timer1_we_in,
			wb_ack_out => timer1_ack_out
		);
	timer1_adr_in <= processor_adr_out(timer1_adr_in'range);
	timer1_dat_in <= processor_dat_out;
	timer1_we_in  <= processor_we_out;
	timer1_cyc_in <= processor_cyc_out when intercon_peripheral = PERIPHERAL_TIMER1 else '0';
	timer1_stb_in <= processor_stb_out when intercon_peripheral = PERIPHERAL_TIMER1 else '0';

	gpio: entity work.pp_soc_gpio
		generic map(
			NUM_GPIOS => gpio_pins'high + 1
		) port map(
			clk => system_clk,
			reset => reset,
			gpio => gpio_pins,
			wb_adr_in => gpio_adr_in,
			wb_dat_in => gpio_dat_in,
			wb_dat_out => gpio_dat_out,
			wb_cyc_in => gpio_cyc_in,
			wb_stb_in => gpio_stb_in,
			wb_we_in => gpio_we_in,
			wb_ack_out => gpio_ack_out
		);
	gpio_adr_in <= processor_adr_out(gpio_adr_in'range);
	gpio_dat_in <= processor_dat_out;
	gpio_we_in  <= processor_we_out;
	gpio_cyc_in <= processor_cyc_out when intercon_peripheral = PERIPHERAL_GPIO else '0';
	gpio_stb_in <= processor_stb_out when intercon_peripheral = PERIPHERAL_GPIO else '0';

	uart0: entity work.pp_soc_uart
		generic map(
			FIFO_DEPTH => 32
		) port map(
			clk => system_clk,
			reset => reset,
			txd => uart0_txd,
			rxd => uart0_rxd,
			irq => uart0_irq,
			wb_adr_in => uart0_adr_in,
			wb_dat_in => uart0_dat_in,
			wb_dat_out => uart0_dat_out,
			wb_cyc_in => uart0_cyc_in,
			wb_stb_in => uart0_stb_in,
			wb_we_in => uart0_we_in,
			wb_ack_out => uart0_ack_out
		);
	uart0_adr_in <= processor_adr_out(uart0_adr_in'range);
	uart0_dat_in <= processor_dat_out(7 downto 0);
	uart0_we_in  <= processor_we_out;
	uart0_cyc_in <= processor_cyc_out when intercon_peripheral = PERIPHERAL_UART0 else '0';
	uart0_stb_in <= processor_stb_out when intercon_peripheral = PERIPHERAL_UART0 else '0';

	uart1: entity work.pp_soc_uart
		generic map(
			FIFO_DEPTH => 32
		) port map(
			clk => system_clk,
			reset => reset,
			txd => uart1_txd,
			rxd => uart1_rxd,
			irq => uart1_irq,
			wb_adr_in => uart1_adr_in,
			wb_dat_in => uart1_dat_in,
			wb_dat_out => uart1_dat_out,
			wb_cyc_in => uart1_cyc_in,
			wb_stb_in => uart1_stb_in,
			wb_we_in => uart1_we_in,
			wb_ack_out => uart1_ack_out
		);
	uart1_adr_in <= processor_adr_out(uart1_adr_in'range);
	uart1_dat_in <= processor_dat_out(7 downto 0);
	uart1_we_in  <= processor_we_out;
	uart1_cyc_in <= processor_cyc_out when intercon_peripheral = PERIPHERAL_UART1 else '0';
	uart1_stb_in <= processor_stb_out when intercon_peripheral = PERIPHERAL_UART1 else '0';

	intercon_error: entity work.pp_soc_intercon
		port map(
			clk => system_clk,
			reset => reset,
			error_irq => intercon_irq_bus_error,
			wb_adr_in => intercon_adr_in,
			wb_dat_in => intercon_dat_in,
			wb_dat_out => intercon_dat_out,
			wb_cyc_in => intercon_cyc_in,
			wb_stb_in => intercon_stb_in,
			wb_we_in => intercon_we_in,
			wb_ack_out => intercon_ack_out,
			err_adr_in => error_adr_in,
			err_dat_in => error_dat_in,
			err_sel_in => error_sel_in,
			err_cyc_in => error_cyc_in,
			err_stb_in => error_stb_in,
			err_we_in => error_we_in,
			err_ack_out => error_ack_out
		);
	intercon_adr_in <= processor_adr_out(intercon_adr_in'range);
	intercon_dat_in <= processor_dat_out;
	intercon_we_in  <= processor_we_out;
	intercon_cyc_in <= processor_cyc_out when intercon_peripheral = PERIPHERAL_INTERCON else '0';
	intercon_stb_in <= processor_stb_out when intercon_peripheral = PERIPHERAL_INTERCON else '0';
	error_adr_in <= processor_adr_out;
	error_dat_in <= processor_dat_out;
	error_sel_in <= processor_sel_out;
	error_we_in  <= processor_we_out;
	error_cyc_in <= processor_cyc_out when intercon_peripheral = PERIPHERAL_ERROR else '0';
	error_stb_in <= processor_stb_out when intercon_peripheral = PERIPHERAL_ERROR else '0';

	aee_rom: entity work.aee_rom_wrapper
		generic map(
			MEMORY_SIZE => 16384
		) port map(
			clk => system_clk,
			reset => reset,
			wb_adr_in => aee_rom_adr_in,
			wb_dat_out => aee_rom_dat_out,
			wb_cyc_in => aee_rom_cyc_in,
			wb_stb_in => aee_rom_stb_in,
			wb_sel_in => aee_rom_sel_in,
			wb_ack_out => aee_rom_ack_out
		);
	aee_rom_adr_in <= processor_adr_out(aee_rom_adr_in'range);
	aee_rom_cyc_in <= processor_cyc_out when intercon_peripheral = PERIPHERAL_AEE_ROM else '0';
	aee_rom_stb_in <= processor_stb_out when intercon_peripheral = PERIPHERAL_AEE_ROM else '0';
	aee_rom_sel_in <= processor_sel_out;

	aee_ram: entity work.pp_soc_memory
		generic map(
			MEMORY_SIZE => 16384
		) port map(
			clk => system_clk,
			reset => reset,
			wb_adr_in => aee_ram_adr_in,
			wb_dat_in => aee_ram_dat_in,
			wb_dat_out => aee_ram_dat_out,
			wb_cyc_in => aee_ram_cyc_in,
			wb_stb_in => aee_ram_stb_in,
			wb_sel_in => aee_ram_sel_in,
			wb_we_in => aee_ram_we_in,
			wb_ack_out => aee_ram_ack_out
		);
	aee_ram_adr_in <= processor_adr_out(aee_ram_adr_in'range);
	aee_ram_dat_in <= processor_dat_out;
	aee_ram_we_in  <= processor_we_out;
	aee_ram_sel_in <= processor_sel_out;
	aee_ram_cyc_in <= processor_cyc_out when intercon_peripheral = PERIPHERAL_AEE_RAM else '0';
	aee_ram_stb_in <= processor_stb_out when intercon_peripheral = PERIPHERAL_AEE_RAM else '0';

	main_memory: entity work.pp_soc_memory
		generic map(
			MEMORY_SIZE => 131072
		) port map(
			clk => system_clk,
			reset => reset,
			wb_adr_in => main_memory_adr_in,
			wb_dat_in => main_memory_dat_in,
			wb_dat_out => main_memory_dat_out,
			wb_cyc_in => main_memory_cyc_in,
			wb_stb_in => main_memory_stb_in,
			wb_sel_in => main_memory_sel_in,
			wb_we_in => main_memory_we_in,
			wb_ack_out => main_memory_ack_out
		);
	main_memory_adr_in <= processor_adr_out(main_memory_adr_in'range);
	main_memory_dat_in <= processor_dat_out;
	main_memory_we_in  <= processor_we_out;
	main_memory_sel_in <= processor_sel_out;
	main_memory_cyc_in <= processor_cyc_out when intercon_peripheral = PERIPHERAL_MAIN_MEMORY else '0';
	main_memory_stb_in <= processor_stb_out when intercon_peripheral = PERIPHERAL_MAIN_MEMORY else '0';

end architecture behaviour;
