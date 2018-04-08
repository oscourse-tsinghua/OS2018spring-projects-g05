-- DO NOT MODIFY THIS FILE.
-- This file is generated by hard_tests_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.logic1_test_const.all;
use work.global_const.all;

entity logic1_fake_ram is
    port (
        clk, rst: in std_logic;
        enable_i, write_i: in std_logic;
        data_i: in std_logic_vector(DataWidth);
        addr_i: in std_logic_vector(AddrWidth);
        byteSelect_i: in std_logic_vector(3 downto 0);
        data_o: out std_logic_vector(DataWidth)
    );
end logic1_fake_ram;

architecture bhv of logic1_fake_ram is
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
words(1) <= x"00_12_03_34"; -- RUN ori $3, $0, 0x1200
words(2) <= x"f2_00_63_34"; -- RUN ori $3, $3, 0x00f2
words(3) <= x"de_30_02_34"; -- RUN ori $2, $0, 0x30de
words(4) <= x"25_30_43_00"; -- RUN or $6, $2, $3
words(5) <= x"26_28_43_00"; -- RUN xor $5, $2, $3
words(6) <= x"27_38_43_00"; -- RUN nor $7, $2, $3
            elsif ((enable_i = '1') and (write_i = '1')) then
                words(wordAddr) <= (words(wordAddr) and not bitSelect) or (data_i and bitSelect);
            end if;
        end if;
    end process;

    data_o <= words(wordAddr) when (enable_i = '1') and (write_i = '0') else 32b"0";
end bhv;
