-- DO NOT MODIFY THIS FILE.
-- This file is generated by hard_tests_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tlb_tlbp_test_const.all;
use work.global_const.all;
use work.bus_const.all;

entity tlb_tlbp_fake_ram is
    port (
        clk, rst: in std_logic;
        cpu_io: inout BusInterface
    );
end tlb_tlbp_fake_ram;

architecture bhv of tlb_tlbp_fake_ram is
    type WordsArray is array(0 to MAX_RAM_ADDRESS) of std_logic_vector(DataWidth);
    signal words: WordsArray;
    signal wordAddr: integer;
    signal bitSelect: std_logic_vector(DataWidth);
    signal llBit: std_logic;
    signal llLoc: std_logic_vector(AddrWidth);
begin
    cpu_io.busy_d2c <= PIPELINE_NONSTOP;

    wordAddr <= to_integer(unsigned(cpu_io.addr_c2d(11 downto 2)));

    bitSelect <= (
        31 downto 24 => cpu_io.byteSelect_c2d(3),
        23 downto 16 => cpu_io.byteSelect_c2d(2),
        15 downto 8 => cpu_io.byteSelect_c2d(1),
        7 downto 0 => cpu_io.byteSelect_c2d(0)
    );

    process (clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                -- CODE BELOW IS AUTOMATICALLY GENERATED
words(1) <= x"01_00_04_34"; -- RUN ori $4, $0, 0x1
words(2) <= x"02_00_05_34"; -- RUN ori $5, $0, 0x2
words(3) <= x"23_01_06_3c"; -- RUN lui $6, 0x0123
words(4) <= x"67_45_07_3c"; -- RUN lui $7, 0x4567
words(5) <= x"ab_89_08_3c"; -- RUN lui $8, 0x89ab
words(6) <= x"00_50_86_40"; -- RUN mtc0 $6, $10
words(7) <= x"00_00_80_40"; -- RUN mtc0 $0, $0
words(8) <= x"00_00_00_00"; -- RUN nop
words(9) <= x"00_00_00_00"; -- RUN nop
words(10) <= x"02_00_00_42"; -- RUN tlbwi
words(11) <= x"00_50_87_40"; -- RUN mtc0 $7, $10
words(12) <= x"00_00_84_40"; -- RUN mtc0 $4, $0
words(13) <= x"00_00_00_00"; -- RUN nop
words(14) <= x"00_00_00_00"; -- RUN nop
words(15) <= x"02_00_00_42"; -- RUN tlbwi
words(16) <= x"00_50_88_40"; -- RUN mtc0 $8, $10
words(17) <= x"00_00_85_40"; -- RUN mtc0 $5, $0
words(18) <= x"00_00_00_00"; -- RUN nop
words(19) <= x"00_00_00_00"; -- RUN nop
words(20) <= x"02_00_00_42"; -- RUN tlbwi
words(21) <= x"00_50_87_40"; -- RUN mtc0 $7, $10
words(22) <= x"00_00_00_00"; -- RUN nop
words(23) <= x"00_00_00_00"; -- RUN nop
words(24) <= x"00_00_00_00"; -- RUN nop
words(25) <= x"08_00_00_42"; -- RUN tlbp
words(26) <= x"00_00_00_00"; -- RUN nop
words(27) <= x"00_00_00_00"; -- RUN nop
words(28) <= x"00_00_0a_40"; -- RUN MFC0 $10, $0
words(29) <= x"ff_ff_09_3c"; -- RUN lui $9, 0xffff
words(30) <= x"00_50_89_40"; -- RUN mtc0 $9, $10
words(31) <= x"00_00_00_00"; -- RUN nop
words(32) <= x"00_00_00_00"; -- RUN nop
words(33) <= x"00_00_00_00"; -- RUN nop
words(34) <= x"08_00_00_42"; -- RUN tlbp
words(35) <= x"00_00_00_00"; -- RUN nop
words(36) <= x"00_00_00_00"; -- RUN nop
words(37) <= x"00_00_0a_40"; -- RUN MFC0 $10, $0
            elsif ((cpu_io.enable_c2d = '1') and (cpu_io.write_c2d = '1')) then
                words(wordAddr) <= (words(wordAddr) and not bitSelect) or (cpu_io.dataSave_c2d and bitSelect);
            end if;
        end if;
    end process;

    cpu_io.dataLoad_d2c <= words(wordAddr) when (cpu_io.enable_c2d = '1') and (cpu_io.write_c2d = '0') else 32b"0";
end bhv;
