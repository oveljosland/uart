library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.all;

entity top is
	port ( /* TODO: decide which ports to consider */
		clk: in std_logic; /* system clock */
		rstn: in std_logic; /* active low */

		rx: in std_logic; 
		tx: out std_logic
	);
end entity;

architecture rtl of top is
	signal rx_dv: std_logic;
	signal tx_dv: std_logic;

	signal baud_tick: std_logic;
	signal byte_out: std_logic_vector(BITWIDTH - 1 downto 0);
begin
	baud_clock: entity work.baud_clock
		port map (
			clk => clk,
			rstn => rstn,
			baud_tick => baud_tick
		);

	rx_module: entity work.rx
		port map (
			clk => baud_tick,
			serial_in => rx,
			data_valid => rx_dv,
			byte_out => byte_out
		);
end architecture;
