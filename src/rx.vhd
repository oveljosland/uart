/* requirements */
-- must support the UART protocol.
	-- 1 start bit.
	-- 8 data bits.
	-- 1 stop bit.
	-- no parity bits.
--x must support baud rate of at least 9600.
--x must be able to store at least one received byte.
--x must use 8x oversampling on the rx signal, and sample the middle of the
--  bit period to determine the value.
--x must indicate when data is received and ready to be used (data valid).
--x can do majority decision based on 5 samples in the middle of the bit period.
--x can have a 16 byte FIFO to store bytes, delete new data when full.
-- should support parity control (even, odd, none).
-- should be able to change baud rate when running.

/* TODO: non-critical: implement parity. */

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.all;

entity rx is
	port (
		clk: in std_logic; /* system clock */
		rst: in std_logic; /* reset defined in pkg.vhd */
		din: in std_logic; /* data in */
		pen: in std_logic; /* parity enable */
		baud_tick: in std_logic;
		data_valid: out std_logic;
		dout: out std_logic_vector(BITWIDTH - 1 downto 0); /* data out */
		perr: out std_logic /* parity error */
	);
end entity;

architecture rtl of rx is
	
	constant MAJVOTES: positive := 5;

	signal s: state := idle;
	signal data: std_logic := '0';
	signal byte: std_logic_vector(BITWIDTH-1 downto 0):=(others=>'0');

	signal clk_cnt: natural range 0 to CLK_PER_SMP - 1 := 0;
	signal smp_idx: natural range 0 to SMP_PER_BIT - 1 := 0;
	signal bit_idx: natural range 0 to BITWIDTH - 1 := 0;
	signal vot_cnt: natural range 0 to MAJVOTES - 1 := 0;
	signal par_bit: std_logic := '0';

	/* count_votes:  count ones inside voting window */
	function count_votes(data: std_logic; idx: natural) return natural is
		variable cnt: natural := 0;
	begin
		/*
		 * count inside centered -MAJVOTES/2..+MAJVOTES/2 window 
		 *
		 * din: _____|`````
		 * win:    ^...^
		 *
		 */
		if idx >= SMP_PER_BIT / 2 - integer(MAJVOTES / 2)
		and idx <=SMP_PER_BIT / 2 + integer(MAJVOTES / 2) then
			if data = '1' then
				if cnt < MAJVOTES then
					cnt := cnt + 1;
				end if;
			end if;
		end if;
		return cnt;
	end function;

begin
	/* read:  read 'din' into 'data' register */
	read: process(clk) begin
		if rising_edge(clk) then
			data <= din;
		end if;
	end process;

	/* control:  control receiver states */
	control: process(clk)
		/* flush: clear registers */
		procedure flush is begin
			clk_cnt <= 0;
			smp_idx <= 0;
			bit_idx <= 0;
			vot_cnt <= 0;
		end procedure;
	begin
		if rst = RST then
			flush;
			s <= idle;
		elsif rising_edge(clk) then
			data_valid <= '0'; /* default */
			if baud_tick = '1' then
				case s is
					when idle =>
						if data = '0' then /* line low */
							clk_cnt <= 0;
							smp_idx <= 0;
							vot_cnt <= 0;
							s <= startbit;
						end if;

					when startbit =>
						if clk_cnt < CLK_PER_SMP - 1 then
							clk_cnt <= clk_cnt + 1;
						else
							clk_cnt <= 0;
							if smp_idx < SMP_PER_BIT - 1 then
								smp_idx <= smp_idx + 1;
								if smp_idx = SMP_PER_BIT / 2 and data = '1' then
									/* false start: middle sample high */
									s <= idle;
								end if;
							else /* got startbit */
								smp_idx <= 0;
								vot_cnt <= 0;
								bit_idx <= 0;
								s <= databit;
							end if;
						end if;

					when databit =>
						if clk_cnt < CLK_PER_SMP - 1 then
							clk_cnt <= clk_cnt + 1;
							vot_cnt <= count_votes(data, smp_idx);
						else
							clk_cnt <= 0;
							if smp_idx < SMP_PER_BIT - 1 then
								smp_idx <= smp_idx + 1;
							else /* done sampling */
								smp_idx <= 0;
								/* decide value by majority: (MAJVOTES+1)/2 */
								if vot_cnt >= (MAJVOTES + 1) / 2 then
									byte <= byte(BITWIDTH - 2 downto 0) & '1';
								else
									byte <= byte(BITWIDTH - 2 downto 0) & '0';
								end if;
								vot_cnt <= 0;
								if bit_idx < BITWIDTH - 1 then
									bit_idx <= bit_idx + 1;
									s <= databit;
								else
									s <= paritybit;
								end if;
							end if;
						end if;
					
					when paritybit =>
						if clk_cnt < CLK_PER_SMP - 1 then
							clk_cnt <= clk_cnt + 1;
						else
							clk_cnt <= 0;
							if smp_idx < SMP_PER_BIT - 1 then
								smp_idx <= smp_idx + 1;
							else /* done sampling */
								smp_idx <= 0;
								/* decide value by majority */
								if vot_cnt >= (MAJVOTES + 1) / 2 then
									par_bit <= '1';
								else
									par_bit <= '0';
								end if;
								vot_cnt <= 0;
								if pen = '1' then
									/* in vhdl, '!=' is '/=' for some reason */
									if par(byte) /= par_bit then   
										perr <= '1';
									else
										perr <= '0';
									end if;
								end if;
								s <= stopbit;
							end if;
						end if;

					when stopbit =>
						if clk_cnt < CLK_PER_SMP - 1 then
							clk_cnt <= clk_cnt + 1;
						else
							clk_cnt <= 0;
							if smp_idx < SMP_PER_BIT - 1 then
								smp_idx <= smp_idx + 1;
								if smp_idx = SMP_PER_BIT / 2 and data = '0' then
									/* false stop: middle sample low */
									s <= idle;
								end if;
							else /* done sampling */
								smp_idx <= 0;
								dout <= byte; /* put byte */
								data_valid <= '1';
								s <= idle;
							end if;
						end if;
					/*
					 * TODO: decide if the 'flush' state is necessary,
					 * it may be used in the tx module.
					 */
					when flush =>
						s <= idle;
				end case;
			end if;
		end if;
	end process;
end architecture;