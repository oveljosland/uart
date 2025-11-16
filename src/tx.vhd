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
		byte_in: in std_logic_vector(BITWIDTH - 1 downto 0);
		baud_tick: in std_logic;
		pen: in std_logic; /* parity enable */
		busy: out std_logic:= '0';
		serial_out: out std_logic
	);
end entity;

architecture rtl of utx is
	signal s: state := idle;
	type array_t is array (0 to 15) of std_logic_vector(BITWIDTH-1 downto 0);
	signal message : array_t := (
    x"48", -- H
    x"45", -- E
    x"4C", -- L
    x"4C", -- L
    x"4F", -- O
    x"20", -- space
    x"57", -- W
    x"4F", -- O
    x"52", -- R
    x"4C", -- L
    x"44", -- D
    x"20", -- space
    x"31", -- 1
    x"32", -- 2
    x"33", -- 3
    x"21"  -- !
);
signal msg_idx : integer range 0 to 15 := 0;
signal bit_idx: natural range 0 to BITWIDTH - 1 := 0;
begin
	send_message: process
	begin
		serial_out <= '1'; /* idle */
		wait until rising_edge(baud_tick);
		for msg_idx in 0 to 15 loop
			/* start bit */
			serial_out <= '0';
			wait until rising_edge(baud_tick);
			/* data bits */
			for bit_idx in 0 to BITWIDTH - 1 loop
				serial_out <= message(msg_idx)(bit_idx);
				wait until rising_edge(baud_tick);
			end loop;
			if pen = '1' then
				/* parity bit */
				serial_out <= par(message(msg_idx)); 
				wait until rising_edge(baud_tick);
			end if;
			/* stop bit */
			serial_out <= '1';
			wait until rising_edge(baud_tick);
		end loop;
	end process;
end architecture;