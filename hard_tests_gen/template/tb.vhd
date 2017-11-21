{{{NOTICE}}}

library ieee;
use ieee.std_logic_1164.all;

use work.{{{TEST_NAME}}}_test_const.all;
use work.global_const.all;
use work.except_const.all;
use work.mmu_const.all;
{{{IMPORT}}}

entity {{{TEST_NAME}}}_tb is
end {{{TEST_NAME}}}_tb;

architecture bhv of {{{TEST_NAME}}}_tb is
    signal rst: std_logic := '1';
    signal clk: std_logic := '0';

    signal devEnable, devWrite: std_logic;
    signal devDataSave, devDataLoad: std_logic_vector(DataWidth);
    signal devPhysicalAddr: std_logic_vector(AddrWidth);
    signal devByteSelect: std_logic_vector(3 downto 0);

    signal int: std_logic_vector(IntWidth);
    signal timerInt: std_logic;
begin
    ram_ist: entity work.{{{TEST_NAME}}}_fake_ram
        port map (
            clk => clk,
            rst => rst,
            enable_i => devEnable,
            write_i => devWrite,
            data_i => devDataSave,
            addr_i => devPhysicalAddr,
            byteSelect_i => devByteSelect,
            data_o => devDataLoad
        );

    cpu_ist: entity work.cpu
        generic map (
            instEntranceAddr        => 32ux"8000_0004",
            exceptNormalBaseAddr    => 32ux"8000_0000",
            exceptBootBaseAddr      => 32ux"8000_0000",
            tlbRefillExl0Offset     => 32ux"40",
            generalExceptOffset     => 32ux"40",
            interruptIv1Offset      => 32ux"40",
            instConvEndian          => true
        ) 
        port map (
            rst => rst, clk => clk,
            devEnable_o => devEnable,
            devWrite_o => devWrite,
            devDataSave_o => devDataSave,
            devDataLoad_i => devDataLoad,
            devPhysicalAddr_o => devPhysicalAddr,
            devByteSelect_o => devByteSelect,

            int_i => int,
            timerInt_o => timerInt
        );
    int <= (0 => timerInt, others => '0');

    process begin
        wait for CLK_PERIOD / 2;
        clk <= not clk;
    end process;

    process begin
        -- begin reset
        wait for CLK_PERIOD;
        rst <= '0';
        wait;
    end process;

    assertBlk: block
        -- NOTE: `assertBlk` is also a layer in the herarchical reference
        {{{ALIASES}}}
    begin
        {{{ASSERTIONS}}}
    end block assertBlk;
end bhv;
