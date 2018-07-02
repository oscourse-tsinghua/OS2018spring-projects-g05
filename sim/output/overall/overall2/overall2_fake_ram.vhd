-- DO NOT MODIFY THIS FILE.
-- This file is generated by hard_tests_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.overall2_test_const.all;
use work.global_const.all;
use work.bus_const.all;

entity overall2_fake_ram is
    port (
        clk, rst: in std_logic;
        cpu_io: inout BusInterface;
        sync_i: in std_logic_vector(2 downto 0);
        scCorrect_o: out std_logic
    );
end overall2_fake_ram;

architecture bhv of overall2_fake_ram is
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
words(1) <= x"00_80_0a_3c"; -- RUN lui $10, 0x8000
words(2) <= x"01_00_63_34"; -- RUN ori $3, $3, 1
words(3) <= x"01_00_44_35"; -- RUN ori $4, $10, 1
words(4) <= x"00_00_83_ac"; -- RUN sw $3, 0($4)
words(5) <= x"08_00_00_0c"; -- RUN jal 0x20
words(6) <= x"00_00_00_00"; -- RUN nop
words(7) <= x"01_00_29_21"; -- RUN addi $9, $9, 1
words(8) <= x"00_00_00_34"; -- RUN ori $0, $0, 0
            elsif ((cpu_io.enable_c2d = '1') and (cpu_io.write_c2d = '1')) then
                words(wordAddr) <= (words(wordAddr) and not bitSelect) or (cpu_io.dataSave_c2d and bitSelect);
            end if;
        end if;
    end process;

    scCorrect_o <= llBit when cpu_io.addr_c2d = llLoc else '0';

    process(clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                llBit <= '0';
                llLoc <= (others => 'X');
            else
                if (sync_i(0) = '1') then -- LL
                    llBit <= '1';
                    llLoc <= cpu_io.addr_c2d;
                elsif (sync_i(1) = '1') then -- SC
                    llBit <= '0';
                elsif (cpu_io.addr_c2d = llLoc) then -- Others
                    llBit <= '0';
                end if;
                if (sync_i(2) = '1') then -- Flush
                    llBit <= '0';
                end if;
            end if;
        end if;
    end process;

    cpu_io.dataLoad_d2c <= words(wordAddr) when (cpu_io.enable_c2d = '1') and (cpu_io.write_c2d = '0') else 32b"0";
end bhv;
