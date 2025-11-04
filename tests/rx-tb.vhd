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

    signal clk : std_logic := '0'; -- Klokkesignal
    signal serial_in : std_logic := '1'; -- UART-linjen -> idle = 1 
    signal data_valid : std_logic; -- Byte klar signal
    signal byte_out : std_logic_vector(BITWIDTH-1 downto 0) -- Byte mottatt

    begin
        clk <= not clk after CLK_PERIOD/2; -- Generer 50 MHz klokke ved å toggle hver periode/2 (10 ns)

        urx: entity work.urx
            port map (
                clk => clk, 
                serial_in => serial_in,
                data_valid => data_valid,
                byte_out => byte_out
            );

        stim: process 
            procedure send_bit(b : std_logic) is -- send en uart bit på serial_in
            begin
                serial_in <= b; -- settter linjen til bitverdien
                for cyc in 1 to BIT_CYCLES loop --  Holder biten en hel bitperiode
                    wait until rising_edge(clk); 
                end loop;
                end procedure;

        procedure send_byte(b : std_logic_vector(BITWIDTH-1 downto 0)) is 
        begin
            send_bit('0'); --send startbit (0)
            for i in 0 to BITWIDTH-1 loop -- send databiter
                send_bit(b(i)); 
            end loop; 
            send_bit('1'); 
        end procedure; 

        function wait_for_data_valid(max_bits : natural) return boolean is 
            variable max_cycles : natural := max_bits * BIT_CYCLES + 5; -- max ventetid i klokkepulser (bitperioder + margin)
        begin
            for n in 1 to max_cycles loop -- sjekk inntil timeout
                wait until rising_edge(clk);  -- vent på klokke
                if data_valid = '1' then -- hvis data klar
                    return true; -- returnerer suksess
                end if; 
            end loop; 
            return false; -- timeout ingen data mottatt
        end function;

    begin 
        for i in 1 to 10*BIT_CYCLES loop -- venter litt før start altså idle
            wait until rising_edge(clk);
        end loop;
        
        report "Sender byte 0x41 ('A')" severity note; -- Melding i simulatoren

        send_byte(EXP_BYTE); -- send uart for A

        if wait_for_data_valid(1 + BITWIDTH + 1 + 2) then -- venter på data valid (start + 8 + stopp + margin)
            if byte_out = EXP_BYTE then -- hvis korrekt byte er mottatt
                report "PASS: Riktig byte mottatt (0x41)" severity note; 
            else 
                report "FAIL: Feil byte!" severity note;
            end if
        else 
            report "Fail: Timeout, ingen data_valid" severity error; 
        end if; 

        for i in 1 to 5 * BIT_CYCLES loop -- venter litt etter
            wait until rising_edge(clk); 
        end loop;

        report "Testbench ferdig" severity note; 
        std.env.stop; -- avslutter simulering
        wait;
    end process
end architecture    
    



