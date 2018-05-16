-- DO NOT MODIFY THIS FILE.
-- This file is generated by hard_tests_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.logic3_test_const.all;
use work.global_const.all;

entity logic3_fake_ram is
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
end logic3_fake_ram;

architecture bhv of logic3_fake_ram is
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
words(1) <= x"00_f2_03_34"; -- RUN ori $3, $0, 0xf200
words(2) <= x"10_00_02_34"; -- RUN ori $2, $0, 0x0010
words(3) <= x"00_24_03_00"; -- RUN sll $4, $3, 0x10
words(4) <= x"02_2c_04_00"; -- RUN srl $5, $4, 0x10
words(5) <= x"03_2c_04_00"; -- RUN sra $5, $4, 0x10
words(6) <= x"04_20_43_00"; -- RUN sllv $4, $3, $2
words(7) <= x"06_28_44_00"; -- RUN srlv $5, $4, $2
words(8) <= x"07_28_44_00"; -- RUN srav $5, $4, $2
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
