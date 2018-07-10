{{{NOTICE}}}

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.{{{TEST_NAME}}}_test_const.all;
use work.global_const.all;
use work.bus_const.all;

entity {{{TEST_NAME}}}_fake_ram is
    port (
        clk, rst: in std_logic;
        cpu_i: in BusC2D;
        cpu_o: out BusD2C
    );
end {{{TEST_NAME}}}_fake_ram;

architecture bhv of {{{TEST_NAME}}}_fake_ram is
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
                {{{INIT_INST_RAM}}}
            elsif ((cpu_i.enable = '1') and (cpu_i.write = '1')) then
                words(wordAddr) <= (words(wordAddr) and not bitSelect) or (cpu_i.dataSave and bitSelect);
            end if;
        end if;
    end process;

    cpu_o.dataLoad <= words(wordAddr) when (cpu_i.enable = '1') and (cpu_i.write = '0') else 32b"0";
end bhv;
