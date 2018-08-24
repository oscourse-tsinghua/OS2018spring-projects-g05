library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.except_const.all;
use work.mmu_const.all;
use work.bus_const.all;

entity cpu is
    generic (
        extraCmd: boolean := true;
        instEntranceAddr: std_logic_vector(AddrWidth) := 32ux"bfc0_0000";
        exceptBootBaseAddr: std_logic_vector(AddrWidth) := 32ux"bfc0_0200";
        tlbRefillExl0Offset: std_logic_vector(AddrWidth) := 32ux"000";
        generalExceptOffset: std_logic_vector(AddrWidth) := 32ux"180";
        interruptIv1Offset: std_logic_vector(AddrWidth) := 32ux"200";
        convEndianEnable: boolean := false;
        cpuId: std_logic_vector(9 downto 0) := 10ub"0";
        enableCache: std_logic := YES;
        scStallPeriods: integer := 0
    );
    port (
        clk, rst: in std_logic;

        instDev_i, dataDev_i: in BusD2C;
        instDev_o, dataDev_o: out BusC2D;
        busMon_i: in BusC2D;
        llBit_i: in std_logic;
        llLoc_i: in std_logic_vector(AddrWidth);
        scCorrect_i: in std_logic;
        sync_o: out std_logic_vector(2 downto 0);

        int_i: in std_logic_vector(IntWidth);
        timerInt_o: out std_logic;

        debug_wb_pc: out std_logic_vector(AddrWidth);
        debug_wb_rf_wen: out std_logic_vector(3 downto 0);
        debug_wb_rf_wnum: out std_logic_vector(CP0RegAddrWidth);
        debug_wb_rf_wdata: out std_logic_vector(DataWidth)
    );
end cpu;

architecture bhv of cpu is

    signal instEnable: std_logic;
    signal instData: std_logic_vector(DataWidth);
    signal instVAddr: std_logic_vector(AddrWidth);
    signal instExcept: std_logic_vector(ExceptionCauseWidth);
    signal instTlbRefill: std_logic;

    signal dataEnable, dataWrite: std_logic;
    signal dataDataSave: std_logic_vector(DataWidth);
    signal dataDataLoad: std_logic_vector(DataWidth);
    signal dataVAddr: std_logic_vector(AddrWidth);
    signal dataByteSelect: std_logic_vector(3 downto 0);
    signal dataExcept: std_logic_vector(ExceptionCauseWidth);
    signal dataTlbRefill: std_logic;

    signal instCache_d2c, dataCache_d2c: BusD2C;
    signal instCache_c2d, dataCache_c2d: BusC2D;

    signal isKernelMode: std_logic;
    signal entryIndexSave, entryIndexLoad: std_logic_vector(TLBIndexWidth);
    signal entryIndexValid: std_logic;
    signal entryWrite: std_logic;
    signal entryFlush: std_logic;
    signal entrySave, entryLoad: TLBEntry;
    signal pageMask: std_logic_vector(AddrWidth);

    signal sync: std_logic_vector(2 downto 0);

    signal debug_wb_rf_wen_ref: std_logic;
begin
    inst_cache: entity work.cache
        generic map (
            enableCache => enableCache
        )
        port map (
            clk => clk, rst => rst,
            vAddr_i => instVAddr,
            req_i => instCache_c2d,
            res_o => instCache_d2c,
            sync_i => "000",
            req_o => instDev_o,
            res_i => instDev_i,
            mon_i => busMon_i,
            llBit_i => llBit_i,
            llLoc_i => llLoc_i
        );
    data_cache: entity work.cache
        generic map (
            enableCache => enableCache
        )
        port map (
            clk => clk, rst => rst,
            vAddr_i => dataVAddr,
            req_i => dataCache_c2d,
            res_o => dataCache_d2c,
            sync_i => sync,
            req_o => dataDev_o,
            res_i => dataDev_i,
            mon_i => busMon_i,
            llBit_i => llBit_i,
            llLoc_i => llLoc_i
        );

    instCache_c2d.dataSave <= (others => 'X');
    conv_endian_inst_load: entity work.conv_endian
        generic map (enable => convEndianEnable)
        port map (input => instCache_d2c.dataLoad, output => instData);
    conv_endian_data_save: entity work.conv_endian
        generic map (enable => convEndianEnable)
        port map (input => dataDataSave, output => dataCache_c2d.dataSave);
    conv_endian_data_load: entity work.conv_endian
        generic map (enable => convEndianEnable)
        port map (input => dataCache_d2c.dataLoad, output => dataDataLoad);

    instCache_c2d.byteSelect <= "1111";
    process (all) begin
        if (convEndianEnable) then
            dataCache_c2d.byteSelect <= dataByteSelect(0) & dataByteSelect(1) & dataByteSelect(2) & dataByteSelect(3);
        else
            dataCache_c2d.byteSelect <= dataByteSelect;
        end if;
    end process;

    instCache_c2d.write <= NO;
    dataCache_c2d.write <= dataWrite;

    mmu_ist: entity work.mmu
        port map (
            clk => clk, rst => rst,

            isKernelMode_i => isKernelMode,

            enable1_i => instEnable,
            isLoad1_i => YES,
            addr1_i => instVAddr,
            addr1_o => instCache_c2d.addr,
            enable1_o => instCache_c2d.enable,
            exceptCause1_o => instExcept,
            tlbRefill1_o => instTlbRefill,

            enable2_i => dataEnable,
            isLoad2_i => not dataWrite,
            addr2_i => dataVAddr,
            addr2_o => dataCache_c2d.addr,
            enable2_o => dataCache_c2d.enable,
            exceptCause2_o => dataExcept,
            tlbRefill2_o => dataTlbRefill,

            pageMask_i => pageMask,
            index_i => entryIndexSave,
            index_o => entryIndexLoad,
            indexValid_o => entryIndexValid,
            entryWrite_i => entryWrite,

            entryFlush_i => entryFlush,
            entry_i => entrySave,
            entry_o => entryLoad
        );
    debug_wb_rf_wen <= (0 => debug_wb_rf_wen_ref, 1 => debug_wb_rf_wen_ref, 2 => debug_wb_rf_wen_ref, 3 => debug_wb_rf_wen_ref);

    datapath_ist: entity work.datapath
        generic map (
            extraCmd                => extraCmd,
            instEntranceAddr        => instEntranceAddr,
            exceptBootBaseAddr      => exceptBootBaseAddr,
            tlbRefillExl0Offset     => tlbRefillExl0Offset,
            generalExceptOffset     => generalExceptOffset,
            interruptIv1Offset      => interruptIv1Offset,
            cpuId                   => cpuId,
            scStallPeriods          => scStallPeriods
        )
        port map (
            rst => rst,
            clk => clk,
            instEnable_o => instEnable,
            instData_i => instData,
            instAddr_o => instVAddr,
            instTlbRefill_i => instTlbRefill,
            dataEnable_o => dataEnable,
            dataWrite_o => dataWrite,
            dataData_i => dataDataLoad,
            dataData_o => dataDataSave,
            dataAddr_o => dataVAddr,
            dataByteSelect_o => dataByteSelect,
            instExcept_i => instExcept,
            dataExcept_i => dataExcept,
            dataTlbRefill_i => dataTlbRefill,
            ifToStall_i => instCache_d2c.busy,
            memToStall_i => dataCache_d2c.busy,
            int_i => int_i,
            timerInt_o => timerInt_o,
            isKernelMode_o => isKernelMode,
            entryIndex_i => entryIndexLoad,
            entryIndexValid_i => entryIndexValid,
            entryIndex_o => entryIndexSave,
            entryWrite_o => entryWrite,
            entryFlush_o => entryFlush,
            entry_i => entryLoad,
            entry_o => entrySave,
            pageMask_o => pageMask,
            scCorrect_i => scCorrect_i,
            sync_o => sync,
            debug_wb_pc => debug_wb_pc,
            debug_wb_rf_wdata => debug_wb_rf_wdata,
            debug_wb_rf_wnum => debug_wb_rf_wnum,
            debug_wb_rf_wen_datapath => debug_wb_rf_wen_ref
        );
    sync_o <= sync;

end bhv;
