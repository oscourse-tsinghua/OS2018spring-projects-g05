-- DO NOT MODIFY THIS FILE.
-- This file is generated by hard_tests_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tlb_pagemask_test_const.all;
use work.global_const.all;

entity tlb_pagemask_fake_ram is
    port (
        clk, rst: in std_logic;
        enable_i, write_i: in std_logic;
        data_i: in std_logic_vector(DataWidth);
        addr_i: in std_logic_vector(AddrWidth);
        byteSelect_i: in std_logic_vector(3 downto 0);
        data_o: out std_logic_vector(DataWidth)
    );
end tlb_pagemask_fake_ram;

architecture bhv of tlb_pagemask_fake_ram is
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
words(1) <= x"07_00_42_34"; -- RUN ori $2, 0x07
words(2) <= x"00_18_82_40"; -- RUN mtc0 $2, $3
words(3) <= x"00_10_82_40"; -- RUN mtc0 $2, $2
words(4) <= x"06_00_00_42"; -- RUN tlbwr
words(5) <= x"04_00_01_3c"; -- RUN lui $1, 0x4
words(6) <= x"ff_ff_06_3c"; -- RUN lui $6, 0xffff
words(7) <= x"ff_ff_c6_34"; -- RUN ori $6, 0xffff
words(8) <= x"00_28_86_40"; -- RUN mtc0 $6, $5, 0
words(9) <= x"00_00_00_00"; -- RUN nop
words(10) <= x"00_28_07_40"; -- RUN mfc0 $7, $5, 0
words(11) <= x"08_00_22_ac"; -- RUN sw $2, 0x8($1)
words(12) <= x"00_00_00_00"; -- RUN nop
words(13) <= x"00_00_00_00"; -- RUN nop
words(14) <= x"0c_00_00_08"; -- RUN j 0x030
words(15) <= x"00_00_00_00"; -- RUN nop
words(16) <= x"ff_ff_17_34"; -- RUN ori $23, $0, 0xffff
            elsif ((enable_i = '1') and (write_i = '1')) then
                words(wordAddr) <= (words(wordAddr) and not bitSelect) or (data_i and bitSelect);
            end if;
        end if;
    end process;

    data_o <= words(wordAddr) when (enable_i = '1') and (write_i = '0') else 32b"0";
end bhv;
