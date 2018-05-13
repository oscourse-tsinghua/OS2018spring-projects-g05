-- DO NOT MODIFY THIS FILE.
-- This file is generated by hard_tests_gen

library ieee;
use ieee.std_logic_1164.all;

use work.tlb_pagemask_test_const.all;
use work.global_const.all;
use work.except_const.all;
use work.mmu_const.all;
-- CODE BELOW IS AUTOMATICALLY GENERATED

entity tlb_pagemask_tb is
end tlb_pagemask_tb;

architecture bhv of tlb_pagemask_tb is
    signal rst: std_logic := '1';
    signal clk: std_logic := '0';

    signal devEnable, devWrite: std_logic;
    signal devDataSave, devDataLoad: std_logic_vector(DataWidth);
    signal devPhysicalAddr: std_logic_vector(AddrWidth);
    signal devByteSelect: std_logic_vector(3 downto 0);

    signal int: std_logic_vector(IntWidth);
    signal timerInt: std_logic;
begin
    ram_ist: entity work.tlb_pagemask_fake_ram
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
            exceptBootBaseAddr      => 32ux"8000_0000",
            tlbRefillExl0Offset     => 32ux"40",
            generalExceptOffset     => 32ux"40",
            interruptIv1Offset      => 32ux"40",
            convEndianEnable        => true
        )
        port map (
            rst => rst, clk => clk,
            devEnable_o => devEnable,
            devBusy_i => PIPELINE_NONSTOP,
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
        -- CODE BELOW IS AUTOMATICALLY GENERATED
alias user_reg is <<signal ^.cpu_ist.datapath_ist.regfile_ist.regArray: RegArrayType>>;
    begin
        -- CODE BELOW IS AUTOMATICALLY GENERATED
process begin
    wait for CLK_PERIOD; -- resetting
    wait for 23 * CLK_PERIOD;
    assert user_reg(23) = 32ux"00000000" severity FAILURE;
    wait;
end process;
process begin
    wait for CLK_PERIOD; -- resetting
    wait for 23 * CLK_PERIOD;
    assert user_reg(7) = 32ux"1fffe000" severity FAILURE;
    wait;
end process;
    end block assertBlk;
end bhv;
