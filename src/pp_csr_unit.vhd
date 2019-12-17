-- The Potato Processor - A simple processor for FPGAs
-- (c) Kristian Klomsten Skordal 2014 - 2015 <kristian.skordal@wafflemail.net>
-- Report bugs and issues on <https://github.com/skordal/potato/issues>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pp_types.all;
use work.pp_csr.all;
use work.pp_utilities.all;

--! @brief Control and status unit.
entity pp_csr_unit is
	generic(
		PROCESSOR_ID  : std_logic_vector(31 downto 0);
		MTIME_DIVIDER : positive := 5; --! Divider for the clock driving the MTIME counter.
		TIME_DIVIDER  : positive := 5  --! Divider for the clock driving the TIME counter.
	);
	port(
		clk       : in std_logic;
		reset     : in std_logic;

		-- IRQ signals:
		irq : in std_logic_vector(7 downto 0);

		-- Count retired instruction:
		count_instruction : in std_logic;

		-- Test interface:
		test_context_out : out test_context;

		-- Read port:
		read_address   : in csr_address;
		read_data_out  : out std_logic_vector(31 downto 0);

		-- Write port:
		write_address : in csr_address;
		write_data_in : in std_logic_vector(31 downto 0);
		write_mode    : in csr_write_mode;

		-- Exception context write port:
		exception_context       : in csr_exception_context;
		exception_context_write : in std_logic;

		-- Interrupts originating from this unit:
		software_interrupt_out : out std_logic;
		timer_interrupt_out    : out std_logic;

		-- Registers needed for exception handling, always read:
		mie_out         : out std_logic_vector(31 downto 0);
		mtvec_out       : out std_logic_vector(31 downto 0);
		ie_out, ie1_out : out std_logic
	);
end entity pp_csr_unit;

architecture behaviour of pp_csr_unit is

	-- Timer clock:
	signal time_clk         : std_logic;
	signal time_clk_counter : natural := 0;

	-- Counters:
	signal counter_time    : std_logic_vector(63 downto 0);
	signal counter_cycle   : std_logic_vector(63 downto 0);
	signal counter_instret : std_logic_vector(63 downto 0);

	-- Machine time counter:
	signal mtime_clock_counter : natural := 0;
	signal counter_mtime       : std_logic_vector(31 downto 0);
	signal mtime_compare       : std_logic_vector(31 downto 0);

	-- Machine-mode registers:
	signal mcause   : csr_exception_cause;
	signal mbadaddr : std_logic_vector(31 downto 0);
	signal mscratch : std_logic_vector(31 downto 0);
	signal mepc     : std_logic_vector(31 downto 0);
	signal mtvec    : std_logic_vector(31 downto 2) := (others => '0');
	signal mie      : std_logic_vector(31 downto 0) := (others => '0');

	-- Interrupt enable bits:
	signal ie, ie1    : std_logic;

	-- Test and debug register:
	signal test_register : test_context;

	-- Interrupt signals:
	signal timer_interrupt    : std_logic;
	signal software_interrupt : std_logic;

begin

	-- Interrupt signals:
	software_interrupt_out <= software_interrupt;
	timer_interrupt_out <= timer_interrupt;
	ie_out <= ie;
	ie1_out <= ie1;
	mie_out <= mie;

	--! Output the current test state:
	test_context_out <= test_register;

	time_clk_gen: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				time_clk <= '0';
				time_clk_counter <= 0;
			else
				if time_clk_counter = TIME_DIVIDER - 1 then
					time_clk_counter <= 0;
					time_clk <= not time_clk;
				else
					time_clk_counter <= time_clk_counter + 1;
				end if;
			end if;
		end if;
	end process time_clk_gen;

	mtime_counter: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				mtime_clock_counter <= 0;
				counter_mtime <= (others => '0');
			else
				if mtime_clock_counter = MTIME_DIVIDER - 1 then
					mtime_clock_counter <= 0;
					counter_mtime <= std_logic_vector(unsigned(counter_mtime) + 1);
				else
					mtime_clock_counter <= mtime_clock_counter + 1;
				end if;
			end if;
		end if;
	end process mtime_counter;

	mtime_interrupt: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				timer_interrupt <= '0';
			else
				if write_mode /= CSR_WRITE_NONE and write_address = CSR_MTIMECMP then
					timer_interrupt <= '0';
				elsif counter_mtime = mtime_compare then
					timer_interrupt <= '1';
				end if;
			end if;
		end if;
	end process mtime_interrupt;

	write: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				software_interrupt <= '0';
				mtvec <= (others => '0');
				mepc <= (others => '0');
				mie <= (others => '0');
				ie <= '0';
				ie1 <= '0';
				test_register <= (TEST_IDLE, (others => '0'));
			else
				if exception_context_write = '1' then
					ie <= exception_context.ie;
					ie1 <= exception_context.ie1;
					mcause <= exception_context.cause;
					mbadaddr <= exception_context.badaddr;
				end if;

				if write_mode /= CSR_WRITE_NONE then
					case write_address is
						when CSR_MSTATUS => -- Status register
							ie1 <= write_data_in(CSR_SR_MPIE_INDEX);
							ie <= write_data_in(CSR_SR_MIE_INDEX);
						when CSR_MSCRATCH => -- Scratch register
							mscratch <= write_data_in;
						when CSR_MEPC => -- Exception return address
							mepc <= write_data_in;
						--when CSR_MCAUSE => -- Exception cause
						--	mcause <= write_data_in(31) & write_data_in(4 downto 0);
						when CSR_MTVEC => -- Exception vector address
							mtvec <= write_data_in(31 downto 2);
						when CSR_MTIMECMP => -- Time compare register
							mtime_compare <= write_data_in;
						when CSR_MIE => -- Interrupt enable register:
							mie <= write_data_in;
						when CSR_MIP => -- Interrupt pending register:
							software_interrupt <= write_data_in(CSR_MIP_MSIP);
						when CSR_TEST => -- Test and debug register:
							test_register <= std_logic_to_test_context(write_data_in);
						when others =>
							-- Ignore writes to invalid or read-only registers
					end case;
				end if;
			end if;
		end if;
	end process write;

	read: process(clk)
	begin
		if rising_edge(clk) then

			if write_mode /= CSR_WRITE_NONE and write_address = CSR_MTVEC then
				mtvec_out <= write_data_in(31 downto 2) & b"00";
			else
				mtvec_out <= mtvec & b"00";
			end if;

			if write_mode /= CSR_WRITE_NONE and write_address = read_address then
				read_data_out <= write_data_in;
			else
				case read_address is

					-- Machine mode registers:
					when CSR_MSTATUS => -- Status register
						read_data_out <= csr_make_mstatus(ie, ie1);
					when CSR_MSCRATCH => -- Scratch register
						read_data_out <= mscratch;
					when CSR_MEPC => -- Exception PC value
						read_data_out <= mepc;
					when CSR_MTVEC => -- Exception vector address
						read_data_out <= mtvec & b"00";
					when CSR_MTDELEG => -- Exception vector delegation register, unsupported
						read_data_out <= (others => '0');
					when CSR_MIP => -- Interrupt pending
						read_data_out <= irq & (CSR_MIP_MTIP => timer_interrupt, CSR_MIP_MSIP => software_interrupt,
							23 downto 8 => '0', 6 downto 4 => '0', 2 downto 0 => '0');
					when CSR_MIE => -- Interrupt enable register
						read_data_out <= mie;
					when CSR_MBADADDR => -- Bad memory address
						read_data_out <= mbadaddr;
					when CSR_MCAUSE => -- Exception cause
						read_data_out <= mcause(5) & (30 downto 5 => '0') & mcause(4 downto 0); --to_std_logic_vector(mcause);

					-- Machine information registers:
					when CSR_MISA => -- ISA features register
						read_data_out <= (
								30 => '1', -- Set the MXL0 bit, indicating XLEN = 32
								 8 => '1', -- Set the bit corresponding to I (RV32I)
								others => '0');
					when CSR_MVENDORID => -- Vendor ID
						read_data_out <= (others => '0'); -- Use 0 to indicate a non-commercial implementation
					when CSR_MARCHID => -- Architecture ID
						read_data_out <= (others => '0'); -- Use 0 to indicate an unsupported field.
					when CSR_MIMPID => -- Implementation ID
						read_data_out <= x"47495400"; -- Source of this implementation: 'G', 'I', 'T', 0
					when CSR_MHARTID => -- Hardware thread ID
						read_data_out <= PROCESSOR_ID;

					-- Timers and counters:
					when CSR_MTIME => -- Machine time counter register
						read_data_out <= counter_mtime;
					when CSR_MTIMECMP => -- Machine time compare register
						read_data_out <= mtime_compare;

					when CSR_TIME =>
						read_data_out <= counter_time(31 downto 0);
					when CSR_TIMEH =>
						read_data_out <= counter_time(63 downto 32);
					when CSR_CYCLE =>
						read_data_out <= counter_cycle(31 downto 0);
					when CSR_CYCLEH =>
						read_data_out <= counter_cycle(63 downto 32);
					when CSR_INSTRET =>
						read_data_out <= counter_instret(31 downto 0);
					when CSR_INSTRETH =>
						read_data_out <= counter_instret(63 downto 32);

					-- Potato extensions:
					when CSR_TEST =>
						read_data_out <= test_context_to_std_logic(test_register);

					-- Return zero from write-only registers and invalid register addresses:
					when others =>
						read_data_out <= (others => '0');
				end case;
			end if;
		end if;
	end process read;

	timer_counter: entity work.pp_counter
		port map(
			clk => time_clk,
			reset => reset,
			count => counter_time,
			increment => '1'
		);

	cycle_counter: entity work.pp_counter
		port map(
			clk => clk,
			reset => reset,
			count => counter_cycle,
			increment => '1'
		);

	instret_counter: entity work.pp_counter
		port map(
			clk => clk,
			reset => reset,
			count => counter_instret,
			increment => count_instruction
		);

end architecture behaviour;
