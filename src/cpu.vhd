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

    signal instEnable, instPhyEnable, instDevEnable: std_logic;
    signal instStall, instDevStall: std_logic;
    signal instData, instDevData: std_logic_vector(DataWidth);
    signal instAddr, instPhyAddr: std_logic_vector(AddrWidth);

    signal dataEnable, dataPhyEnable, dataDevEnable: std_logic;
    signal dataStall, dataDevStall: std_logic;
    signal dataWrite: std_logic;
    signal dataDataSave: std_logic_vector(DataWidth);
    signal dataDataLoad, dataDevDataLoad: std_logic_vector(DataWidth);
    signal dataAddr, dataPhyAddr: std_logic_vector(AddrWidth);
    signal dataByteSelect: std_logic_vector(3 downto 0);

    signal instExcept, dataExcept: std_logic_vector(ExceptionCauseWidth);

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

    memctrl_ist: entity work.memctrl
        port map (
            -- Connect to instruction cache
            instEnable_i => instDevEnable,
            instData_o => instDevData,
            instAddr_i => instPhyAddr,
            instStall_o => instDevStall,

            -- Connect to data cache
            dataEnable_i => dataDevEnable,
            dataWrite_i => dataWrite,
            dataData_o => dataDevDataLoad,
            dataData_i => dataDataSave,
            dataAddr_i => dataPhyAddr,
            dataByteSelect_i => dataByteSelect,
            dataStall_o => dataDevStall,

            -- Connect to external device
            devEnable_o => devEnable_o,
            devWrite_o => devWrite_o,
            devData_i => dataLoadConv,
            devData_o => dataSaveConv,
            devAddr_o => devPhysicalAddr_o,
            devByteSelect_o => byteSelectConv,
            devBusy_i => devBusy_i
        );

    inst_cache: entity work.cache
        port map (
            clk => clk,
            rst => rst,
            enable_i => instEnable,
            write_i => NO,
            busy_o => instStall,
            dataSave_i => 32ux"0",
            dataLoad_o => instData,
            addr_i => instAddr,
            enable_o => instDevEnable,
            busy_i => instDevStall,
            dataLoad_i => instDevData
        );

    data_cache: entity work.cache
        port map (
            clk => clk,
            rst => rst,
            enable_i => dataEnable,
            write_i => dataWrite,
            busy_o => dataStall,
            dataSave_i => dataDataSave,
            dataLoad_o => dataDataLoad,
            addr_i => dataAddr,
            enable_o => dataDevEnable,
            busy_i => dataDevStall,
            dataLoad_i => dataDevDataLoad
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
