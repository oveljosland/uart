/* control module:  may be merged into top.vhd */

/* requirements */
-- print ascii code to seven-segment display.
-- flash led when a character is received.
-- loopback: send received character back immediately.
-- should send predetermined character with a button press.
-- can send a predetermined string of at least eight characters.
-- can adjust baud rate while running (100 kb/s – 1 Mb/s in 100 kb/s steps).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.all;

entity ctr is
end entity;

architecture rtl of ctr is
begin
end architecture;