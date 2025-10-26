/* uart rx */

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity urx is
	generic (
		constant BITWIDTH: positive := 8;
		constant SYS_CLK_FRQ: positive := 50; /* MHz */
		constant BAUD_RATE: positive := 9600 /* B/s */
	);
	port (
		sclk: in std_logic; /* system clock */
		si: in std_logic; /* serial in */
		dv: out std_logic; /* data valid */
		bo: out std_logic /* byte out */
	);
end entity;

architecture rtl of urx is
	constant N: positive := SYS_CLK_FRQ*10e6 / BAUD_RATE;

	type state is (idle, startbit, databit);
	signal s: state := idle;

	signal d: std_logic := '0'; /* rx serial data in */
	signal b: std_logic_vector(BITWIDTH - 1 downto 0) := (others => '0'); /*byte out*/

	signal idx: natural range 0 to BITWIDTH - 1 := 0;
	signal cnt: natural range 0 to N - 1 := 0;

begin
	/* read:  read rx serial data into rx data register */
	read: process(sclk) begin
		if rising_edge(sclk) then
			d <= si;
		end if;
	end process;

	/* main:  receiver state machine */
	main: process(sclk) begin
		if rising_edge(sclk) then
			case s is
				when idle =>
					cnt <= 0;
					idx <= 0;
					if (d = '0') then
						s <= startbit;
					else
						s <= idle;
					end if;
				when startbit =>
					if cnt = (N - 1) / 2 then
						if d = '0' then
							cnt <= 0; /* middle */
							s <= databit;
						else
							s <= idle;
						end if;
					else
						cnt <= cnt + 1;
						s <= startbit; --lowkey denne linjen gjør ingenting
					end if;

				when databit =>
					if cnt < N - 1 then
						cnt <= cnt + 1;
						s <= databit; --lowkey denne linjen gjør ingenting
					else
						cnt <= 0;
						b(idx) <= d;
						idx <= idx + 1;
						if idx = BITWIDTH - 1 then
							s <= idle;
						end if;
					end if;
			end case;
		end if;
	end process;
end architecture;
