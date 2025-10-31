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

/* TODO: finish fifo implementation, use 'empty' and 'full' */
architecture rtl of fifo is
	constant DEPTH: positive := 16 * BITWIDTH;
	type mem_t is array (0 to DEPTH-1) of std_logic_vector(BITWIDTH-1 downto 0);
	signal mem: mem_t;
	signal rp, wp: integer := 0;
	signal i: integer := 0;
begin
	process(clk) begin
		if rst = '0' then
			rp <= 0;
			wp <= 0;
			i <= 0;
		elsif rising_edge(clk) then
			if w = '1' and i < DEPTH then /* there is room */
				mem(wp) <= data_in;
				wp <= (wp + 1) mod DEPTH;
				i <= i + 1;
			end if;
			if r = '1' and i > 0 then
				data_out <= mem(rp);
				rp <= (rp + 1) mod DEPTH;
				i <= i - 1;
			end if;
		end if;
	end process;
end architecture;