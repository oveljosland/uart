library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.all;

entity top is
	port ( /* TODO: decide which ports to consider */
		clk: in std_logic; /* SYS_CLK_FRQ defined in pkg */
		rst: in std_logic; /* RST defined in pkg */

		rx: in std_logic; 
		tx: out std_logic;

		HEX0: out std_logic_vector(6 downto 0);
		HEX1: out std_logic_vector(6 downto 0);
		HEX2: out std_logic_vector(6 downto 0)
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
			serial_in => rx,
			baud_tick => baud_tick,
			data_valid => rx_dv,
			byte_out => rx_dout
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
	
	cooltest: process(clk, rst)
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

	anim1: process(clk, rst)
		constant SPEED: positive := 5_000_000;
		constant STEPS: positive := 8;
		type list2 is array(0 to STEPS - 1) of std_logic_vector(6 downto 0);
		constant pattern: list2 := (
			"1111110",
			"1111101",
			"0111111",
			"1101111",
			"1110111",
			"1111011",
			"0111111",
			"1011111"
		);
		variable cnt: integer := 0;
		variable i: integer := 0;
	begin
		if rst = '0' then
			i := 0;
			cnt := 0;
			HEX1 <= (others => '1');
		elsif rising_edge(clk) then
			if cnt = SPEED then
				i := (i + 1) mod STEPS;
				HEX1 <= pattern(i);
				cnt := 0;
			else
				cnt := cnt + 1;
			end if;
		end if;
	end process;

	anim2: process(clk, rst)
		constant SPEED: positive := 2_000_000;
		constant STEPS: positive := 58;
		type list2 is array(0 to STEPS-1) of std_logic_vector(6 downto 0);
		constant pattern: list2 := (
			"1111110",
			"1111101",
			"1111011",
			"1110111",
			"1101111",
			"1011111",
			"1111110",
			"1111100",
			"1111001",
			"1110011",
			"1100111",
			"1001111",
			"1011110",
			"1111100",
			"1111000",
			"1110001",
			"1100011",
			"1000111",
			"1001110",
			"1011100",
			"1111000",
			"1110000",
			"1100001",
			"1000011",
			"1000110",
			"1001100",
			"1011000",
			"1110000",
			"1100000",
			"1000001",
			"1000010",
			"1000100",
			"1001000",
			"1010000",
			"1100000",
			"1000001",
			"1000011",
			"1000110",
			"1001100",
			"1011000",
			"1110000", 
			"1100001",
			"1000011",
			"1000111",
			"1001110",
			"1011100",
			"1111000", 
			"1110001",
			"1100011",
			"1000111",
			"1001111",
			"1011110",
			"1111100", 
			"1111001",
			"1110011",
			"1100111",
			"1001111",
			"1011111"
		);
		variable cnt: natural := 0;
		variable i: integer := 0;
	begin
		if rst = '0' then
			i := 0;
			cnt := 0;
			HEX2 <= (others => '1');
		elsif rising_edge(clk) then
			if cnt = SPEED then
				i := (i + 1) mod STEPS;
				HEX2 <= pattern(i);
				cnt := 0;
			else
				cnt := cnt + 1;
			end if;
		end if;
	end process;

end architecture;
