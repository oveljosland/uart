library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.all;

entity display is
	port (
		char: in std_logic_vector(BITWIDTH - 1 downto 0);
		seg: out std_logic_vector(BITWIDTH - 1 downto 0)
	);
end entity;

architecture rtl of display is
begin
	/* putchar:  put character onto the display */
	put_char: process(char)
		variable a: integer;
	begin
		a := to_integer(char);
end architecture;