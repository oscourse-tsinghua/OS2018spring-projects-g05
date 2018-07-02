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

    signal conn: BusInterface;
    signal sync: std_logic_vector(2 downto 0);
    signal scCorrect: std_logic;

    signal int: std_logic_vector(IntWidth);
    signal timerInt: std_logic;
begin
    ram_ist: entity work.{{{TEST_NAME}}}_fake_ram
        port map (
            clk => clk,
            rst => rst,
            cpu_io => conn,
            scCorrect_o => scCorrect,
            sync_i => sync
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
            dev_io => conn,
            int_i => int,
            timerInt_o => timerInt,
            sync_o => sync,
            scCorrect_i => scCorrect
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
