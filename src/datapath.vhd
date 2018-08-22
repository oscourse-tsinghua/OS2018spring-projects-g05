library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.alu_const.all;
use work.mem_const.all;
use work.cp0_const.all;
use work.mmu_const.all;
use work.except_const.all;

entity datapath is
    generic (
        instEntranceAddr:       std_logic_vector(AddrWidth);
        exceptBootBaseAddr:     std_logic_vector(AddrWidth);
        tlbRefillExl0Offset:    std_logic_vector(AddrWidth);
        generalExceptOffset:    std_logic_vector(AddrWidth);
        interruptIv1Offset:     std_logic_vector(AddrWidth);
        cpuId:                  std_logic_vector(9 downto 0);
        scStallPeriods:         integer
    );
    port (
        rst, clk: in std_logic;
        instData_i: in std_logic_vector(InstWidth);
        instAddr_o: out std_logic_vector(AddrWidth);
        instEnable_o: out std_logic;

        dataEnable_o: out std_logic;
        dataWrite_o: out std_logic;
        dataData_i: in std_logic_vector(DataWidth);
        scCorrect_i: in std_logic;
        dataData_o: out std_logic_vector(DataWidth);
        dataAddr_o: out std_logic_vector(AddrWidth);
        dataByteSelect_o: out std_logic_vector(3 downto 0);
        sync_o: out std_logic_vector(2 downto 0);

        instExcept_i, dataExcept_i: in std_logic_vector(ExceptionCauseWidth);
        instTlbRefill_i, dataTlbRefill_i: in std_logic;
        ifToStall_i, memToStall_i: in std_logic;

        int_i: in std_logic_vector(intWidth);
        timerInt_o: out std_logic;

        -- To MMU
        isKernelMode_o: out std_logic;
        entryIndex_i: in std_logic_vector(TLBIndexWidth);
        entryIndexValid_i: in std_logic;
        entryIndex_o: out std_logic_vector(TLBIndexWidth);
        entryWrite_o: out std_logic;
        entryFlush_o: out std_logic;
        entry_i: in TLBEntry;
        entry_o: out TLBEntry;
        pageMask_o: out std_logic_vector(AddrWidth);

        debug_wb_pc: out std_logic_vector(AddrWidth);
        debug_wb_rf_wen_datapath: out std_logic;
        debug_wb_rf_wnum: out std_logic_vector(RegAddrWidth);
        debug_wb_rf_wdata: out std_logic_vector(DataWidth)
    );
end datapath;

architecture bhv of datapath is
    -- Labels of components for convenience (especially in quantity naming)
    -- 1: pc_reg
    -- 2: if_id
    -- 3: regfile
    -- 4: id
    -- 5: id_ex
    -- 6: ex
    -- 7: ex_mem
    -- 8: mem
    -- 9: mem_wb
    -- a: hi_lo
    -- b: ctrl
    -- c: cp0
    -- d: div

    -- Signal connecting pc_reg and if_id --
    signal pc_12: std_logic_vector(AddrWidth);
    signal instEnable_12: std_logic;

    -- Signals connecting if_id and id --
    signal pc_24: std_logic_vector(AddrWidth);
    signal valid_24: std_logic;
    signal inst_24: std_logic_vector(InstWidth);
    signal exceptCause_24: std_logic_vector(ExceptionCauseWidth);
    signal tlbRefill_24: std_logic;

    -- Signals connecting regfile and id --
    signal regReadEnable1_43, regReadEnable2_43: std_logic;
    signal regReadAddr1_43, regReadAddr2_43: std_logic_vector(RegAddrWidth);
    signal regData1_34, regData2_34: std_logic_vector(DataWidth);

    -- Signals connecting id and id_ex --
    signal alut_45: AluType;
    signal memt_45: MemType;
    signal operand1_45: std_logic_vector(DataWidth);
    signal operand2_45: std_logic_vector(DataWidth);
    signal operandX_45: std_logic_vector(DataWidth);
    signal toWriteReg_45: std_logic;
    signal writeRegAddr_45: std_logic_vector(RegAddrWidth);
    signal isInDelaySlot_45: std_logic;
    signal linkAddr_45: std_logic_vector(AddrWidth);
    signal nextInstInDelaySlot_45: std_logic;
    signal isInDelaySlot_54: std_logic;
    signal valid_45: std_logic;
    signal exceptCause_45: std_logic_vector(ExceptionCauseWidth);
    signal tlbRefill_45: std_logic;
    signal currentInstAddr_45: std_logic_vector(AddrWidth);
    signal flushForceWrite_45: std_logic;

    -- Signals connecting id_ex and ex --
    signal alut_56: AluType;
    signal memt_56: MemType;
    signal operand1_56: std_logic_vector(DataWidth);
    signal operand2_56: std_logic_vector(DataWidth);
    signal operandX_56: std_logic_vector(DataWidth);
    signal toWriteReg_56: std_logic;
    signal writeRegAddr_56: std_logic_vector(RegAddrWidth);
    signal exIsInDelaySlot_56: std_logic;
    signal exLinkAddress_56: std_logic_vector(AddrWidth);
    signal exExceptCause_56: std_logic_vector(ExceptionCauseWidth);
    signal exTlbRefill_56: std_logic;
    signal exCurrentInstAddr_56: std_logic_vector(AddrWidth);
    signal valid_56: std_logic;
    signal flushForceWrite_56: std_logic;

    -- Signals connecting ex and id --
    signal exToWriteReg_64: std_logic;
    signal exWriteRegAddr_64: std_logic_vector(RegAddrWidth);
    signal exWriteRegData_64: std_logic_vector(DataWidth);
    signal lastMemt_64: MemType;

    -- Signals connecting ex and ex_mem --
    signal toWriteReg_67: std_logic;
    signal writeRegAddr_67: std_logic_vector(RegAddrWidth);
    signal writeRegData_67: std_logic_vector(DataWidth);
    signal toWriteHi_67, toWriteLo_67: std_logic;
    signal writeHiData_67, writeLoData_67: std_logic_vector(DataWidth);
    signal memt_67: MemType;
    signal memAddr_67: std_logic_vector(AddrWidth);
    signal memData_67: std_logic_vector(DataWidth);
    signal cp0RegData_67: std_logic_vector(DataWidth);
    signal cp0RegWriteAddr_67: std_logic_vector(CP0RegAddrWidth);
    signal cp0RegWriteSel_67: std_logic_vector(SelWidth);
    signal cp0RegWe_67: std_logic;
    signal cp0Sp_67: CP0Special;
    signal tempProduct_67, tempProduct_76: std_logic_vector(DoubleDataWidth);
    signal cnt_67, cnt_76: std_logic_vector(CntWidth);
    signal exceptCause_67: std_logic_vector(ExceptionCauseWidth);
    signal tlbRefill_67: std_logic;
    signal currentInstAddr_67: std_logic_vector(AddrWidth);
    signal isInDelaySlot_67: std_logic;
    signal valid_67: std_logic;
    signal flushForceWrite_67: std_logic;

    -- Signals connecting ex and cp0 --
    signal cp0RegReadAddr_6c: std_logic_vector(CP0RegAddrWidth);
    signal cp0RegReadSel_6c: std_logic_vector(SelWidth);

    -- Signals connecting ex and div --
    signal divEnable_6d: std_logic;
    signal dividend_6d, divider_6d: std_logic_vector(DataWidth);
    signal quotient_d6, remainder_d6: std_logic_vector(DataWidth);
    signal divBusy_d6: std_logic;

    -- Signals connecting ex_mem and mem --
    signal toWriteReg_78: std_logic;
    signal writeRegAddr_78: std_logic_vector(RegAddrWidth);
    signal writeRegData_78: std_logic_vector(DataWidth);
    signal toWriteHi_78, toWriteLo_78: std_logic;
    signal writeHiData_78, writeLoData_78: std_logic_vector(DataWidth);
    signal memt_78: MemType;
    signal memAddr_78: std_logic_vector(AddrWidth);
    signal memData_78: std_logic_vector(DataWidth);
    signal cp0RegData_78: std_logic_vector(DataWidth);
    signal cp0RegWriteAddr_78: std_logic_vector(CP0RegAddrWidth);
    signal cp0RegWriteSel_78: std_logic_vector(SelWidth);
    signal cp0RegWe_78: std_logic;
    signal cp0Sp_78: CP0Special;
    signal exceptCause_78: std_logic_vector(ExceptionCauseWidth);
    signal tlbRefill_78: std_logic;
    signal currentInstAddr_78: std_logic_vector(AddrWidth);
    signal isInDelaySlot_78: std_logic;
    signal valid_78: std_logic;
    signal flushForceWrite_78: std_logic;

    -- Signals connecting mem and id --
    signal memToWriteReg_84: std_logic;
    signal memWriteRegAddr_84: std_logic_vector(RegAddrWidth);
    signal memWriteRegData_84: std_logic_vector(DataWidth);

    -- Signals connecting mem and ex --
    signal memToWriteHi_86, memToWriteLo_86: std_logic;
    signal memWriteHiData_86, memWriteLoData_86: std_logic_vector(DataWidth);
    signal cp0RegData_86: std_logic_vector(DataWidth);
    signal cp0RegWriteAddr_86: std_logic_vector(CP0RegAddrWidth);
    signal cp0RegWe_86: std_logic;

    -- Signals connecting mem and mem_wb --
    signal toWriteReg_89: std_logic;
    signal writeRegAddr_89: std_logic_vector(RegAddrWidth);
    signal writeRegData_89: std_logic_vector(DataWidth);
    signal toWriteHi_89, toWriteLo_89: std_logic;
    signal writeHiData_89, writeLoData_89: std_logic_vector(DataWidth);
    signal cp0RegData_89: std_logic_vector(DataWidth);
    signal cp0RegWriteAddr_89: std_logic_vector(CP0RegAddrWidth);
    signal cp0RegWriteSel_89: std_logic_vector(SelWidth);
    signal cp0RegWe_89: std_logic;
    signal cp0Sp_89: CP0Special;
    signal currentInstAddr_89: std_logic_vector(AddrWidth);
    signal flushForceWrite_89: std_logic;

    -- Signals connecting mem_wb and regfile --
    signal toWriteReg_93: std_logic;
    signal writeRegAddr_93: std_logic_vector(RegAddrWidth);
    signal writeRegData_93: std_logic_vector(DataWidth);

    -- Signals connecting mem_wb and hi_lo --
    signal toWriteHi_9a, toWriteLo_9a: std_logic;
    signal writeHiData_9a, writeLoData_9a: std_logic_vector(DataWidth);

    -- Signals connecting mem_wb and ex --
    signal wbToWriteHi_96, wbToWriteLo_96: std_logic;
    signal wbWriteHiData_96, wbWriteLoData_96: std_logic_vector(DataWidth);

    -- Signals connecting mem_wb and cp0 --
    signal wbCP0RegData_9c: std_logic_vector(DataWidth);
    signal wbCP0RegWriteAddr_9c: std_logic_vector(CP0RegAddrWidth);
    signal wbCP0RegWriteSel_9c: std_logic_vector(SelWidth);
    signal wbCP0RegWe_9c: std_logic;
    signal cp0Sp_9c: CP0Special;

    -- Signals connecting hi_lo and ex --
    signal hiData_a6, loData_a6: std_logic_vector(DataWidth);

    -- Signals connecting ctrl and pc --
    signal flush_b1: std_logic;
    signal newPC_b1: std_logic_vector(AddrWidth);

    -- Signals connecting ctrl and if_id --
    signal flush_b2: std_logic;

    -- Signals connecting ctrl and id_ex --
    signal flush_b5: std_logic;

    -- Signals connecting ctrl and ex_mem --
    signal flush_b7: std_logic;

    -- Signals connecting ctrl and mem_wb --
    signal flush_b9: std_logic;
    signal wbCP0RegWe_9b: std_logic;

    -- Signals connecting id and ctrl --
    signal isIdEhb_4b: std_logic;
    signal idToStall_4b, blNullify_4b: std_logic;
    signal idIsInDelaySlot_4b: std_logic;

    -- Signals connecting ex and ctrl --
    signal exToStall_6b: std_logic;
    signal excp0RegWe_6b: std_logic;

    -- Signals connecting ctrl and others --
    signal stall: std_logic_vector(StallWidth);

    -- Signals connecting id_ex and pc --
    signal branchTargetAddress_41: std_logic_vector(AddrWidth);
    signal branchFlag_41: std_logic;

    -- Signals connecting cp0 and ex --
    signal data_c6: std_logic_vector(DataWidth);

    -- Signals connecting cp0 and mem --
    signal status_c8: std_logic_vector(DataWidth);
    signal cause_c8: std_logic_vector(DataWidth);
    signal epc_c8: std_logic_vector(AddrWidth);
    signal exceptCause_8c: std_logic_vector(ExceptionCauseWidth);
    signal currentInstAddr_8c, currentAccessAddr_8c: std_logic_vector(AddrWidth);
    signal isInDelaySlot_8c: std_logic;
    signal memDataWrite_8c: std_logic;
    signal tlbRefill_8c: std_logic;

    -- Signals connecting cp0 and ctrl --
    signal cp0Status_cb: std_logic_vector(DataWidth);
    signal cp0Cause_cb: std_logic_vector(DataWidth);
    signal cp0Epc_cb: std_logic_vector(DataWidth);
    signal cp0EBaseAddr_cb: std_logic_vector(DataWidth);
    signal ctrlToWriteBadVAddr_cb: std_logic;
    signal ctrlBadVAddr_cb: std_logic_vector(DataWidth);
    signal exceptCause_cb: std_logic_vector(ExceptionCauseWidth);
    signal depc_cb: std_logic_vector(AddrWidth);
    signal tlbRefill_cb: std_logic;

    -- Signals connecting mem and ctrl --
    signal memCp0RegWe_8b: std_logic;
    signal scStall_8b: integer;
    signal memDataWrite: std_logic;
begin

    pc_reg_ist: entity work.pc_reg
        generic map (
            instEntranceAddr => instEntranceAddr
        )
        port map (
           rst => rst, clk => clk,
           stall_i => stall,
           pc_o => pc_12,
           pcEnable_o => instEnable_12,
           branchFlag_i => branchFlag_41,
           branchTargetAddress_i => branchTargetAddress_41,
           flush_i => flush_b1,
           newPC_i => newPC_b1
        );
    instEnable_o <= instEnable_12;

    if_id_ist: entity work.if_id
        port map (
            rst => rst, clk => clk,
            stall_i => stall,
            pc_i => pc_12,
            valid_o => valid_24,
            instEnable_i => instEnable_12,
            inst_i => instData_i,
            pc_o => pc_24,
            inst_o => inst_24,
            flush_i => flush_b2,
            exceptCause_o => exceptCause_24
        );
    instAddr_o <= pc_12;

    regfile_ist: entity work.regfile
        port map (
            rst => rst, clk => clk,
            writeEnable_i => toWriteReg_93,
            writeAddr_i => writeRegAddr_93,
            writeData_i => writeRegData_93,
            readEnable1_i => regReadEnable1_43,
            readAddr1_i => regReadAddr1_43,
            readData1_o => regData1_34,
            readEnable2_i => regReadEnable2_43,
            readAddr2_i => regReadAddr2_43,
            readData2_o => regData2_34
        );

    id_ist: entity work.id
        port map (
            rst => rst,

            pc_i => pc_24,
            inst_i => inst_24,
            regData1_i => regData1_34,
            regData2_i => regData2_34,
            regReadEnable1_o => regReadEnable1_43,
            regReadEnable2_o => regReadEnable2_43,
            regReadAddr1_o => regReadAddr1_43,
            regReadAddr2_o => regReadAddr2_43,

            exToWriteReg_i => exToWriteReg_64,
            exWriteRegAddr_i => exWriteRegAddr_64,
            exWriteRegData_i => exWriteRegData_64,
            memToWriteReg_i => memToWriteReg_84,
            memWriteRegAddr_i => memWriteRegAddr_84,
            memWriteRegData_i => memWriteRegData_84,

            nextWillStall_i => stall(ID_STOP_IDX),
            toStall_o => idToStall_4b,

            alut_o => alut_45,
            memt_o => memt_45,
            lastMemt_i => lastMemt_64,
            operand1_o => operand1_45,
            operand2_o => operand2_45,
            operandX_o => operandX_45,
            toWriteReg_o => toWriteReg_45,
            writeRegAddr_o => writeRegAddr_45,

            isInDelaySlot_i => isInDelaySlot_54,
            nextInstInDelaySlot_o => nextInstInDelaySlot_45,
            branchFlag_o => branchFlag_41,
            branchTargetAddress_o => branchTargetAddress_41,
            isInDelaySlot_o => isInDelaySlot_45,
            blNullify_o => blNullify_4b,
            linkAddr_o => linkAddr_45,
            flushForceWrite_o => flushForceWrite_45,

            valid_i => valid_24,
            valid_o => valid_45,
            exceptCause_i => exceptCause_24,
            tlbRefill_i =>tlbRefill_24,
            exceptCause_o => exceptCause_45,
            tlbRefill_o =>tlbRefill_45,
            currentInstAddr_o => currentInstAddr_45,

            isIdEhb_o => isIdEhb_4b
        );
    idIsInDelaySlot_4b <= isInDelaySlot_45;

    id_ex_ist: entity work.id_ex
        port map (
            rst => rst, clk => clk,

            operand1_i => operand1_45,
            operand2_i => operand2_45,
            operandX_i => operandX_45,
            toWriteReg_i => toWriteReg_45,
            writeRegAddr_i => writeRegAddr_45,
            operand1_o => operand1_56,
            operand2_o => operand2_56,
            operandX_o => operandX_56,
            toWriteReg_o => toWriteReg_56,
            writeRegAddr_o => writeRegAddr_56,

            alut_i => alut_45,
            memt_i => memt_45,
            alut_o => alut_56,
            memt_o => memt_56,
            stall_i => stall,

            idExceptCause_i => exceptCause_45,
            idTlbRefill_i => tlbRefill_45,
            exExceptCause_o => exExceptCause_56,
            exTlbRefill_o => exTlbRefill_56,
            valid_i => valid_45,
            valid_o => valid_56,
            flush_i => flush_b5,

            idLinkAddress_i => linkAddr_45,
            idIsInDelaySlot_i => isInDelaySlot_45,
            nextInstInDelaySlot_i => nextInstInDelaySlot_45,
            exLinkAddress_o => exLinkAddress_56,
            exIsInDelaySlot_o => exIsInDelaySlot_56,
            isInDelaySlot_o => isInDelaySlot_54,
            idCurrentInstAddr_i => currentInstAddr_45,
            exCurrentInstAddr_o => exCurrentInstAddr_56,
            flushForceWrite_i => flushForceWrite_45,
            flushForceWrite_o => flushForceWrite_56
        );

    ex_ist: entity work.ex
        port map (
            rst => rst,

            alut_i => alut_56,
            memt_i => memt_56,
            operand1_i => operand1_56,
            operand2_i => operand2_56,
            operandX_i => operandX_56,
            toWriteReg_i => toWriteReg_56,
            writeRegAddr_i => writeRegAddr_56,
            linkAddress_i => exLinkAddress_56,
            isInDelaySlot_i => exIsInDelaySlot_56,
            toStall_o => exToStall_6b,
            toWriteReg_o => toWriteReg_67,
            writeRegAddr_o => writeRegAddr_67,
            writeRegData_o => writeRegData_67,

            hi_i => hiData_a6,
            lo_i => loData_a6,
            memToWriteHi_i => memToWriteHi_86,
            memToWriteLo_i => memToWriteLo_86,
            memWriteHiData_i => memWriteHiData_86,
            memWriteLoData_i => memWriteLoData_86,
            wbToWriteHi_i => wbToWriteHi_96,
            wbToWriteLo_i => wbToWriteLo_96,
            wbWriteHiData_i => wbWriteHiData_96,
            wbWriteLoData_i => wbWriteLoData_96,
            toWriteHi_o => toWriteHi_67,
            toWriteLo_o => toWriteLo_67,
            writeHiData_o => writeHiData_67,
            writeLoData_o => writeLoData_67,

            memt_o => memt_67,
            memAddr_o => memAddr_67,
            memData_o => memData_67,

            tempProduct_i => tempProduct_76,
            cnt_i => cnt_76,
            tempProduct_o => tempProduct_67,
            cnt_o => cnt_67,

            divBusy_i => divBusy_d6,
            quotient_i => quotient_d6,
            remainder_i => remainder_d6,
            divEnable_o => divEnable_6d,
            dividend_o => dividend_6d,
            divider_o => divider_6d,

            cp0RegData_i => data_c6,
            memCP0RegData_i => cp0RegData_86,
            memCP0RegWriteAddr_i => cp0RegWriteAddr_86,
            memCP0RegWe_i => cp0RegWe_86,
            cp0RegReadAddr_o => cp0RegReadAddr_6c,
            cp0RegReadSel_o => cp0RegReadSel_6c,
            cp0RegData_o => cp0RegData_67,
            cp0RegWriteAddr_o => cp0RegWriteAddr_67,
            cp0RegWriteSel_o => cp0RegWriteSel_67,
            cp0RegWe_o => cp0RegWe_67,
            cp0Sp_o => cp0Sp_67,

            valid_i => valid_56,
            valid_o => valid_67,
            exceptCause_i => exExceptCause_56,
            tlbRefill_i => exTlbRefill_56,
            currentInstAddr_i => exCurrentInstAddr_56,
            exceptCause_o => exceptCause_67,
            tlbRefill_o => tlbRefill_67,
            currentInstAddr_o => currentInstAddr_67,
            isInDelaySlot_o => isInDelaySlot_67,
            flushForceWrite_i => flushForceWrite_56,
            flushForceWrite_o => flushForceWrite_67

        );
    exToWriteReg_64 <= toWriteReg_67;
    exWriteRegAddr_64 <= writeRegAddr_67;
    exWriteRegData_64 <= writeRegData_67;
    lastMemt_64 <= memt_67;
    excp0RegWe_6b <= cp0RegWe_67;

    div_ist: entity work.div
        port map (
            clk => clk,
            enable_i => divEnable_6d,
            dividend_i => dividend_6d,
            divider_i => divider_6d,
            busy_o => divBusy_d6,
            quotient_o => quotient_d6,
            remainder_o => remainder_d6
        );

    ex_mem_ist: entity work.ex_mem
        port map (
            rst => rst, clk => clk,

            stall_i => stall,
            toWriteReg_i => toWriteReg_67,
            writeRegAddr_i => writeRegAddr_67,
            writeRegData_i => writeRegData_67,
            toWriteReg_o => toWriteReg_78,
            writeRegAddr_o => writeRegAddr_78,
            writeRegData_o => writeRegData_78,

            toWriteHi_i => toWriteHi_67,
            toWriteLo_i => toWriteLo_67,
            writeHiData_i => writeHiData_67,
            writeLoData_i => writeLoData_67,
            toWriteHi_o => toWriteHi_78,
            toWriteLo_o => toWriteLo_78,
            writeHiData_o => writeHiData_78,
            writeLoData_o => writeLoData_78,

            memt_i => memt_67,
            memAddr_i => memAddr_67,
            memData_i => memData_67,
            memt_o => memt_78,
            memAddr_o => memAddr_78,
            memData_o => memData_78,

            tempProduct_i => tempProduct_67,
            cnt_i => cnt_67,
            tempProduct_o => tempProduct_76,
            cnt_o => cnt_76,

            cp0RegData_i => cp0RegData_67,
            cp0RegWriteAddr_i => cp0RegWriteAddr_67,
            cp0RegWriteSel_i => cp0RegWriteSel_67,
            cp0RegWe_i => cp0RegWe_67,
            cp0Sp_i => cp0Sp_67,
            cp0RegData_o => cp0RegData_78,
            cp0RegWriteAddr_o => cp0RegWriteAddr_78,
            cp0RegWriteSel_o => cp0RegWriteSel_78,
            cp0RegWe_o => cp0RegWe_78,
            cp0Sp_o => cp0Sp_78,

            valid_i => valid_67,
            flush_i => flush_b7,
            exceptCause_i => exceptCause_67,
            tlbRefill_i => tlbRefill_67,
            isInDelaySlot_i => isInDelaySlot_67,
            currentInstAddr_i => currentInstAddr_67,
            valid_o => valid_78,
            exceptCause_o => exceptCause_78,
            tlbRefill_o => tlbRefill_78,
            currentInstAddr_o => currentInstAddr_78,
            isInDelaySlot_o => isInDelaySlot_78,
            flushForceWrite_i => flushForceWrite_67,
            flushForceWrite_o => flushForceWrite_78
        );

    mem_ist: entity work.mem
        generic map (
            scStallPeriods => scStallPeriods
        )
        port map (
            rst => rst,
            toWriteReg_i => toWriteReg_78,
            writeRegAddr_i => writeRegAddr_78,
            writeRegData_i => writeRegData_78,
            toWriteReg_o => toWriteReg_89,
            writeRegAddr_o => writeRegAddr_89,
            writeRegData_o => writeRegData_89,

            toWriteHi_i => toWriteHi_78,
            toWriteLo_i => toWriteLo_78,
            writeHiData_i => writeHiData_78,
            writeLoData_i => writeLoData_78,
            toWriteHi_o => toWriteHi_89,
            toWriteLo_o => toWriteLo_89,
            writeHiData_o => writeHiData_89,
            writeLoData_o => writeLoData_89,

            memt_i => memt_78,
            memAddr_i => memAddr_78,
            memData_i => memData_78,
            memExcept_i => dataExcept_i,
            tlbRefill_i => dataTlbRefill_i,
            loadedData_i => dataData_i,
            scCorrect_i => scCorrect_i,
            savingData_o => dataData_o,
            memAddr_o => dataAddr_o,
            dataEnable_o => dataEnable_o,
            dataWrite_o => memDataWrite_8c,
            dataByteSelect_o => dataByteSelect_o,
            sync_o => sync_o,
            scStall_o => scStall_8b,

            cp0RegData_i => cp0RegData_78,
            cp0RegWriteAddr_i => cp0RegWriteAddr_78,
            cp0RegWriteSel_i => cp0RegWriteSel_78,
            cp0RegWe_i => cp0RegWe_78,
            cp0Sp_i => cp0Sp_78,
            cp0RegData_o => cp0RegData_89,
            cp0RegWriteAddr_o => cp0RegWriteAddr_89,
            cp0RegWriteSel_o => cp0RegWriteSel_89,
            cp0RegWe_o => cp0RegWe_89,
            cp0Sp_o => cp0Sp_89,

            valid_i => valid_78,
            exceptCause_i => exceptCause_78,
            instTlbRefill_i => tlbRefill_78,
            isInDelaySlot_i => isInDelaySlot_78,
            currentInstAddr_i => currentInstAddr_78,
            cp0Status_i => status_c8,
            cp0Cause_i => cause_c8,
            exceptCause_o => exceptCause_8c,
            tlbRefill_o => tlbRefill_8c,
            isInDelaySlot_o => isInDelaySlot_8c,
            currentInstAddr_o => currentInstAddr_8c,
            currentAccessAddr_o => currentAccessAddr_8c,
            flushForceWrite_i => flushForceWrite_78,
            flushForceWrite_o => flushForceWrite_89
        );
    memToWriteReg_84 <= toWriteReg_89;
    memWriteRegAddr_84 <= writeRegAddr_89;
    memWriteRegData_84 <= writeRegData_89;
    memToWriteHi_86 <= toWriteHi_89;
    memToWriteLo_86 <= toWriteLo_89;
    memWriteHiData_86 <= writeHiData_89;
    memWriteLoData_86 <= writeLoData_89;
    cp0RegData_86 <= cp0RegData_89;
    cp0RegWriteAddr_86 <= cp0RegWriteAddr_89;
    cp0RegWe_86 <= cp0RegWe_89;
    memcp0regWe_8b <= cp0regWe_89;
    dataWrite_o <= memDataWrite_8c;
    currentInstAddr_89 <= currentInstAddr_8c;

    mem_wb_ist: entity work.mem_wb
        port map (
            rst => rst, clk => clk,

            stall_i => stall,
            toWriteReg_i => toWriteReg_89,
            writeRegAddr_i => writeRegAddr_89,
            writeRegData_i => writeRegData_89,
            toWriteReg_o => toWriteReg_93,
            writeRegAddr_o => writeRegAddr_93,
            writeRegData_o => writeRegData_93,

            toWriteHi_i => toWriteHi_89,
            toWriteLo_i => toWriteLo_89,
            writeHiData_i => writeHiData_89,
            writeLoData_i => writeLoData_89,
            toWriteHi_o => toWriteHi_9a,
            toWriteLo_o => toWriteLo_9a,
            writeHiData_o => writeHiData_9a,
            writeLoData_o => writeLoData_9a,

            memCP0RegData_i => cp0RegData_89,
            memCP0RegWriteAddr_i => cp0RegWriteAddr_89,
            memCP0RegWriteSel_i => cp0RegWriteSel_89,
            memCP0RegWe_i => cp0RegWe_89,
            cp0Sp_i => cp0Sp_89,
            wbCP0RegData_o => wbCP0RegData_9c,
            wbCP0RegWriteAddr_o => wbCP0RegWriteAddr_9c,
            wbCP0RegWriteSel_o => wbCP0RegWriteSel_9c,
            wbCP0RegWe_o => wbCP0RegWe_9c,
            cp0Sp_o => cp0Sp_9c,
            flush_i => flush_b9,
            currentInstAddr_i => currentInstAddr_89,
            currentInstAddr_o => debug_wb_pc,
            flushForceWrite_i => flushForceWrite_89
        );
    wbToWriteHi_96 <= toWriteHi_9a;
    wbToWriteLo_96 <= toWriteLo_9a;
    wbWriteHiData_96 <= writeHiData_9a;
    wbWriteLoData_96 <= writeLoData_9a;
    wbCP0RegWe_9b <= wbCP0RegWe_9c;
    debug_wb_rf_wen_datapath <= towriteReg_93;
    debug_wb_rf_wnum <= writeRegAddr_93;
    debug_wb_rf_wdata <= writeRegData_93;

    hi_lo_ist: entity work.hi_lo
        port map(
            rst => rst, clk => clk,
            writeHiEnable_i => toWriteHi_9a,
            writeLoEnable_i => toWriteLo_9a,
            writeHiData_i => writeHiData_9a,
            writeLoData_i => writeLoData_9a,
            readHiData_o => hiData_a6,
            readLoData_o => loData_a6
        );

    ctrl_ist: entity work.ctrl
        generic map (
            exceptBootBaseAddr => exceptBootBaseAddr,
            tlbRefillExl0Offset => tlbRefillExl0Offset,
            generalExceptOffset => generalExceptOffset,
            interruptIv1Offset => interruptIv1Offset
        )
        port map(
            rst => rst,
            clk => clk,
            ifToStall_i => ifToStall_i,
            idToStall_i => idToStall_4b,
            blNullify_i => blNullify_4b,
            exToStall_i => exToStall_6b,
            memToStall_i => memToStall_i,
            stall_o => stall,
            flush_o => flush_b1,
            idNextInDelaySlot_i => idIsInDelaySlot_4b,
            newPC_o => newPC_b1,
            exceptionBase_i => cp0EBaseAddr_cb,
            exceptCause_i => exceptCause_cb,
            tlbRefill_i => tlbRefill_cb,
            cp0Status_i => cp0Status_cb,
            cp0Cause_i => cp0Cause_cb,
            cp0Epc_i => cp0Epc_cb,
            depc_i => depc_cb,
            toWriteBadVAddr_o => ctrlToWriteBadVAddr_cb,
            badVAddr_o => ctrlBadVAddr_cb,
            isIdEhb_i => isIdEhb_4b,
            excp0RegWe_i => excp0RegWe_6b,
            memCP0RegWe_i => memCp0RegWe_8b,
            wbcp0regWe_i => wbCP0RegWe_9b,
            scStall_i => scStall_8b
        );
    flush_b2 <= flush_b1;
    flush_b5 <= flush_b1;
    flush_b7 <= flush_b1;
    flush_b9 <= flush_b1;

    cp0_reg_ist: entity work.cp0_reg
        generic map(
            cpuId => cpuId
        )
        port map(
            rst => rst,
            clk => clk,
            we_i => wbCP0RegWe_9c,
            waddr_i => wbCP0RegWriteAddr_9c,
            wsel_i => wbCP0RegWriteSel_9c,
            raddr_i => cp0RegReadAddr_6c,
            rsel_i => cp0RegReadSel_6c,
            data_i => wbCP0RegData_9c,
            int_i => int_i,
            data_o => data_c6,
            timerInt_o => timerInt_o,

            status_o => status_c8,
            cause_o => cause_c8,
            epc_o => epc_c8,
            depc_o => depc_cb,

            valid_i => valid_78,
            exceptCause_i => exceptCause_8c,
            currentInstAddr_i => currentInstAddr_8c,
            currentAccessAddr_i => currentAccessAddr_8c,
            memDataWrite_i => memDataWrite_8c,
            isInDelaySlot_i => isInDelaySlot_8c,
            exceptCause_o => exceptCause_cb,
            isKernelMode_o => isKernelMode_o,
            tlbRefill_i => tlbRefill_8c,
            tlbRefill_o => tlbRefill_cb,

            cp0Sp_i => cp0Sp_9c,
            entryIndex_i => entryIndex_i,
            entryIndexValid_i => entryIndexValid_i,
            entry_i => entry_i,
            entryIndex_o => entryIndex_o,
            entryWrite_o => entryWrite_o,
            entry_o => entry_o,
            entryFlush_o => entryFlush_o,
            pageMask_o => pageMask_o,

            ctrlBadVAddr_i => ctrlBadVAddr_cb,
            ctrlToWriteBadVAddr_i => ctrlToWriteBadVAddr_cb,

            cp0EBaseAddr_o => cp0EBaseAddr_cb
        );
    cp0Status_cb <= status_c8;
    cp0Cause_cb <= cause_c8;
    cp0Epc_cb <= epc_c8;
end bhv;
