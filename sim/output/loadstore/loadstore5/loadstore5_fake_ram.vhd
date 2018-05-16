-- DO NOT MODIFY THIS FILE.
-- This file is generated by hard_tests_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.loadstore5_test_const.all;
use work.global_const.all;

entity loadstore5_fake_ram is
    port (
        clk, rst: in std_logic;
        enable_i, write_i: in std_logic;
        data_i: in std_logic_vector(DataWidth);
        addr_i: in std_logic_vector(AddrWidth);
        byteSelect_i: in std_logic_vector(3 downto 0);
        data_o: out std_logic_vector(DataWidth);
        sync_i: in std_logic_vector(2 downto 0);
        scCorrect_o: out std_logic
    );
end loadstore5_fake_ram;

architecture bhv of loadstore5_fake_ram is
    type WordsArray is array(0 to MAX_RAM_ADDRESS) of std_logic_vector(DataWidth);
    signal words: WordsArray;
    signal wordAddr: integer;
    signal bitSelect: std_logic_vector(DataWidth);
    signal llBit: std_logic;
    signal llLoc: std_logic_vector(AddrWidth);
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
words(1) <= x"00_80_0a_3c"; -- RUN lui $10, 0x8000
words(2) <= x"ff_ff_03_3c"; -- RUN lui $3, 0xffff
words(3) <= x"ff_ff_63_34"; -- RUN ori $3, $3, 0xffff
words(4) <= x"23_01_04_3c"; -- RUN lui $4, 0x0123
words(5) <= x"67_45_84_34"; -- RUN ori $4, $4, 0x4567
words(6) <= x"ab_89_05_3c"; -- RUN lui $5, 0x89ab
words(7) <= x"ef_cd_a5_34"; -- RUN ori $5, $5, 0xcdef
words(8) <= x"00_01_43_ad"; -- RUN sw $3, 0x100($10)
words(9) <= x"04_01_43_ad"; -- RUN sw $3, 0x104($10)
words(10) <= x"00_01_44_b9"; -- RUN swr $4, 0x100($10)
words(11) <= x"07_01_45_a9"; -- RUN swl $5, 0x107($10)
words(12) <= x"00_01_46_8d"; -- RUN lw $6, 0x100($10)
words(13) <= x"04_01_47_8d"; -- RUN lw $7, 0x104($10)
words(14) <= x"00_01_43_ad"; -- RUN sw $3, 0x100($10)
words(15) <= x"04_01_43_ad"; -- RUN sw $3, 0x104($10)
words(16) <= x"01_01_44_b9"; -- RUN swr $4, 0x101($10)
words(17) <= x"04_01_45_a9"; -- RUN swl $5, 0x104($10)
words(18) <= x"00_01_46_8d"; -- RUN lw $6, 0x100($10)
words(19) <= x"04_01_47_8d"; -- RUN lw $7, 0x104($10)
words(20) <= x"00_01_43_ad"; -- RUN sw $3, 0x100($10)
words(21) <= x"04_01_43_ad"; -- RUN sw $3, 0x104($10)
words(22) <= x"02_01_44_b9"; -- RUN swr $4, 0x102($10)
words(23) <= x"05_01_45_a9"; -- RUN swl $5, 0x105($10)
words(24) <= x"00_01_46_8d"; -- RUN lw $6, 0x100($10)
words(25) <= x"04_01_47_8d"; -- RUN lw $7, 0x104($10)
words(26) <= x"00_01_43_ad"; -- RUN sw $3, 0x100($10)
words(27) <= x"04_01_43_ad"; -- RUN sw $3, 0x104($10)
words(28) <= x"03_01_44_b9"; -- RUN swr $4, 0x103($10)
words(29) <= x"06_01_45_a9"; -- RUN swl $5, 0x106($10)
words(30) <= x"00_01_46_8d"; -- RUN lw $6, 0x100($10)
words(31) <= x"04_01_47_8d"; -- RUN lw $7, 0x104($10)
            elsif ((enable_i = '1') and (write_i = '1')) then
                words(wordAddr) <= (words(wordAddr) and not bitSelect) or (data_i and bitSelect);
            end if;
        end if;
    end process;

    process(clk) begin
        if (falling_edge(clk)) then
            scCorrect_o <= '0';
            if (sync_i(0) = '1') then
                llBit <= '1';
                llLoc <= addr_i;
            elsif (sync_i(1) = '1' and llBit = '1') then
                if (addr_i = llLoc) then
                    scCorrect_o <= '1';
                    llBit <= '0';
                end if;
            elsif (addr_i = llLoc) then
                llBit <= '0';
            end if;
            if (sync_i(2) = '1') then
                llBit <= '0';
            end if;
        end if;
    end process;

    data_o <= words(wordAddr) when (enable_i = '1') and (write_i = '0') else 32b"0";
end bhv;
