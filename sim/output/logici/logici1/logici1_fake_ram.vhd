-- DO NOT MODIFY THIS FILE.
-- This file is generated by hard_tests_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.logici1_test_const.all;
use work.global_const.all;

entity logici1_fake_ram is
    generic (
        isInst: boolean := false -- The RAM will be initialized with instructions when true
    );
    port (
        enable_i, write_i, clk: in std_logic;
        data_i: in std_logic_vector(DataWidth);
        addr_i: in std_logic_vector(AddrWidth);
        byteSelect_i: in std_logic_vector(3 downto 0);
        data_o: out std_logic_vector(DataWidth)
    );
end logici1_fake_ram;

architecture bhv of logici1_fake_ram is
    type WordsArray is array(0 to MAX_RAM_ADDRESS) of std_logic_vector(DataWidth);
    signal words: WordsArray;
    signal wordAddr: integer;
    signal bitSelect: std_logic_vector(DataWidth);
begin
    wordAddr <= to_integer(unsigned(addr_i(31 downto 2)));

    bitSelect <= (
        31 downto 24 => byteSelect_i(3),
        23 downto 16 => byteSelect_i(2),
        15 downto 8 => byteSelect_i(1),
        7 downto 0 => byteSelect_i(0)
    );

    process (clk) begin
        if (not isInst) then
            if (rising_edge(clk) and (enable_i = '1') and (write_i = '1')) then
                words(wordAddr) <= (words(wordAddr) and not bitSelect) or (data_i and bitSelect);
            end if;
        else
            -- The first instruction is at 0x4
            -- CODE BELOW IS AUTOMATICALLY GENERATED
words(1) <= x"34_12_41_34"; -- RUN ori $1, $2, 0x1234
words(2) <= x"21_89_23_38"; -- RUN xori $3, $1, 0x8921
words(3) <= x"e2_4f_24_30"; -- RUN andi $4, $1, 0x4fe2
words(4) <= x"43_65_25_30"; -- RUN andi $5, $1, 0x6543
words(5) <= x"ef_fe_63_38"; -- RUN xori $3, $3, 0xfeef
words(6) <= x"ff_ff_a0_34"; -- RUN ori $0, $5, 0xffff
words(7) <= x"88_88_03_30"; -- RUN andi $3, $0, 0x8888
words(8) <= x"33_33_02_38"; -- RUN xori $2, $0, 0x3333
words(9) <= x"66_66_01_34"; -- RUN ori $1, $0, 0x6666
        end if;
    end process;

    data_o <= words(wordAddr) when (enable_i = '1') and (write_i = '0') else 32b"0";
end bhv;
