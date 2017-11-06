-- DO NOT MODIFY THIS FILE.
-- This file is generated by hard_tests_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.arith4_test_const.all;
use work.global_const.all;

entity arith4_fake_ram is
    port (
        clk, rst: in std_logic;
        enable_i, write_i: in std_logic;
        data_i: in std_logic_vector(DataWidth);
        addr_i: in std_logic_vector(AddrWidth);
        byteSelect_i: in std_logic_vector(3 downto 0);
        data_o: out std_logic_vector(DataWidth)
    );
end arith4_fake_ram;

architecture bhv of arith4_fake_ram is
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
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                -- CODE BELOW IS AUTOMATICALLY GENERATED
words(1) <= x"34_12_42_34"; -- RUN ori $2, $2, 0x1234
words(2) <= x"67_45_63_34"; -- RUN ori $3, $3, 0x4567
words(3) <= x"02_20_43_70"; -- RUN mul $4, $2, $3
words(4) <= x"bb_bb_04_34"; -- RUN ori $4, $0, 0xbbbb
words(5) <= x"00_24_04_00"; -- RUN sll $4, $4, 0x10
words(6) <= x"bb_bb_84_34"; -- RUN ori $4, $4, 0xbbbb
words(7) <= x"19_00_84_00"; -- RUN multu $4, $4
words(8) <= x"10_28_00_00"; -- RUN mfhi $5
words(9) <= x"12_30_00_00"; -- RUN mflo $6
words(10) <= x"02_38_64_70"; -- RUN mul $7, $3, $4
words(11) <= x"18_00_83_00"; -- RUN mult $4, $3
words(12) <= x"10_28_00_00"; -- RUN mfhi $5
words(13) <= x"12_30_00_00"; -- RUN mflo $6
words(14) <= x"02_18_a4_70"; -- RUN mul $3, $5, $4
words(15) <= x"19_00_a4_00"; -- RUN multu $5, $4
words(16) <= x"10_18_00_00"; -- RUN mfhi $3
            elsif ((enable_i = '1') and (write_i = '1')) then
                words(wordAddr) <= (words(wordAddr) and not bitSelect) or (data_i and bitSelect);
            end if;
        end if;
    end process;

    data_o <= words(wordAddr) when (enable_i = '1') and (write_i = '0') else 32b"0";
end bhv;
