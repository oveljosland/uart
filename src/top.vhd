library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.all;

entity top is
	port ( /* TODO: decide which ports to consider */
		sclk: in std_logic; /* system clock */
		rstn: in std_logic; /* active low */

		rx: in std_logic; 
		tx: out std_logic;
	);
end entity;

architecture rtl of top is
	signal rx_dv: std_logic;
	signal tx_dv: std_logic;
begin
	rx_module: entity work.rx
	port map (
		clk => sclk, /* TODO: replace sclk with baud clock */
	);
	
	/* loopback */
	-- tx data <= rx data
end architecture;
