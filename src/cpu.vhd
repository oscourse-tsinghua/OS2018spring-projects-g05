library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.except_const.all;
use work.mmu_const.all;
use work.bus_const.all;

entity cpu is
    generic (
        instEntranceAddr: std_logic_vector(AddrWidth) := 32ux"bfc0_0000";
        exceptBootBaseAddr: std_logic_vector(AddrWidth) := 32ux"bfc0_0200";
        tlbRefillExl0Offset: std_logic_vector(AddrWidth) := 32ux"000";
        generalExceptOffset: std_logic_vector(AddrWidth) := 32ux"180";
        interruptIv1Offset: std_logic_vector(AddrWidth) := 32ux"200";
        convEndianEnable: boolean := false;
        cpuId: std_logic_vector(9 downto 0) := 10ub"0"
    );
    port (
        clk, rst: in std_logic;

        instDev_io, dataDev_io: inout BusInterface;
        scCorrect_i: in std_logic;
        sync_o: out std_logic_vector(2 downto 0);

        int_i: in std_logic_vector(IntWidth);
        timerInt_o: out std_logic
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

    signal isKernelMode: std_logic;
    signal entryIndexSave, entryIndexLoad: std_logic_vector(TLBIndexWidth);
    signal entryIndexValid: std_logic;
    signal entryWrite: std_logic;
    signal entryFlush: std_logic;
    signal entrySave, entryLoad: TLBEntry;
    signal pageMask: std_logic_vector(AddrWidth);

begin
    instDev_io.dataSave_c2d <= (others => 'X');
    conv_endian_inst_load: entity work.conv_endian
        generic map (enable => convEndianEnable)
        port map (input => instDev_io.dataLoad_d2c, output => instData);
    conv_endian_data_save: entity work.conv_endian
        generic map (enable => convEndianEnable)
        port map (input => dataDataSave, output => dataDev_io.dataSave_c2d);
    conv_endian_data_load: entity work.conv_endian
        generic map (enable => convEndianEnable)
        port map (input => dataDev_io.dataLoad_d2c, output => dataDataLoad);

    instDev_io.byteSelect_c2d <= "1111";
    process (all) begin
        if (convEndianEnable) then
            dataDev_io.byteSelect_c2d <= dataByteSelect(0) & dataByteSelect(1) & dataByteSelect(2) & dataByteSelect(3);
        else
            dataDev_io.byteSelect_c2d <= dataByteSelect;
        end if;
    end process;

    instDev_io.write_c2d <= NO;
    dataDev_io.write_c2d <= dataWrite;

    mmu_ist: entity work.mmu
        port map (
            clk => clk, rst => rst,

            isKernelMode_i => isKernelMode,

            enable1_i => instEnable,
            isLoad1_i => YES,
            addr1_i => instVAddr,
            addr1_o => instDev_io.addr_c2d,
            enable1_o => instDev_io.enable_c2d,
            exceptCause1_o => instExcept,
            tlbRefill1_o => instTlbRefill,

            enable2_i => dataEnable,
            isLoad2_i => not dataWrite,
            addr2_i => dataVAddr,
            addr2_o => dataDev_io.addr_c2d,
            enable2_o => dataDev_io.enable_c2d,
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

    datapath_ist: entity work.datapath
        generic map (
            instEntranceAddr        => instEntranceAddr,
            exceptBootBaseAddr      => exceptBootBaseAddr,
            tlbRefillExl0Offset     => tlbRefillExl0Offset,
            generalExceptOffset     => generalExceptOffset,
            interruptIv1Offset      => interruptIv1Offset,
            cpuId                   => cpuId
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
            ifToStall_i => instDev_io.busy_d2c,
            memToStall_i => dataDev_io.busy_d2c,
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
            sync_o => sync_o
        );

end bhv;
