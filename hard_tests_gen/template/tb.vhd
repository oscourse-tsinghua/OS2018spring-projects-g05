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

    signal cpu1Inst_c2d, cpu1Data_c2d, cpu2Inst_c2d, cpu2Data_c2d: BusC2D;
    signal cpu1Inst_d2c, cpu1Data_d2c, cpu2Inst_d2c, cpu2Data_d2c: BusD2C;
    signal ram_c2d, flash_c2d, serial_c2d, boot_c2d, eth_c2d, led_c2d, num_c2d, ipi_c2d: BusC2D;
    signal ram_d2c, flash_d2c, serial_d2c, boot_d2c, eth_d2c, led_d2c, num_d2c, ipi_d2c: BusD2C;

    signal busMon_c2d: BusC2D;
    signal llBit: std_logic;
    signal llLoc: std_logic_vector(AddrWidth);

    signal sync1, sync2: std_logic_vector(2 downto 0);
    signal scCorrect1, scCorrect2: std_logic;

    signal int1, int2: std_logic_vector(IntWidth);
    signal ipiInt: std_logic_vector(1 downto 0);
    signal timerInt1, timerInt2: std_logic;

    {{{CONFIGS}}}
begin
    ram_ist: entity work.{{{TEST_NAME}}}_fake_ram
        port map (
            clk => clk,
            rst => rst,
            cpu_i => ram_c2d,
            cpu_o => ram_d2c
        );

    ipi_ctrl_ist: entity work.ipi_ctrl
        port map (
            clk => clk,
            rst => rst,
            cpu_i => ipi_c2d,
            cpu_o => ipi_d2c,
            int_o => ipiInt
        );

    cpu1_ist: entity work.cpu
        generic map (
            instEntranceAddr        => 32ux"8000_0004",
            exceptBootBaseAddr      => 32ux"8000_0000",
            tlbRefillExl0Offset     => 32ux"40",
            generalExceptOffset     => 32ux"40",
            interruptIv1Offset      => 32ux"40",
            convEndianEnable        => true,
            cpuId                   => (0 => CPU1_ID, others => '0'),
            enableCache             => ENABLE_CACHE,
            scStallPeriods          => 0
        )
        port map (
            rst => rst, clk => clk,
            instDev_i => cpu1Inst_d2c,
            dataDev_i => cpu1Data_d2c,
            instDev_o => cpu1Inst_c2d,
            dataDev_o => cpu1Data_c2d,
            busMon_i => busMon_c2d,
            llBit_i => llBit,
            llLoc_i => llLoc,
            int_i => int1,
            timerInt_o => timerInt1,
            sync_o => sync1,
            scCorrect_i => scCorrect1
        );
    int1 <= (5 => timerInt1, 4 => ipiInt(0), others => '0');

    cpu2_ist: entity work.cpu
        generic map (
            instEntranceAddr        => 32ux"8000_0004",
            exceptBootBaseAddr      => 32ux"8000_0000",
            tlbRefillExl0Offset     => 32ux"40",
            generalExceptOffset     => 32ux"40",
            interruptIv1Offset      => 32ux"40",
            convEndianEnable        => true,
            cpuId                   => (0 => CPU2_ID, others => '0'),
            enableCache             => ENABLE_CACHE,
            scStallPeriods          => 64
        )
        port map (
            rst => rst or not CPU2_ON, clk => clk,
            instDev_i => cpu2Inst_d2c,
            dataDev_i => cpu2Data_d2c,
            instDev_o => cpu2Inst_c2d,
            dataDev_o => cpu2Data_c2d,
            busMon_i => busMon_c2d,
            llBit_i => llBit,
            llLoc_i => llLoc,
            int_i => int2,
            timerInt_o => timerInt2,
            sync_o => sync2,
            scCorrect_i => scCorrect2
        );
    int2 <= (5 => timerInt2, 4 => ipiInt(1), others => '0');

    devctrl_ist: entity work.devctrl
        port map (
            clk => clk,
            rst => rst,

            cpu1Inst_i => cpu1Inst_c2d,
            cpu1Data_i => cpu1Data_c2d,
            cpu1Inst_o => cpu1Inst_d2c,
            cpu1Data_o => cpu1Data_d2c,
            cpu2Inst_i => cpu2Inst_c2d,
            cpu2Data_i => cpu2Data_c2d,
            cpu2Inst_o => cpu2Inst_d2c,
            cpu2Data_o => cpu2Data_d2c,

            ddr3_i => ram_d2c,
            flash_i => flash_d2c,
            serial_i => serial_d2c,
            boot_i => boot_d2c,
            eth_i => eth_d2c,
            led_i => led_d2c,
            num_i => num_d2c,
            ipi_i => ipi_d2c,
            ddr3_o => ram_c2d,
            flash_o => flash_c2d,
            serial_o => serial_c2d,
            boot_o => boot_c2d,
            eth_o => eth_c2d,
            led_o => led_c2d,
            num_o => num_c2d,
            ipi_o => ipi_c2d,

            busMon_o => busMon_c2d,
            llBit_o => llBit,
            llLoc_o => llLoc,

            sync1_i => sync1,
            scCorrect1_o => scCorrect1,
            sync2_i => sync2,
            scCorrect2_o => scCorrect2
    );
    flash_d2c.dataLoad <= (others => '0'); flash_d2c.busy <= PIPELINE_STOP;
    serial_d2c.dataLoad <= (others => '0'); serial_d2c.busy <= PIPELINE_STOP;
    boot_d2c.dataLoad <= (others => '0'); boot_d2c.busy <= PIPELINE_STOP;
    eth_d2c.dataLoad <= (others => '0'); eth_d2c.busy <= PIPELINE_STOP;
    led_d2c.dataLoad <= (others => '0'); led_d2c.busy <= PIPELINE_STOP;
    num_d2c.dataLoad <= (others => '0'); num_d2c.busy <= PIPELINE_STOP;

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
