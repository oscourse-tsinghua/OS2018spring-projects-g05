{{{NOTICE}}}

library ieee;
use ieee.std_logic_1164.all;

use work.{{{TEST_NAME}}}_test_const.all;
use work.global_const.all;
use work.except_const.all;
use work.mmu_const.all;
use work.bus_const.all;
{{{IMPORT}}}

entity {{{TEST_NAME}}}_tb is
end {{{TEST_NAME}}}_tb;

architecture bhv of {{{TEST_NAME}}}_tb is
    signal rst: std_logic := '1';
    signal clk: std_logic := '0';

    signal cpu1InstBus, cpu1DataBus: BusInterface;
    signal ramBus, flashBus, serialBus, bootBus, ethBus, ledBus, numBus: BusInterface;

    signal sync: std_logic_vector(2 downto 0);
    signal scCorrect: std_logic;

    signal int: std_logic_vector(IntWidth);
    signal timerInt: std_logic;
begin
    ram_ist: entity work.{{{TEST_NAME}}}_fake_ram
        port map (
            clk => clk,
            rst => rst,
            cpu_io => ramBus
        );

    cpu_ist: entity work.cpu
        generic map (
            instEntranceAddr        => 32ux"8000_0004",
            exceptBootBaseAddr      => 32ux"8000_0000",
            tlbRefillExl0Offset     => 32ux"40",
            generalExceptOffset     => 32ux"40",
            interruptIv1Offset      => 32ux"40",
            convEndianEnable        => true
        )
        port map (
            rst => rst, clk => clk,
            instDev_io => cpu1InstBus,
            dataDev_io => cpu1DataBus,
            int_i => int,
            timerInt_o => timerInt,
            sync_o => sync,
            scCorrect_i => scCorrect
        );
    int <= (0 => timerInt, others => '0');

    devctrl_ist: entity work.devctrl
        port map (
            clk => clk,
            rst => rst,

            cpu1Inst_io => cpu1InstBus,
            cpu1Data_io => cpu1DataBus,

            ddr3_io => ramBus,
            flash_io => flashBus,
            serial_io => serialBus,
            boot_io => bootBus,
            eth_io => ethBus,
            led_io => ledBus,
            num_io => numBus,

            sync_i => sync,
            scCorrect_o => scCorrect
    );
    flashBus.dataLoad_d2c <= (others => '0'); flashBus.busy_d2c <= PIPELINE_STOP;
    serialBus.dataLoad_d2c <= (others => '0'); serialBus.busy_d2c <= PIPELINE_STOP;
    bootBus.dataLoad_d2c <= (others => '0'); bootBus.busy_d2c <= PIPELINE_STOP;
    ethBus.dataLoad_d2c <= (others => '0'); ethBus.busy_d2c <= PIPELINE_STOP;
    ledBus.dataLoad_d2c <= (others => '0'); ledBus.busy_d2c <= PIPELINE_STOP;
    numBus.dataLoad_d2c <= (others => '0'); numBus.busy_d2c <= PIPELINE_STOP;

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
