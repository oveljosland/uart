library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.all;

entity rx_tb is
end entity;

architecture sim of rx_tb is
	constant SYS_CLK_PER: time := 20 ns;
	constant BAUD_TICK_PER: time := (1 sec) / (BAUDRATE * SMP_PER_BIT);

	signal clk: std_logic := '0';
	signal rst: std_logic := not SYSRESET;
	signal din: std_logic := '1';
	signal pen: std_logic := '0';
	signal baud_tick: std_logic := '0';
	signal data_valid: std_logic;
	signal dout: std_logic_vector(BITWIDTH - 1 downto 0);
	signal perr: std_logic;

	signal test_byte: std_logic_vector(7 downto 0);
	signal par_bit: std_logic;
begin
end architecture;