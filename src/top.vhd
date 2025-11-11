library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.all;

/* control/top module */

/* requirements */
-- print ascii code to seven-segment display.
-- flash led when a character is received.
-- loopback: send received character back immediately.
-- should send predetermined character with a button press.
-- can send a predetermined string of at least eight characters.
-- can adjust baud rate while running (100 kb/s – 1 Mb/s in 100 kb/s steps).


entity top is
	port ( /* TODO: decide which ports to consider */
		clk: in std_logic; /* SYS_CLK_FRQ defined in pkg */
		rst: in std_logic; /* SYSRESET defined in pkg */
		pen: in std_logic; /* parity enable */ 

		rx: in std_logic := '0'; 
		tx: out std_logic := '0';

		HEX0: out std_logic_vector(6 downto 0) := (others => '0');
		HEX1: out std_logic_vector(6 downto 0) := (others => '0');
		HEX2: out std_logic_vector(6 downto 0) := (others => '0')
	);
end entity;

architecture rtl of top is
	signal rx_dv: std_logic;
	signal tx_dv: std_logic;

	signal baud_tick: std_logic;

	/* rx tx io */
	signal perr: std_logic;
	signal rx_dout: std_logic_vector(BITWIDTH - 1 downto 0);
	signal tx_din: std_logic_vector(BITWIDTH - 1 downto 0);
	
	/* rx fifo */
	signal ff_din: std_logic_vector(BITWIDTH - 1 downto 0);
	signal ff_dout: std_logic_vector(BITWIDTH - 1 downto 0);
	signal ff_read, ff_write: std_logic := '0'; /* r/w enable */
	signal ff_empty, ff_full: std_logic := '0'; /* stauts flags */

	/* test: rx --> display */
	signal test_rx_dout: std_logic_vector(BITWIDTH - 1 downto 0);

begin
	baud_clock: entity work.baud_clock
		port map (
			clk => clk,
			rst => rst,
			baud_tick => baud_tick
		);

	rx_module: entity work.rx
		port map (
			clk => clk,
			rst => rst,
			din => rx,
			baud_tick => baud_tick,
			data_valid => rx_dv,
			dout => rx_dout,
			pen => pen,
			perr => perr
		);

	rx_fifo: entity work.fifo
		port map (
			clk => clk,
			rst => rst,
			r => ff_read,
			w => rx_dv,
			din => rx_dout,
			dout => ff_dout,
			empty => ff_empty,
			full => ff_full
		);
	display: entity work.display
		port map (
			char => test_rx_dout, -- set this to ff_dout later
			seg => HEX0
		);
	
	/* put some characters on the display */
	display_test: process(clk, rst)
		type string is array(0 to 15) of std_logic_vector(7 downto 0);

		constant chars: string := ( /* hexadecimal */
		/* '0'..'9' */
		x"30", x"31", x"32", x"33", x"34", x"35", x"36", x"37", x"38", x"39",
		/* 'A'..'F' */
		x"41", x"42", x"43", x"44", x"45", x"46"
		);
		variable i: natural := 0;
		variable d: natural := 0;
	begin
		if rst = '0' then
			test_rx_dout <= (others => '0');
			i := 0;
		elsif rising_edge(clk) then
			if d = 50_000_000 / 5 then
				test_rx_dout <= chars(i);
				i := (i +1) mod 16;
				d := 0;
			else
				d := d +1;
			end if;
		end if;
	end process;

end architecture;
