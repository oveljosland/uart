library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.pkg.all;

entity baud_clock is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        inc_btn    : in  std_logic;  -- button to increase baud
        baud_tick  : out std_logic
    );
end entity;

architecture rtl of baud_clock is
    constant DIV : positive := 1_000_000 * SYS_CLK_FRQ / SMP_PER_BIT;

    signal i        : natural range 0 to DIV - 1 := 0;
    signal clk_out  : std_logic := '0';
    signal baudrate : positive range 100_000 to 1_000_000 := 100_000;

    -- debounce & edge detection
    signal btn_sync, btn_prev : std_logic := '0';
    signal debounce_cnt       : natural range 0 to 500_000 := 0; -- ~10 ms at 50 MHz
    signal btn_clean           : std_logic := '0';
begin

    -- Button debounce and rising edge detection
    process(clk, rst)
    begin
        if rst = SYSRESET then
            btn_sync    <= '0';
            btn_prev    <= '0';
            debounce_cnt <= 0;
            btn_clean   <= '0';
        elsif rising_edge(clk) then
            -- synchronize button to clock domain
            btn_sync <= inc_btn;

            -- debounce counter
            if btn_sync = '1' then
                if debounce_cnt < 500_000 then
                    debounce_cnt <= debounce_cnt + 1;
                else
                    btn_clean <= '1';
                end if;
            else
                debounce_cnt <= 0;
                btn_clean <= '0';
            end if;

            -- save previous for edge detection
            btn_prev <= btn_clean;

            -- increment baud rate on rising edge of debounced button
            if btn_clean = '1' and btn_prev = '0' then
                if baudrate + 100_000 > 1_000_000 then
                    baudrate <= 100_000; -- loop back
                else
                    baudrate <= baudrate + 100_000;
                end if;
            end if;
        end if;
    end process;

    -- Baud clock generation
    gen: process(clk, rst)
    begin
        if rst = SYSRESET then
            i <= 0;
            clk_out <= '0';
        elsif rising_edge(clk) then
            if i = DIV / baudrate - 1 then
                i <= 0;
                clk_out <= not clk_out; -- square wave
            else
                i <= i + 1;
                clk_out <= '0';  -- optional: single pulse instead of square wave
            end if;
        end if;
    end process;

    baud_tick <= clk_out;

end architecture;
