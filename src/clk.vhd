/* baud rate clock generator */

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.all;

entity clk is
	port (
		sclk: in std_logic; /* system clock */
		rstn: in std_logic; /* system reset */
		gclk: out std_logic /* generated clock */
	);
end entity;

architecture rtl of clk is
	constant MAX: positive := 1_000_000 * SYS_CLK_FRQ / BAUDRATE;
	signal cnt: natural range 0 to MAX - 1 := 0;
	signal reg: std_logic := '0'; /* output register */
begin
	/* clkgen:  generate baud rate clock */
	clkgen: process(sclk, rstn) begin
		if rstn = '0' then
			cnt <= 0;
			reg <= '0';
		elsif rising_edge(sclk) then
			if cnt = MAX - 1 then
				cnt <= 0;
				reg <= not reg;
			else
				cnt <= cnt + 1;
				/*
				 * uncomment to generate one pulse per baud
				 * instead of a square wave clock signal
				 */
				--reg <= '0'; /* pulse */
			end if;
		end if;
	end process;
	gclk <= reg;
end architecture;
