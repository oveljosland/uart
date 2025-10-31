library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.BITWIDTH;

entity fifo is
	port (
		clk: in std_logic;
		rst: in std_logic;
		r: in std_logic;
		w: in std_logic;
		data_in: in std_logic_vector(BITWIDTH - 1 downto 0);
		data_out: out std_logic_vector(BITWIDTH - 1 downto 0);
		empty, full: out std_logic
	);
end entity;

architecture rtl of fifo is
	constant NBITS: positive := 7;
	constant DEPTH: positive := 2 ** NBITS;
	type mem is array (0 to DEPTH-1) of std_logic_vector(BITWIDTH-1 downto 0);
	signal stack: mem;
	signal rp, wp: integer := 0;
	signal i: integer := 0;
begin
	rw: process(clk) begin
		if rst = '0' then
			rp <= 0;
			wp <= 0;
			i <= 0;
		elsif rising_edge(clk) then
			if w = '1' and i < DEPTH then /* there is room */
				stack(wp) <= data_in; /* push */
				wp <= (wp + 1) mod DEPTH;
				i <= i + 1;
			end if;
			if r = '1' and i > 0 then
				data_out <= stack(rp); /* pop */
				rp <= (rp + 1) mod DEPTH;
				i <= i - 1;
			end if;
		end if;
	end process;

	status: process(clk) begin
		if rising_edge(clk) then
			if i = 0 then
				empty <= '1';
			else
				empty <= '0';
			end if;
			
			if i = DEPTH then
				full <= '1';
			else
				full <= '0';
			end if;
		end if;
	end process;
end architecture;