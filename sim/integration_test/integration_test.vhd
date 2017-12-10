library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.global_const.all;
use work.except_const.all;
use work.mmu_const.all;
use work.integration_test_const.all;

entity integration_test is
end integration_test;

architecture bhv of integration_test is

    signal rst: std_logic := '1';
    signal clk: std_logic := '0';
    signal ramClk: std_logic;

    signal devEnable, devWrite: std_logic;
    signal devDataSave, devDataLoad: std_logic_vector(DataWidth);
    signal devPhysicalAddr: std_logic_vector(AddrWidth);
    signal devByteSelect: std_logic_vector(3 downto 0);

    signal int: std_logic_vector(IntWidth);
    signal timerInt: std_logic;

    signal judgeRes: std_logic;

begin

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

    ramClk <= clk after 0.1 ns;
    ram_ist: entity work.ram
        port map (
            clka => ramClk,
            ena => devEnable,
            wea => devByteSelect and (devWrite & devWrite & devWrite & devWrite),
            dina => devDataSave,
            addra => devPhysicalAddr(RamAddrSliceWidth),
            douta => devDataLoad
        );

    cpu_ist: entity work.cpu
        generic map (
            instEntranceAddr        => 32ux"8000_0000",
            exceptBootBaseAddr      => 32ux"8000_0000",
            tlbRefillExl0Offset     => 32ux"180",
            generalExceptOffset     => 32ux"180",
            interruptIv1Offset      => 32ux"200"
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

    process(clk)
        variable testCnt, correctCnt: integer := 0;
        variable tmpTestCnt, nowTestCnt, nowCorrectCnt: integer;
        variable nowDelta: integer := 0;
        alias reg is <<signal cpu_ist.datapath_ist.regfile_ist.regArray: RegArrayType>>;
    begin
        if (falling_edge(clk)) then
            tmpTestCnt := conv_integer(reg(23));
            if (tmpTestCnt > testCnt) then
                nowTestCnt := tmpTestCnt;
                nowCorrectCnt := conv_integer(reg(19));
                if (nowTestCnt - nowCorrectCnt > nowDelta) then
                    judgeRes <= '0';
                    report "test " & integer'image(nowTestCnt) & " failed";
                else
                    judgeRes <= '1';
                    report "test " & integer'image(nowTestCnt) & " passed";
                end if;
                testCnt := nowTestCnt;
                correctCnt := nowCorrectCnt;
                nowDelta := nowTestCnt - nowCorrectCnt;
            end if;
        end if;
    end process;

end bhv;
