library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.all;

entity display is
	port (
		char: in std_logic_vector(BITWIDTH - 1 downto 0);
		seg: out std_logic_vector(6 downto 0)
	);
end entity;

architecture rtl of display is
begin

	/* putchar:  put character onto the display */
	putchar: process(char)
		variable a: integer;
	begin
		if char >= x"30" and char <= x"39" then    /* '0'..'9' */
			a := to_integer(unsigned(char)) - 48;
		elsif char >= x"41" and char <= x"46" then /* 'A'..'F' */
			a := to_integer(unsigned(char)) - 55;  /* 'A' = 10 */
		elsif char >= x"61" and char <= x"66" then /* 'a'..'f' */
			a := to_integer(unsigned(char)) - 87;  /* 'a' = 10 */
		else
			a := 16;
		end if;

		case a is
			when 0  => seg <= "1000000"; /* 0 */
			when 1  => seg <= "1111001"; /* 1 */
			when 2  => seg <= "0100100"; /* 2 */
			when 3  => seg <= "0110000"; /* 3 */
			when 4  => seg <= "0011001"; /* 4 */
			when 5  => seg <= "0010010"; /* 5 */
			when 6  => seg <= "0000010"; /* 6 */
			when 7  => seg <= "1111000"; /* 7 */
			when 8  => seg <= "0000000"; /* 8 */
			when 9  => seg <= "0010000"; /* 9 */
			when 10 => seg <= "0001000"; /* A */
			when 11 => seg <= "0000011"; /* b */
			when 12 => seg <= "1000110"; /* C */
			when 13 => seg <= "0100001"; /* d */
			when 14 => seg <= "0000110"; /* E */
			when 15 => seg <= "0001110"; /* F */
			when others => seg <= "1111111";
		end case;
	end process;
end architecture;