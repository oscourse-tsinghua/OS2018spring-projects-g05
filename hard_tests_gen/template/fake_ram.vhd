{{{NOTICE}}}

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.{{{TEST_NAME}}}_test_const.all;
use work.global_const.all;

entity {{{TEST_NAME}}}_fake_ram is
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
end {{{TEST_NAME}}}_fake_ram;

architecture bhv of {{{TEST_NAME}}}_fake_ram is
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
                words(wordAddr) <= (words(wordAddr) xnor bitSelect) and (data_i xor bitSelect);
            end if;
        else
            -- The first instruction is at 0x4
            {{{INIT_INST_RAM}}}
        end if;
    end process;

    data_o <= words(wordAddr) when (enable_i = '1') and (write_i = '0') else 32b"0";
end bhv;
