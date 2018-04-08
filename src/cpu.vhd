library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.except_const.all;
use work.mmu_const.all;

entity cpu is
    generic (
        instEntranceAddr: std_logic_vector(AddrWidth) := 32ux"bfc0_0000";
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

    signal instEnable, instPhyEnable: std_logic;
    signal instData: std_logic_vector(DataWidth);
    signal instAddr, instPhyAddr: std_logic_vector(AddrWidth);

    signal dataEnable, dataPhyEnable: std_logic;
    signal dataWrite: std_logic;
    signal dataDataSave: std_logic_vector(DataWidth);
    signal dataDataLoad: std_logic_vector(DataWidth);
    signal dataAddr, dataPhyAddr: std_logic_vector(AddrWidth);
    signal dataByteSelect: std_logic_vector(3 downto 0);

    signal instStall, dataStall: std_logic;
    signal instExcept, dataExcept: std_logic_vector(ExceptionCauseWidth);

    signal cacheEnable, cacheWrite, cacheBusy: std_logic;
    signal cacheDataSave, cacheDataLoad: std_logic_vector(DataWidth);
    signal cacheAddr: std_logic_vector(AddrWidth);

    signal isKernelMode: std_logic;
    signal entryIndexSave, entryIndexLoad: std_logic_vector(TLBIndexWidth);
    signal entryIndexValid: std_logic;
    signal entryWrite: std_logic;
    signal entryFlush: std_logic;
    signal entrySave, entryLoad: TLBEntry;

    signal dataLoadConv, dataSaveConv: std_logic_vector(DataWidth);
    signal byteSelectConv: std_logic_vector(3 downto 0);

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
    process (all) begin
        if (convEndianEnable) then
            devByteSelect_o <= byteSelectConv(0) & byteSelectConv(1) & byteSelectConv(2) & byteSelectConv(3);
        else
            devByteSelect_o <= byteSelectConv;
        end if;
    end process;

    devWrite_o <= cacheWrite;
    dataSaveConv <= cacheDataSave;
    devPhysicalAddr_o <= cacheAddr;

    cache_ist: entity work.cache
        port map (
            clk => clk,
            rst => rst,
            enable_i => cacheEnable,
            write_i => cacheWrite,
            busy_o => cacheBusy,
            dataSave_i => cacheDataSave,
            dataLoad_o => cacheDataLoad,
            addr_i => cacheAddr,
            enable_o => devEnable_o,
            busy_i => devBusy_i,
            dataLoad_i => dataLoadConv
        );

    memctrl_ist: entity work.memctrl
        port map (
            -- Connect to instruction interface(1) of MMU
            instEnable_i => instPhyEnable,
            instData_o => instData,
            instAddr_i => instPhyAddr,
            instStall_o => instStall,

            -- Connect to data interface(2) of MMU
            dataEnable_i => dataPhyEnable,
            dataWrite_i => dataWrite,
            dataData_o => dataDataLoad,
            dataData_i => dataDataSave,
            dataAddr_i => dataPhyAddr,
            dataByteSelect_i => dataByteSelect,
            dataStall_o => dataStall,

            -- Connect to external device
            devEnable_o => cacheEnable,
            devWrite_o => cacheWrite,
            devData_i => cacheDataLoad,
            devData_o => cacheDataSave,
            devAddr_o => cacheAddr,
            devByteSelect_o => byteSelectConv,
            devBusy_i => cacheBusy
        );

    mmu_ist: entity work.mmu
        port map (
            clk => clk,
            rst => rst,
            isKernelMode_i => isKernelMode,

            enable1_i => instEnable,
            isLoad1_i => '1',
            addr1_i => instAddr,
            addr1_o => instPhyAddr,
            enable1_o => instPhyEnable,
            exceptCause1_o => instExcept,

            enable2_i => dataEnable,
            isLoad2_i => not dataWrite,
            addr2_i => dataAddr,
            addr2_o => dataPhyAddr,
            enable2_o => dataPhyEnable,
            exceptCause2_o => dataExcept,

            index_i => entryIndexSave,
            index_o => entryIndexLoad,
            indexValid_o => entryIndexValid,
            entryWrite_i => entryWrite,

            entryFlush_i => entryFlush,
            entry_i => entrySave,
            entry_o => entryLoad
        );

    datapath_ist: entity work.datapath
        generic map (
            instEntranceAddr        => instEntranceAddr,
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
            entryIndex_i => entryIndexLoad,
            entryIndexValid_i => entryIndexValid,
            entryIndex_o => entryIndexSave,
            entryWrite_o => entryWrite,
            entryFlush_o => entryFlush,
            entry_i => entryLoad,
            entry_o => entrySave
        );

end bhv;
