-- DO NOT MODIFY THIS FILE.
-- This file is generated by hard_tests_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sub_d_test_const.all;
use work.global_const.all;
use work.bus_const.all;

entity sub_d_fake_ram is
    port (
        clk, rst: in std_logic;
        cpu_i: in BusC2D;
        cpu_o: out BusD2C
    );
end sub_d_fake_ram;

architecture bhv of sub_d_fake_ram is
    type WordsArray is array(0 to MAX_RAM_ADDRESS) of std_logic_vector(DataWidth);
    signal words: WordsArray;
    signal wordAddr: integer;
    signal bitSelect: std_logic_vector(DataWidth);
    signal llBit: std_logic;
    signal llLoc: std_logic_vector(AddrWidth);
begin
    cpu_o.busy <= PIPELINE_NONSTOP;

    wordAddr <= to_integer(unsigned(cpu_i.addr(11 downto 2)));

    bitSelect <= (
        31 downto 24 => cpu_i.byteSelect(3),
        23 downto 16 => cpu_i.byteSelect(2),
        15 downto 8 => cpu_i.byteSelect(1),
        7 downto 0 => cpu_i.byteSelect(0)
    );

    process (clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                -- CODE BELOW IS AUTOMATICALLY GENERATED
words(1) <= x"00_c0_02_3c"; -- RUN lui $2, 0xc000
words(2) <= x"01_c0_03_3c"; -- RUN lui $3, 0xc001
words(3) <= x"00_20_82_44"; -- RUN mtc1 $2, $4
words(4) <= x"00_30_83_44"; -- RUN mtc1 $3, $6
words(5) <= x"01_32_24_46"; -- RUN sub.d $f8, $f6, $f4
words(6) <= x"00_40_04_44"; -- RUN mfc1 $4, $8
words(7) <= x"00_48_05_44"; -- RUN mfc1 $5, $9
words(8) <= x"00_00_00_00"; -- RUN nop
words(9) <= x"08_00_00_08"; -- RUN j 0x20
words(10) <= x"00_00_00_00"; -- RUN nop
            elsif ((cpu_i.enable = '1') and (cpu_i.write = '1')) then
                words(wordAddr) <= (words(wordAddr) and not bitSelect) or (cpu_i.dataSave and bitSelect);
            end if;
        end if;
    end process;

    cpu_o.dataLoad <= words(wordAddr) when (cpu_i.enable = '1') and (cpu_i.write = '0') else 32b"0";
end bhv;