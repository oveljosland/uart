library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.all;

entity baud_clock is
	port (
		clk: in std_logic;
		rst: in std_logic;
		baud_tick: out std_logic
	);
end entity;

architecture rtl of baud_clock is
	constant DIV: positive := 1_000_000 * SYS_CLK_FRQ / BAUDRATE;
	signal i: natural range 0 to DIV - 1 := 0;
	signal clk_out: std_logic := '0';
begin
	/* gen:  generate baud rate clock */
	gen: process(clk, rst) begin
		if rst = RST then
			i <= 0;
			clk_out <= '0';
		elsif rising_edge(clk) then
			if i = DIV - 1 then
				i <= 0;
				clk_out <= not clk_out;
			else
				i <= i + 1;
				/*
				 * uncomment to generate one pulse/tick per baud
				 * instead of a square wave clock signal
				 */
				clk_out <= '0'; /* pulse/tick */
			end if;
		end if;
	end process;
	/* TODO:  check if this need to be inside a process */
	baud_tick <= clk_out;
end architecture;