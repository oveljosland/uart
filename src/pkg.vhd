library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pkg is
	constant SYSRST: std_logic := '0'; /* system-wide active low */
	constant BITWIDTH: positive := 8; /* 8-bit code set */
	constant BAUDRATE: positive := 9600; /* B/s */
	constant SMP_PER_BIT: positive := 8; /* oversamples per bit */
	constant SYS_CLK_FRQ: positive := 50; /* MHz */
	constant CLK_PER_BIT: positive := SYS_CLK_FRQ * 1_000_000 / BAUDRATE;
	constant CLK_PER_SMP: positive := CLK_PER_BIT / SMP_PER_BIT;
	
	type state is (idle, startbit, databit, paritybit, stopbit, flush);
	type parity is (none, even, odd);

	type list is array (integer range <>) of integer;
	constant SUPPORTED_BAUDRATES: list := (
		9600, 19200, 38400, 57600, 115200
	);
	
	/* functions */
	pure function par(x: std_logic_vector) return std_logic;

end package;

package body pkg is

	/* par:  return parity of bit vector */
	pure function par(x: std_logic_vector) return std_logic is
		variable p: std_logic := '0';
	begin
		for i in x'RANGE loop
			p := p xor x(i);
		end loop;
		return p;
	end function;

end package body;