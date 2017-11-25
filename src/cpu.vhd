library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.except_const.all;
use work.mmu_const.all;

entity cpu is
    generic (
        instEntranceAddr: std_logic_vector(AddrWidth) := 32ux"bfc0_0000";
        exceptNormalBaseAddr: std_logic_vector(AddrWidth) := 32ux"8000_0000";
        exceptBootBaseAddr: std_logic_vector(AddrWidth) := 32ux"bfc0_0200";
        tlbRefillExl0Offset: std_logic_vector(AddrWidth) := 32ux"000";
        generalExceptOffset: std_logic_vector(AddrWidth) := 32ux"180";
        interruptIv1Offset: std_logic_vector(AddrWidth) := 32ux"200";
        convEndianEnable: boolean := false
    );
    port (
        clk, rst: in std_logic;

        devEnable_o, devWrite_o: out std_logic;
        devBusy_i: in std_logic;
        devDataSave_o: out std_logic_vector(DataWidth);
        devDataLoad_i: in std_logic_vector(DataWidth);
        devPhysicalAddr_o: out std_logic_vector(AddrWidth);
        devByteSelect_o: out std_logic_vector(3 downto 0);

        int_i: in std_logic_vector(IntWidth);
        timerInt_o: out std_logic
    );
end cpu;

architecture bhv of cpu is

    signal instEnable: std_logic;
    signal instData: std_logic_vector(DataWidth);
    signal instAddr: std_logic_vector(AddrWidth);

    signal dataEnable: std_logic;
    signal dataWrite: std_logic;
    signal dataDataSave: std_logic_vector(DataWidth);
    signal dataDataLoad: std_logic_vector(DataWidth);
    signal dataAddr: std_logic_vector(AddrWidth);
    signal dataByteSelect: std_logic_vector(3 downto 0);

    signal mmuEnable: std_logic;
    signal devWrite: std_logic;
    signal devVirtualAddr: std_logic_vector(AddrWidth);

    signal instStall, dataStall: std_logic;
    signal instExcept, dataExcept, devExcept: std_logic_vector(ExceptionCauseWidth);

    signal isKernelMode: std_logic;
    signal entryIndex: std_logic_vector(TLBIndexWidth);
    signal entryWrite: std_logic;
    signal entry: TLBEntry;

    signal dataLoadConv, dataSaveConv: std_logic_vector(DataWidth);

begin
    conv_endian_load: entity work.conv_endian
        generic map (
            enable => convEndianEnable
        )
        port map (
            input => devDataLoad_i,
            output => dataLoadConv
        );
    conv_endian_save: entity work.conv_endian
        generic map (
            enable => convEndianEnable
        )
        port map (
            input => dataSaveConv,
            output => devDataSave_o
        );

    devWrite_o <= devWrite;

    mmu_ist: entity work.mmu
        port map (
            clk => clk,
            rst => rst,

            enable_i => mmuEnable,
            isKernelMode_i => isKernelMode,
            isLoad_i => not devWrite,
            addr_i => devVirtualAddr,
            addr_o => devPhysicalAddr_o,
            enable_o => devEnable_o,
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
            devEnable_o => mmuEnable,
            devWrite_o => devWrite,
            devData_i => dataLoadConv,
            devData_o => dataSaveConv,
            devAddr_o => devVirtualAddr,
            devByteSelect_o => devByteSelect_o,
            devBusy_i => devBusy_i,
            devExcept_i => devExcept
        );

    datapath_ist: entity work.datapath
        generic map (
            instEntranceAddr        => instEntranceAddr,
            exceptNormalBaseAddr    => exceptNormalBaseAddr,
            exceptBootBaseAddr      => exceptBootBaseAddr,
            tlbRefillExl0Offset     => tlbRefillExl0Offset,
            generalExceptOffset     => generalExceptOffset,
            interruptIv1Offset      => interruptIv1Offset
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
            int_i => int_i,
            timerInt_o => timerInt_o,
            isKernelMode_o => isKernelMode,
            entryIndex_o => entryIndex,
            entryWrite_o => entryWrite,
            entry_o => entry
        );

end bhv;
