library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.all;

entity top is
	port ( /* TODO: decide which ports to consider */
		clk: in std_logic; /* SYS_CLK_FRQ defined in pkg */
		rstn: in std_logic;

		rx: in std_logic; 
		tx: out std_logic
	);
end entity;

architecture rtl of top is
	signal rx_dv: std_logic;
	signal tx_dv: std_logic;

	signal baud_tick: std_logic;

	/* rx tx io */
	signal rx_dout: std_logic_vector(BITWIDTH - 1 downto 0);
	signal tx_din: std_logic_vector(BITWIDTH - 1 downto 0);
	
	/* rx fifo */
	signal ff_din: std_logic_vector(BITWIDTH - 1 downto 0);
	signal ff_dout: std_logic_vector(BITWIDTH - 1 downto 0);
	signal ff_read, ff_write: std_logic; /* r/w enable */
	signal ff_empty, ff_full: std_logic; /* stauts flags */
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
			byte_out => rx_dout
		);

	rx_fifo: entity work.fifo
		port map (
			clk => clk,
			rst => rstn,
			r => ff_read,
			w => rx_dv,
			din => rx_dout,
			dout => ff_dout,
			empty => ff_empty,
			full => ff_full
		);
end architecture;
