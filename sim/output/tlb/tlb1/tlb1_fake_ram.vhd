-- DO NOT MODIFY THIS FILE.
-- This file is generated by hard_tests_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tlb1_test_const.all;
use work.global_const.all;

entity tlb1_fake_ram is
    port (
        clk, rst: in std_logic;
        enable_i, write_i: in std_logic;
        data_i: in std_logic_vector(DataWidth);
        addr_i: in std_logic_vector(AddrWidth);
        byteSelect_i: in std_logic_vector(3 downto 0);
        data_o: out std_logic_vector(DataWidth)
    );
end tlb1_fake_ram;

architecture bhv of tlb1_fake_ram is
    type WordsArray is array(0 to MAX_RAM_ADDRESS) of std_logic_vector(DataWidth);
    signal words: WordsArray;
    signal wordAddr: integer;
    signal bitSelect: std_logic_vector(DataWidth);
begin
    wordAddr <= to_integer(unsigned(addr_i(RAM_ADDR_WIDTH + 2 - 1 downto 2)));

    bitSelect <= (
        31 downto 24 => byteSelect_i(3),
        23 downto 16 => byteSelect_i(2),
        15 downto 8 => byteSelect_i(1),
        7 downto 0 => byteSelect_i(0)
    );

    process (clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                -- CODE BELOW IS AUTOMATICALLY GENERATED
words(1) <= x"00_80_0a_3c"; -- RUN lui $10, 0x8000
words(2) <= x"34_12_63_34"; -- RUN ori $3, 0x1234
words(3) <= x"00_71_03_ac"; -- RUN sw  $3, 0x7100($0)
words(4) <= x"00_01_44_8d"; -- RUN lw  $4, 0x0100($10)
words(5) <= x"00_00_00_00"; -- RUN nop
words(6) <= x"00_00_00_00"; -- RUN nop
words(7) <= x"00_00_00_00"; -- RUN nop
words(8) <= x"00_00_00_00"; -- RUN nop
words(9) <= x"00_00_00_00"; -- RUN nop
words(10) <= x"00_00_00_00"; -- RUN nop
words(11) <= x"00_00_00_00"; -- RUN nop
words(12) <= x"00_00_00_00"; -- RUN nop
words(13) <= x"00_00_00_00"; -- RUN nop
words(14) <= x"40_00_00_08"; -- RUN j 0x100
words(15) <= x"00_00_00_00"; -- RUN nop
words(16) <= x"00_40_04_40"; -- RUN mfc0 $4, $8
words(17) <= x"00_50_04_40"; -- RUN mfc0 $4, $10
words(18) <= x"07_00_c6_34"; -- RUN ori $6, 0x07
words(19) <= x"00_18_86_40"; -- RUN mtc0 $6, $3
words(20) <= x"47_00_c6_34"; -- RUN ori $6, 0x47
words(21) <= x"00_10_86_40"; -- RUN mtc0 $6, $2
words(22) <= x"06_00_00_42"; -- RUN tlbwr
words(23) <= x"18_00_00_42"; -- RUN eret
            elsif ((enable_i = '1') and (write_i = '1')) then
                words(wordAddr) <= (words(wordAddr) and not bitSelect) or (data_i and bitSelect);
            end if;
        end if;
    end process;

    data_o <= words(wordAddr) when (enable_i = '1') and (write_i = '0') else 32b"0";
end bhv;
