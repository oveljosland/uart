/* requirements */
-- must support the UART protocol.
	-- 1 start bit.
	-- 8 data bits.
	-- 1 stop bit.
	-- no parity bits.
--x must support baud rate of at least 9600.
--x must be able to store at least one received byte.
--x must use 8x oversampling on the rx signal, and sample the middle of the
--x bit period to determine the value.
--x must indicate when data is received and ready to be used (data valid).
--x can do majority decision based on 5 samples in the middle of the bit period.
-- can have a 16 byte FIFO to store bytes, delete new data when ff_full.
-- should support parity control (even, odd, none).
-- should be able to change baud rate when running.

/* TODO: non-critical: implement parity. */
/* TODO: connect fifo to rx logic */

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.all;

entity rx is
	port (
		clk: in std_logic;
		serial_in: in std_logic;
		data_valid: out std_logic;
		byte_out: out std_logic_vector(BITWIDTH - 1 downto 0)
	);
end entity;

architecture rtl of rx is
	
	constant MVOTES: positive := 5;

	signal s: state := idle;
	signal data: std_logic := '0';
	signal char: std_logic_vector(BITWIDTH-1 downto 0):=(others=>'0');

	signal i: natural range 0 to BITWIDTH - 1 := 0;		/* bit index counter */
	signal j: natural range 0 to SMP_PER_BIT - 1 := 0; /* oversample counter */
	signal k: natural range 0 to MVOTES - 1 := 0;	/* majority vote counter */

	component fifo
		port (
			clk: in std_logic;
			rst: in std_logic;
			r: in std_logic;
			w: in std_logic;
			data_in: in std_logic_vector(BITWIDTH - 1 downto 0);
			data_out: out std_logic_vector(BITWIDTH - 1 downto 0);
			empty, full: out std_logic
		);
	end component;

	signal ff_din: std_logic_vector(BITWIDTH - 1 downto 0);
	signal ff_dout: std_logic_vector(BITWIDTH - 1 downto 0);
	signal ff_w_en: std_logic;
	signal ff_r_en: std_logic;
	signal ff_empty: std_logic;
	signal ff_full: std_logic;
begin
	rx_fifo: fifo
		port map (
			clk => clk,
			rst => '1', /* TODO: rx.vhd does not have a reset signal yet */
			data_in => ff_din,
			data_out => ff_dout,
			w => ff_w_en,
			r => ff_r_en,
			empty => ff_empty,
			full => ff_full
		);
	
	/* read:  read rx serial data into rx data register */
	read: process(clk) begin
		if rising_edge(clk) then
			data <= serial_in;
		end if;
	end process;

	/* control:  control receiver states */
	control: process(clk) begin
		if rising_edge(clk) then
			data_valid <= '0'; /* default */
			case s is
				/* idle:  wait for transmission */
				when idle =>
					i <= 0;
					j <= 0;
					k <= 0;
					if data = '0' then
						s <= startbit;
					end if;
				
				/* startbit:  */
				when startbit =>
					if j < CLK_PER_SMP - 1 then
						j <= j + 1;
					else
						j <= 0;
						if i < SMP_PER_BIT - 1 then
							i <= i + 1;
							if i = SMP_PER_BIT / 2 and data = '1' then
								s <= idle; /* false start */
							end if;
						else
							i <= 0;
							k <= 0;
							s <= databit;
						end if;
					end if;
				
				/* databit:  */
				when databit =>
					if j < CLK_PER_SMP - 1 then
						j <= j + 1;
						/* count ones in voting window */
						if i >= (SMP_PER_BIT / 2 - MVOTES / 2)
						and i <= (SMP_PER_BIT / 2 + MVOTES / 2) then
							if data = '1' then
								k <= k + 1;
							end if;
						end if;
					else
						j <= 0;
						if i < SMP_PER_BIT - 1 then
							i <= i + 1;
						else
							/* end of bit period */
							if k >= MVOTES/2 then /* voting time */
								char <= char(BITWIDTH - 2 downto 0) & '1';
							else
								char <= char(BITWIDTH - 2 downto 0) & '0';
							end if;
							i <= 0;
							k <= 0;
							if i < BITWIDTH - 1 then
								s <= databit;
							else
								s <= stopbit;
							end if;
						end if;
					end if;
				
				/* stopbit:  */
				when stopbit =>
					if j < CLK_PER_SMP - 1 then
						j <= j + 1;
					else
						j <= 0;
						if i < SMP_PER_BIT - 1 then
							i <= i + 1;
							if i = SMP_PER_BIT / 2 and data = '0' then /* false stop */
								s <= idle;
							end if;
						else
							byte_out <= char;  /* put char */
							data_valid <= '1';
							s <= idle;
						end if;
					end if;
				
				/* flush:  clean and return to idle */
				when flush =>
					s <= idle;
			end case;
		end if;
	end process;
end architecture;