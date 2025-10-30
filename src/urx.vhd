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
-- can have a 16 bit FIFO to store bytes, delete new data when full.
-- should support parity control (even, odd, none).
-- should be able to change baud rate when running.

/* TODO: non-critical: implement fifo, parity. */

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.all;

entity urx is
	port (
		clk: in std_logic; /* system clock */
		si: in std_logic; /* serial in */
		dv: out std_logic; /* data valid */
		bo: out std_logic_vector(BITWIDTH-1 downto 0) /* byte out */
	);
end entity;

architecture rtl of urx is
	
	constant NVOTE: positive := 5;
	signal s: state := idle;
	signal d: std_logic := '0'; /* rx serial data in */
	signal b: std_logic_vector(BITWIDTH-1 downto 0):=(others=>'0');/*byte out*/
	signal votes: natural range 0 to NVOTE := 0; /* ones in voting window */
	signal samps: natural range 0 to CLK_PER_SMP - 1 := 0;
	signal idx: natural range 0 to BITWIDTH - 1 := 0;
begin
	/* read:  read rx serial data into rx data register */
	read: process(clk) begin
		if rising_edge(clk) then
			d <= si;
		end if;
	end process;

	/* main:  receiver state machine */
	main: process(clk) begin
		if rising_edge(clk) then
			dv <= '0'; /* default */
			case s is
				when idle =>
					samps <= 0;
					idx <= 0;
					votes <= 0;
					if d = '0' then
						s <= startbit;
					end if;

				when startbit =>
					if samps < CLK_PER_SMP - 1 then
						samps <= samps + 1;
					else
						samps <= 0;
						if idx < NSAMP - 1 then
							idx <= idx + 1;
							if idx = NSAMP/2 and d = '1' then /* false start */
								s <= idle;
							end if;
						else
							idx <= 0;
							votes <= 0;
							s <= databit;
						end if;
					end if;

				when databit =>
					if samps < CLK_PER_SMP - 1 then
						samps <= samps + 1;
						/* count ones in voting window */
						if idx >= (NSAMP / 2 - NVOTE / 2)
						and idx <= (NSAMP / 2 + NVOTE / 2) then
							if d = '1' then
								votes <= votes + 1;
							end if;
						end if;
					else
						samps <= 0;
						if idx < NSAMP - 1 then
							idx <= idx + 1;
						else
							/* end of bit period */
							if votes >= NVOTE/2 then /* voting time */
								b <= b(BITWIDTH - 2 downto 0) & '1';
							else
								b <= b(BITWIDTH - 2 downto 0) & '0';
							end if;
							idx <= 0;
							votes <= 0;
							if idx < BITWIDTH - 1 then
								s <= databit;
							else
								s <= stopbit;
							end if;
						end if;
					end if;

				when stopbit =>
					if samps < CLK_PER_SMP - 1 then
						samps <= samps + 1;
					else
						samps <= 0;
						if idx < NSAMP - 1 then
							idx <= idx + 1;
							if idx = NSAMP / 2 and d = '0' then /* false stop */
								s <= idle;
							end if;
						else
							bo <= b;  /* put byte */
							dv <= '1';
							s <= idle;
						end if;
					end if;
				when flush =>
					s <= idle;
			end case;
		end if;
	end process;
end architecture;
