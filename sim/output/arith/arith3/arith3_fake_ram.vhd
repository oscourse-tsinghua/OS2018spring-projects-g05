-- DO NOT MODIFY THIS FILE.
-- This file is generated by hard_tests_gen

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.arith3_test_const.all;
use work.global_const.all;
use work.bus_const.all;

entity arith3_fake_ram is
    port (
        clk, rst: in std_logic;
        cpu_io: inout BusInterface
    );
end arith3_fake_ram;

architecture bhv of arith3_fake_ram is
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
words(1) <= x"ff_ff_02_28"; -- RUN slti $2, $0, 0xffff
words(2) <= x"ff_ff_02_2c"; -- RUN sltiu $2, $0, 0xffff
words(3) <= x"fe_ff_63_34"; -- RUN ori $3, $3, 0xfffe
words(4) <= x"00_1c_03_00"; -- RUN sll $3, $3, 0x10
words(5) <= x"34_12_84_34"; -- RUN ori $4, $4, 0x1234
words(6) <= x"2a_10_64_00"; -- RUN slt $2, $3, $4
words(7) <= x"2b_10_64_00"; -- RUN sltu $2, $3, $4
words(8) <= x"2a_10_84_00"; -- RUN slt $2, $4, $4
words(9) <= x"2b_10_84_00"; -- RUN sltu $2, $4, $4
            elsif ((cpu_io.enable_c2d = '1') and (cpu_io.write_c2d = '1')) then
                words(wordAddr) <= (words(wordAddr) and not bitSelect) or (cpu_io.dataSave_c2d and bitSelect);
            end if;
        end if;
    end process;

    cpu_io.dataLoad_d2c <= words(wordAddr) when (cpu_io.enable_c2d = '1') and (cpu_io.write_c2d = '0') else 32b"0";
end bhv;
