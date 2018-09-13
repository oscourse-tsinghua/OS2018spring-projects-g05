-- DO NOT MODIFY THIS FILE.
-- This file is generated by hard_tests_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.bc1f_ge_test_const.all;
use work.global_const.all;
use work.bus_const.all;

entity bc1f_ge_fake_ram is
    port (
        clk, rst: in std_logic;
        cpu_i: in BusC2D;
        cpu_o: out BusD2C
    );
end bc1f_ge_fake_ram;

architecture bhv of bc1f_ge_fake_ram is
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
words(1) <= x"00_c0_03_3c"; -- RUN lui $3, 0xc000
words(2) <= x"01_c0_04_3c"; -- RUN lui $4, 0xc001
words(3) <= x"00_10_83_44"; -- RUN mtc1 $3, $2
words(4) <= x"00_20_84_44"; -- RUN mtc1 $4, $4
words(5) <= x"3c_10_24_46"; -- RUN c.lt.d $f2, $f4
words(6) <= x"04_00_01_45"; -- RUN bc1t 0x0010
words(7) <= x"00_00_00_00"; -- RUN nop
words(8) <= x"cc_cc_06_34"; -- RUN ori $6, $0, 0xcccc
words(9) <= x"00_00_00_00"; -- RUN nop
words(10) <= x"00_00_00_00"; -- RUN nop
words(11) <= x"00_00_00_00"; -- RUN nop
words(12) <= x"00_00_00_00"; -- RUN nop
words(13) <= x"00_00_00_00"; -- RUN nop
words(14) <= x"00_00_00_00"; -- RUN nop
words(15) <= x"00_00_00_00"; -- RUN nop
words(16) <= x"00_00_00_00"; -- RUN nop
words(17) <= x"00_00_00_00"; -- RUN nop
words(18) <= x"00_00_00_00"; -- RUN nop
words(19) <= x"00_00_00_00"; -- RUN nop
words(20) <= x"00_00_00_00"; -- RUN nop
words(21) <= x"14_00_00_08"; -- RUN j 0x50
words(22) <= x"00_00_00_00"; -- RUN nop
            elsif ((cpu_i.enable = '1') and (cpu_i.write = '1')) then
                words(wordAddr) <= (words(wordAddr) and not bitSelect) or (cpu_i.dataSave and bitSelect);
            end if;
        end if;
    end process;

    cpu_o.dataLoad <= words(wordAddr) when (cpu_i.enable = '1') and (cpu_i.write = '0') else 32b"0";
end bhv;
