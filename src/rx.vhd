/* requirements */
-- must support the UART protocol.
	-- 1 start bit.
	-- 8 din bits.
	-- 1 stop bit.
	-- no parity bits.
--x must support baud rate of at least 9600.
--x must be able to store at least one received byte.
--x must use 8x oversampling on the rx signal, and sample the middle of the
--x bit period to determine the value.
--x must indicate when din is received and ready to be used (din valid).
--x can do majority decision based on 5 samples in the middle of the bit period.
-- can have a 16 byte FIFO to store bytes, delete new din when ff_full.
-- should support parity control (even, odd, none).
-- should be able to change baud rate when running.

/* TODO: non-critical: implement parity. */

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
	signal din: std_logic := '0';
	signal char: std_logic_vector(BITWIDTH-1 downto 0):=(others=>'0');

	signal clk_cnt: natural range 0 to CLK_PER_SMP - 1 := 0;
	signal smp_idx: natural range 0 to SMP_PER_BIT - 1 := 0;
	signal bit_idx: natural range 0 to BITWIDTH - 1 := 0;
	signal votecnt: natural range 0 to MVOTES := 0;
begin
	/* read:  read rx serial din into rx din register */
	read: process(clk) begin
		if rising_edge(clk) then
			din <= serial_in;
		end if;
	end process;

	/* control:  control receiver states */
	control: process(clk) begin
		if rising_edge(clk) then
			data_valid <= '0'; /* default */
			case s is
				when idle => /* reset counters */
					clk_cnt <= 0;
					smp_idx <= 0;
					bit_idx <= 0;
					votecnt <= 0;
					if din = '0' then /* line low */
						s <= startbit;
						clk_cnt <= 0;
						smp_idx <= 0;
						votecnt <= 0;
					end if;

				when startbit =>
					if clk_cnt < CLK_PER_SMP - 1 then
						clk_cnt <= clk_cnt + 1;
					else
						clk_cnt <= 0;
						if smp_idx < SMP_PER_BIT - 1 then
							smp_idx <= smp_idx + 1;
							if smp_idx = SMP_PER_BIT / 2 and din = '1' then
								s <= idle; /* false start: middle sample high */
							end if;
						else /* got startbit */
							smp_idx <= 0;
							votecnt <= 0;
							bit_idx <= 0;
							s <= databit;
						end if;
					end if;

				when databit =>
					if clk_cnt < CLK_PER_SMP - 1 then
						clk_cnt <= clk_cnt + 1;
						/* count ones inside the voting window
						 *
						 * din: _____|`````
						 * win:    ^...^
						 *
						 */
						if smp_idx >= integer(SMP_PER_BIT/2) -integer(MVOTES/2)
						and smp_idx <= integer(SMP_PER_BIT/2)+integer(MVOTES/2) then
							if din = '1' then
								if votecnt < MVOTES then
									votecnt <= votecnt + 1;
								end if;
							end if;
						end if;
					else
						clk_cnt <= 0;
						if smp_idx < SMP_PER_BIT - 1 then
							smp_idx <= smp_idx + 1;
						else
							smp_idx <= 0;
							/* decide value by majority: (MVOTES+1)/2 */
							if votecnt >= (MVOTES + 1) / 2 then
								char <= char(BITWIDTH - 2 downto 0) & '1';
							else
								char <= char(BITWIDTH - 2 downto 0) & '0';
							end if;
							votecnt <= 0;
							if bit_idx < BITWIDTH - 1 then
								bit_idx <= bit_idx + 1;
								s <= databit;
							else
								s <= stopbit;
							end if;
						end if;
					end if;

				when stopbit =>
					if clk_cnt < CLK_PER_SMP - 1 then
						clk_cnt <= clk_cnt + 1;
					else
						clk_cnt <= 0;
						if smp_idx < SMP_PER_BIT - 1 then
							smp_idx <= smp_idx + 1;
							-- false stop detection (line low at middle)
							if smp_idx = SMP_PER_BIT / 2 and din = '0' then
								s <= idle; /* false stop: middle sample low */
							end if;
						else
							smp_idx <= 0;
							byte_out <= char; /* put char */
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