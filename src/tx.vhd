/* requirements */
-- must support the UART protocol.
	-- 1 start bit.
	-- 8 data bits.
	-- 1 stop bit.
	-- no parity bits.
-- must support baud rate of at least 9600.
-- must be able to store the byte to be transmitted.
-- must indicate with a signal that tx is busy.
-- should support parity control (even, odd, none).
-- should be able to change baud rate when running.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.all;

entity utx is
	port (
		clk: in std_logic;
		char_in: in std_logic_vector(BITWIDTH-1 downto 0);
		busy: out std_logic;
		serial_out: out std_logic
	);
end entity;

architecture rtl of utx is
	signal s: state := idle;
begin
end architecture;