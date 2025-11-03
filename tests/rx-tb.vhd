/* testbench for rx module */
/* Denne testbenken skal kunne simulere oppførselen til rx modulen */

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.pkg.all; -- BITWIDT, SMP_PER_BIT, CLK_PER_SMP

entity rx_tb is
end entity;

architecture simulation of rx_tb is 
    constant CLK_PERIOD : time := 20 ns; -- Klokkeperiode (20ns = 50 Mhz)
    constant BIT_CYCLES : natural := SMP_PER_BIT * CLK_PER_SMP -- Antall klokkesykluser per UART-bit -> 8 samples * antall klokker per sample

    