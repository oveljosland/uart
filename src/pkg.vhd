library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pkg is
	constant BITWIDTH: positive := 8;
	constant BAUDRATE: positive := 9600; /* B/s */
	constant NSAMP: positive := 8; /* oversampling */
	constant SYS_CLK_FRQ: positive := 50; /* MHz */
	constant CLK_PER_BIT: positive := SYS_CLK_FRQ * 1000000 / BAUDRATE;
	constant CLK_PER_SMP: positive := CLK_PER_BIT / NSAMP; /* cycles/sample */
	
	type state is (idle, startbit, databit, stopbit, flush);
end package;