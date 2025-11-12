library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.all; -- BITWIDT, SMP_PER_BIT, CLK_PER_SMP

entity rx_tb is
end entity;

architecture simulation of rx_tb is 
    constant CLK_PERIOD : time := 20 ns; -- Klokkeperiode (20ns = 50 Mhz)
    constant BIT_CYCLES : natural := SMP_PER_BIT * CLK_PER_SMP; -- Antall klokkesykluser per UART-bit -> 8 samples * antall klokker per sample

    signal rst : std_logic := '0'; -- reset signal
    signal clk : std_logic := '0'; -- Klokkesignal
    signal serial_in : std_logic := '1'; -- UART-linjen -> idle = 1 
    signal data_valid : std_logic; -- Byte klar signal
    signal byte_out : std_logic_vector(BITWIDTH-1 downto 0); -- Byte mottatt
    signal pen: std_logic:= '1'; /* parity enable */
    signal perr: std_logic; /* parity error */
    signal baud_tick: std_logic;

    -- Forventet byte (sendes og verifiseres)
    constant EXP_BYTE : std_logic_vector(0 to BITWIDTH-1):= "01000001";--x"41"; -- 'A' '01000001'

    signal fifi : std_logic_vector(8*16-1 downto 0); -- FIFO signal
    signal di : std_logic := '0'; -- for testing purposes only
    signal statusbatus : std_logic_vector(7 downto 0):=(others=>'0'); -- for testing purposes only
    begin
        clk <= not clk after CLK_PERIOD/2; -- Generer 50 MHz klokke ved å toggle hver periode/2 (10 ns)
        clkgen: entity work.baud_clock
            port map (
                clk => clk,
                rst => rst,
                baud_tick => baud_tick
            );
        urx: entity work.rx
            port map (
                clk => clk, 
                din => serial_in,
                data_valid => data_valid,
                dout => byte_out,
		rst => rst,
		baud_tick => baud_tick,
		pen => pen,
        perr => perr,
        di => di,
        statusbatus => statusbatus,
        fifomathiasmaten => fifi
            );

        stim: process 
            procedure send_bit(b : std_logic) is -- send en uart bit på serial_in
            begin
                serial_in <= b; -- settter linjen til bitverdien
                for cyc in 1 to BIT_CYCLES loop --  Holder biten en hel bitperiode
                    wait until rising_edge(clk); 
                end loop;
                end procedure;

        procedure send_byte(b : std_logic_vector(0 to BITWIDTH-1)) is 
        begin
            send_bit('0'); --send startbit (0)
            for i in 0 to BITWIDTH-1 loop -- send databiter
                send_bit(b(i)); 
            end loop; 
            if pen = '1' then
                send_bit(par(b)); -- send paritybit hvis aktivert
            end if;
            send_bit('1'); 
        end procedure; 

        procedure wait_for_data_valid(max_bits : natural; success : out boolean) is
            variable max_cycles : natural := max_bits * BIT_CYCLES + 5; -- margin
        begin
            success := false;
            for n in 1 to max_cycles loop
                wait until rising_edge(clk);
                if data_valid = '1' then
                    success := true;
                    exit;
                end if;
            end loop;
        end procedure;

	variable ok : boolean;

    begin 
        wait until rising_edge(clk);
            rst <= '1'; -- release reset (inactive high)
        for k in 1 to 10*BIT_CYCLES loop -- venter litt før start altså idle
            wait until rising_edge(clk);
        end loop;
        

        -- Test 1: Send byte 0x41 ('A') and check if it is received correctly
        report "Sender byte 0x41 ('A')" severity note; -- Melding i simulatoren
        send_byte(EXP_BYTE); -- send uart for A
        wait_for_data_valid(1 + BITWIDTH + 1 + 2, ok); -- start + 8 + stop + margin
	    if ok then
            if byte_out = EXP_BYTE then -- hvis korrekt byte er mottatt
                report "PASS: Riktig byte mottatt (0x41)" severity note; 
            else 
                report "FAIL: Feil byte!" severity note;
            end if;
        else 
            report "Fail: Timeout, ingen data_valid" severity error; 
        end if; 


        -- Test 2: Send byte 0x55 ('U') and check if it is received correctly
        report "Sender byte 0x55 ('U')" severity note;
        send_byte("01010101"); -- send uart for U
        wait_for_data_valid(1 + BITWIDTH + 1 + 2, ok); -- start + 8 + stop + margin
        if ok then 
            if byte_out = "01010101" then 
                report "PASS: Riktig byte mottatt (0x55)" severity note; 
            else 
                report "FAIL: Feil byte!" severity note;
            end if;
        else 
            report "Fail: Timeout, ingen data_valid" severity error;
        end if;

        -- send hei mathias her!
        send_byte("01101000"); -- h
        send_byte("01100101"); -- e
        send_byte("01101001"); -- i
        send_byte("00100000"); -- space
        send_byte("01101101"); -- m
        send_byte("01100001"); -- a
        send_byte("01110100"); -- t
        send_byte("01101000"); -- h
        send_byte("01101001"); -- i
        send_byte("01100001"); -- a
        send_byte("01110011"); -- s
        send_byte("00100000"); -- space
        send_byte("01101000"); -- h
        send_byte("01100101"); -- e
        send_byte("01110010"); -- r
        send_byte("00100001"); -- !
        wait until data_valid = '1';
        report "fifo er" & integer'image(to_integer(unsigned(fifi(8*16-1 downto 8*16-8)))) & " " &
               integer'image(to_integer(unsigned(fifi(8*16-1-8 downto 8*16-16)))) & " " &
               integer'image(to_integer(unsigned(fifi(8*16-1-16 downto 8*16-24)))) & " " &
               integer'image(to_integer(unsigned(fifi(8*16-1-24 downto 8*16-32)))) & " " &
               integer'image(to_integer(unsigned(fifi(8*16-1-32 downto 8*16-40)))) & " " &
               integer'image(to_integer(unsigned(fifi(8*16-1-40 downto 8*16-48)))) & " " &
               integer'image(to_integer(unsigned(fifi(8*16-1-48 downto 8*16-56)))) & " " &
               integer'image(to_integer(unsigned(fifi(8*16-1-56 downto 8*16-64)))) & " " &
               integer'image(to_integer(unsigned(fifi(8*16-1-64 downto 8*16-72)))) & " " &
               integer'image(to_integer(unsigned(fifi(8*16-1-72 downto 8*16-80)))) & " " &
               integer'image(to_integer(unsigned(fifi(8*16-1-80 downto 8*16-88)))) & " " &
               integer'image(to_integer(unsigned(fifi(8*16-1-88 downto 8*16-96)))) & " " &
               integer'image(to_integer(unsigned(fifi(8*16-1-96 downto 8*16-104)))) & " " &
               integer'image(to_integer(unsigned(fifi(8*16-1-104 downto 8*16-112)))) & " " &
               integer'image(to_integer(unsigned(fifi(8*16-1-112 downto 8*16-120)))) & " " &
               integer'image(to_integer(unsigned(fifi(8*16-1-120 downto 8*16-128)))) severity note;


        
        -- Wait a bit before ending the simulation
        for k in 1 to 5 * BIT_CYCLES loop
            wait until rising_edge(clk); 
        end loop;

        report "Testbench ferdig" severity note; 
        std.env.stop; -- avslutter simulering
        wait;
    end process;
end architecture;