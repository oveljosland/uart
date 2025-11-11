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
		perr: out std_logic; /* parity error */


		fifomathiasmaten: out std_logic_vector(8*16-1 downto 0);
		di: out std_logic := '0'; --for testing purposes only
		statusbatus: out std_logic_vector(7 downto 0):=(others=>'0'); -- for testing purposes only
		bytus: out std_logic_vector(BITWIDTH-1 downto 0):=(others=>'0')
	);
end entity;

architecture rtl of rx is
	
	constant MAJVOTES: positive := 5;
	
	/* voting window */
	constant LO: integer := SMP_PER_BIT / 2 - MAJVOTES / 2;
	constant HI: integer := SMP_PER_BIT / 2 + MAJVOTES / 2;

	signal s: state := idle;

	signal data_in: std_logic := '0';
	signal data_out: std_logic_vector(BITWIDTH-1 downto 0):=(others=>'0');
	signal clk_cnt: natural range 0 to CLK_PER_SMP - 1 := 0;
	signal smp_idx: natural range 0 to SMP_PER_BIT - 1 := 0;
	signal bit_idx: natural range 0 to BITWIDTH - 1 := 0;
	signal maj_cnt: natural range 0 to MAJVOTES := 0;
	signal par_bit: std_logic := '0';



begin
	/* read:  read 'din' into 'data' register */
	read: process(clk) begin
		if rising_edge(clk) then
			data_in <= din;
		end if;
	end process;

	/* control:  control receiver states */
	control: process(clk, rst)
		/* flush: clear registers */
		procedure flush is begin
			clk_cnt <= 0;
			smp_idx <= 0;
			bit_idx <= 0;
			maj_cnt <= 0;
		end procedure;
	begin
		if rst = SYSRST then
			s <= idle;
			flush;
		elsif rising_edge(clk) then
			data_valid <= '0'; /* default */
			case s is
				when idle =>
					if data_in = '0' then /* line low */
						clk_cnt <= 0;
						smp_idx <= 0;
						maj_cnt <= 0;
						s <= startbit;
					end if;

				when startbit =>
					if clk_cnt < CLK_PER_SMP - 1 then
						clk_cnt <= clk_cnt + 1;
					else
						
						clk_cnt <= 0;
						if smp_idx < SMP_PER_BIT - 1 then
							smp_idx <= smp_idx + 1;
							if smp_idx = SMP_PER_BIT / 2 and data_in = '1' then
								/* false start: middle sample high */
								s <= idle;
							end if;
						else /* got startbit */
							smp_idx <= 0;
							maj_cnt <= 0;
							bit_idx <= 0;
							s <= databit;
						end if;
					end if;

				when databit =>
					if clk_cnt < CLK_PER_SMP - 1 then
						clk_cnt <= clk_cnt + 1;
					else
						clk_cnt <= 0;
						/* count ones in voting window */
						if smp_idx >= LO and smp_idx <= HI then
							if data_in = '1' and maj_cnt < MAJVOTES then
								maj_cnt <= maj_cnt + 1;
							end if;
						end if;

						if smp_idx < SMP_PER_BIT - 1 then
							smp_idx <= smp_idx + 1;
						else /* done sampling */
							smp_idx <= 0;
							/* decide value by majority: (MAJVOTES+1)/2 */
							if maj_cnt >= (MAJVOTES + 1) / 2 then
								data_out <= data_out(BITWIDTH - 2 downto 0) & '1';
							else
								data_out <= data_out(BITWIDTH - 2 downto 0) & '0';
							end if;
							maj_cnt <= 0;
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
						
						/* count ones in voting window */
						if smp_idx >= LO and smp_idx <= HI then
							if data_in = '1' and maj_cnt < MAJVOTES then
								maj_cnt <= maj_cnt + 1;
							end if;
						end if;
					else
						clk_cnt <= 0;
						if smp_idx < SMP_PER_BIT - 1 then
							smp_idx <= smp_idx + 1;
						else /* done sampling */
							smp_idx <= 0;
							/* decide value by majority */
							if maj_cnt >= (MAJVOTES + 1) / 2 then
								par_bit <= '1';
							else
								par_bit <= '0';
							end if;
							maj_cnt <= 0;
							if pen = '1' then
								/* in vhdl, '!=' is '/=' for some reason */
								if par(data_out) /= par_bit then   
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
							if smp_idx = SMP_PER_BIT / 2 and data_in = '0' then
								/* false stop: middle sample low */
								s <= idle;
							end if;
						else /* done sampling */
							smp_idx <= 0;
							dout <= data_out; /* put data_out */
							fifomathiasmaten <= fifomathiasmaten(8*16-1-8 downto 0) & data_out; -- put data_out in FIFO
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
	end process;


	process(s, data_out) is
	begin
		-- for testing purposes only
		bytus <= data_out;
		if s = idle then
			statusbatus <= "00000001";
		elsif s = startbit then
			statusbatus <= "00000010";
		elsif s = databit then
			statusbatus <= "00000100";
		elsif s = paritybit then
			statusbatus <= "00001000";
		elsif s = stopbit then
			statusbatus <= "00010000";
		elsif s = flush then
			statusbatus <= "00100000";
		else
			statusbatus <= "11111111";
		end if;
	end process;
end architecture;