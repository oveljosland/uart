library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.BITWIDTH;
use work.pkg.SYSRESET;

entity fifo is
	port (
		clk: in std_logic;
		rst: in std_logic;
		r: in std_logic;
		w: in std_logic;
		din: in std_logic_vector(BITWIDTH - 1 downto 0);
		dout: out std_logic_vector(BITWIDTH - 1 downto 0);
		empty, full: out std_logic;

		--test signals
		rec_byte: out std_logic_vector(BITWIDTH - 1 downto 0) := (others => '0')
	);
end entity;

architecture rtl of fifo is
	constant LEN: positive := 2 ** 7;
	type array_t is array (0 to LEN-1) of std_logic_vector(BITWIDTH-1 downto 0);
	signal queue: array_t;
	signal rp, wp: integer := 0;
	signal i: natural := 0;
begin
	rw: process(rst, w, r) begin
		dout <= queue(rp);
		if rst = SYSRESET then
			rp <= 0;
			wp <= 0;
			i <= 0;
		end if;
		if rising_edge(w) and i < LEN then /* there is room */
			queue(wp) <= din;
			wp <= (wp + 1) mod LEN;
			i <= i + 1;
		end if;
		if rising_edge(r) and i > 0 then
			rp <= (rp + 1) mod LEN;
			i <= i - 1;
		end if;
	end process;

	status: process(i) begin
		if i = 0 then
			empty <= '1';
		else
			empty <= '0';
		end if;
		
		if i = LEN then
			full <= '1';
		else
			full <= '0';
		end if;
	end process;

	-- test: output fifo content
	test_output: process(clk, queue, rp) begin
		if rising_edge(clk) then
			rec_byte <= queue(rp);
		end if;
	end process;
end architecture;