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

    signal instEnable: std_logic;
    signal instData: std_logic_vector(DataWidth);
    signal instAddr: std_logic_vector(AddrWidth);

    signal dataEnable: std_logic;
    signal dataWrite: std_logic;
    signal dataDataSave: std_logic_vector(DataWidth);
    signal dataDataLoad: std_logic_vector(DataWidth);
    signal dataAddr: std_logic_vector(AddrWidth);
    signal dataByteSelect: std_logic_vector(3 downto 0);

    signal devEnable, devWrite: std_logic;
    signal devDataSave, devDataLoad: std_logic_vector(DataWidth);
    signal devVirtualAddr, devPhysicalAddr: std_logic_vector(AddrWidth);
    signal devByteSelect: std_logic_vector(3 downto 0);

    signal instStall, dataStall: std_logic;
    signal instExcept, dataExcept, devExcept: std_logic_vector(ExceptionCauseWidth);

    signal isKernelMode: std_logic;
    signal entryIndex: std_logic_vector(TLBIndexWidth);
    signal entryWrite: std_logic;
    signal entry: TLBEntry;

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

    mmu_ist: entity work.mmu
        port map (
            clk => clk,
            rst => rst,

            isKernelMode_i => isKernelMode,
            isLoad_i => not devWrite,
            addr_i => devVirtualAddr,
            addr_o => devPhysicalAddr,
            exceptCause_o => devExcept,

            index_i => entryIndex,
            entryWrite_i => entryWrite,
            entry_i => entry
        );

    memctrl_ist: entity work.memctrl
        port map (
            -- Connect to instruction interface of CPU
            instData_o => instData,
            instAddr_i => instAddr,
            instEnable_i => instEnable,
            instStall_o => instStall,
            instExcept_o => instExcept,

            -- Connect to data interface of CPU
            dataEnable_i => dataEnable,
            dataWrite_i => dataWrite,
            dataData_o => dataDataLoad,
            dataData_i => dataDataSave,
            dataAddr_i => dataAddr,
            dataByteSelect_i => dataByteSelect,
            dataStall_o => dataStall,
            dataExcept_o => dataExcept,

            -- Connect to external device (MMU)
            devEnable_o => devEnable,
            devWrite_o => devWrite,
            devData_i => devDataLoad,
            devData_o => devDataSave,
            devAddr_o => devVirtualAddr,
            devByteSelect_o => devByteSelect,
            devBusy_i => PIPELINE_NONSTOP,
            devExcept_i => devExcept
        );

    cpu_ist: entity work.cpu
        generic map (
            instEntranceAddr        => 32ux"8000_0000",
            exceptNormalBaseAddr    => 32ux"8000_0000",
            exceptBootBaseAddr      => 32ux"8000_0000",
            tlbRefillExl0Offset     => 32ux"180",
            generalExceptOffset     => 32ux"180",
            interruptIv1Offset      => 32ux"200",
            instConvEndian          => false
        )
        port map (
            rst => rst,
            clk => clk,
            instEnable_o => instEnable,
            instData_i => instData,
            instAddr_o => instAddr,
            dataEnable_o => dataEnable,
            dataWrite_o => dataWrite,
            dataData_i => dataDataLoad,
            dataData_o => dataDataSave,
            dataAddr_o => dataAddr,
            dataByteSelect_o => dataByteSelect,
            instExcept_i => instExcept,
            dataExcept_i => dataExcept,
            ifToStall_i => instStall,
            memToStall_i => dataStall,
            int_i => int,
            timerInt_o => timerInt,
            isKernelMode_o => isKernelMode,
            entryIndex_o => entryIndex,
            entryWrite_o => entryWrite,
            entry_o => entry
        );

    int <= (0 => timerInt, others => '0');

    process(clk)
        variable testCnt, correctCnt: integer := 0;
        variable tmpTestCnt, nowTestCnt, nowCorrectCnt: integer;
        variable nowDelta: integer := 0;
        alias reg is <<signal cpu_ist.regfile_ist.regArray: RegArrayType>>;
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
