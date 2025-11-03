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
		a := to_integer(unsigned(char));
		case a is
			when 48 => seg <= "1000000"; /* 0 */
			when 49 => seg <= "1111001"; /* 1 */
			when 50 => seg <= "0100100"; /* 2 */
			when 51 => seg <= "0110000"; /* 3 */
			when 52 => seg <= "0011001"; /* 4 */
			when 53 => seg <= "0010010"; /* 5 */
			when 54 => seg <= "0000010"; /* 6 */
			when 55 => seg <= "1111000"; /* 7 */
			when 56 => seg <= "0000000"; /* 8 */
			when 57 => seg <= "0010000"; /* 9 */
			when others => seg <= "1111111";
		end case;
	end process;
end architecture;