library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.all;

entity top is
	port (
		sclk: in std_logic; /* system clock */
		rstn: in std_logic; /* active low */

		rx: in std_logic;
		tx; out std_logic;

		valid: out std_logic; /* rx data valid */
		busy: out std_logic /* tx busy */
	);
end entity;