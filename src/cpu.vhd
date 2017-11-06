library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.alu_const.all;
use work.mem_const.all;
use work.cp0_const.all;
use work.except_const.all;

entity cpu is
    port (
        rst, clk: in std_logic;
        instData_i: in std_logic_vector(InstWidth);
        instAddr_o: out std_logic_vector(AddrWidth);
        instEnable_o: out std_logic;

        dataEnable_o: out std_logic;
        dataWrite_o: out std_logic;
        dataData_i: in std_logic_vector(DataWidth);
        dataData_o: out std_logic_vector(DataWidth);
        dataAddr_o: out std_logic_vector(AddrWidth);
        dataByteSelect_o: out std_logic_vector(3 downto 0);

        instExcept_i, dataExcept_i: in std_logic_vector(ExceptionCauseWidth);
        ifToStall_i, memToStall_i: in std_logic;

        int_i: in std_logic_vector(intWidth);
        timerInt_o: out std_logic
    );
end cpu;

architecture bhv of cpu is

    component pc_reg
        port (
            rst, clk: in std_logic;
            stall_i: in std_logic_vector(StallWidth);
            pc_o: out std_logic_vector(AddrWidth);
            pcEnable_o: out std_logic;
            branchFlag_i: in std_logic;
            branchTargetAddress_i: in std_logic_vector(AddrWidth);
            flush_i: in std_logic;
            newPC_i: in std_logic_vector(AddrWidth)
        );
    end component;

    component if_id
        port (
            rst, clk: in std_logic;
            pc_i: in std_logic_vector(AddrWidth);
            instEnable_i: in std_logic;
            inst_i: in std_logic_vector(InstWidth);
            exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
            pc_o: out std_logic_vector(AddrWidth);
            inst_o: out std_logic_vector(InstWidth);
            exceptCause_o: out std_logic_vector(ExceptionCauseWidth);
            stall_i: in std_logic_vector(StallWidth);
            flush_i: in std_logic
        );
    end component;

    component regfile
        port (
            rst, clk: in std_logic;
            writeEnable_i: in std_logic;
            writeAddr_i: in std_logic_vector(RegAddrWidth);
            writeData_i: in std_logic_vector(DataWidth);
            readEnable1_i: in std_logic;
            readAddr1_i: in std_logic_vector(RegAddrWidth);
            readData1_o: out std_logic_vector(DataWidth);
            readEnable2_i: in std_logic;
            readAddr2_i: in std_logic_vector(RegAddrWidth);
            readData2_o: out std_logic_vector(DataWidth)
        );
    end component;

    component id
        port (
            rst: in std_logic;
            pc_i: in std_logic_vector(AddrWidth);
            inst_i: in std_logic_vector(InstWidth);
            regData1_i: in std_logic_vector(DataWidth);
            regData2_i: in std_logic_vector(DataWidth);

            exToWriteReg_i: in std_logic;
            exWriteRegAddr_i: in std_logic_vector(RegAddrWidth);
            exWriteRegData_i: in std_logic_vector(DataWidth);
            memToWriteReg_i: in std_logic;
            memWriteRegAddr_i: in std_logic_vector(RegAddrWidth);
            memWriteRegData_i: in std_logic_vector(DataWidth);
            isInDelaySlot_i: in std_logic;

            toStall_o: out std_logic;
            regReadEnable1_o: out std_logic;
            regReadEnable2_o: out std_logic;
            regReadAddr1_o: out std_logic_vector(RegAddrWidth);
            regReadAddr2_o: out std_logic_vector(RegAddrWidth);
            alut_o: out AluType;
            memt_o: out MemType;
            lastMemt_i: in MemType;
            operand1_o: out std_logic_vector(DataWidth);
            operand2_o: out std_logic_vector(DataWidth);
            operandX_o: out std_logic_vector(DataWidth);
            toWriteReg_o: out std_logic;
            writeRegAddr_o: out std_logic_vector(RegAddrWidth);

            branchTargetAddress_o: out std_logic_vector(AddrWidth);
            branchFlag_o: out std_logic;
            linkAddr_o: out std_logic_vector(AddrWidth);
            isInDelaySlot_o: out std_logic;
            nextInstInDelaySlot_o: out std_logic;

            exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
            exceptCause_o: out std_logic_vector(ExceptionCauseWidth);
            currentInstAddr_o: out std_logic_vector(AddrWidth)
        );
    end component;

    component id_ex
        port (
            rst, clk: in std_logic;
            stall_i: in std_logic_vector(StallWidth);
            alut_i: in AluType;
            memt_i: in MemType;
            operand1_i: in std_logic_vector(DataWidth);
            operand2_i: in std_logic_vector(DataWidth);
            operandX_i: in std_logic_vector(DataWidth);
            toWriteReg_i: in std_logic;
            writeRegAddr_i: in std_logic_vector(RegAddrWidth);
            idIsInDelaySlot_i: in std_logic;
            idLinkAddress_i: in std_logic_vector(AddrWidth);
            nextInstInDelaySlot_i: in std_logic;

            alut_o: out AluType;
            memt_o: out MemType;
            operand1_o: out std_logic_vector(DataWidth);
            operand2_o: out std_logic_vector(DataWidth);
            operandX_o: out std_logic_vector(DataWidth);
            toWriteReg_o: out std_logic;
            writeRegAddr_o: out std_logic_vector(RegAddrWidth);
            exIsInDelaySlot_o: out std_logic;
            exLinkAddress_o: out std_logic_vector(AddrWidth);
            isInDelaySlot_o: out std_logic;

            flush_i: in std_logic;
            idExceptCause_i: in std_logic_vector(ExceptionCauseWidth);
            idCurrentInstAddr_i: in std_logic_vector(AddrWidth);
            exExceptCause_o: out std_logic_vector(ExceptionCauseWidth);
            exCurrentInstAddr_o: out std_logic_vector(AddrWidth)
        );
    end component;

    component ex
        port (
            rst: in std_logic;
            alut_i: in AluType;
            memt_i: in MemType;
            operand1_i: in std_logic_vector(DataWidth);
            operand2_i: in std_logic_vector(DataWidth);
            operandX_i: in std_logic_vector(DataWidth);
            toWriteReg_i: in std_logic;
            writeRegAddr_i: in std_logic_vector(RegAddrWidth);
            isInDelaySlot_i: in std_logic;
            linkAddress_i: in std_logic_vector(AddrWidth);

            toStall_o: out std_logic;
            toWriteReg_o: out std_logic;
            writeRegAddr_o: out std_logic_vector(RegAddrWidth);
            writeRegData_o: out std_logic_vector(DataWidth);

            hi_i, lo_i: in std_logic_vector(DataWidth);
            memToWriteHi_i, memToWriteLo_i: in std_logic;
            memWriteHiData_i, memWriteLoData_i: in std_logic_vector(DataWidth);
            wbToWriteHi_i, wbToWriteLo_i: in std_logic;
            wbWriteHiData_i, wbWriteLoData_i: in std_logic_vector(DataWidth);
            toWriteHi_o, toWriteLo_o: out std_logic;
            writeHiData_o, writeLoData_o: out std_logic_vector(DataWidth);

            memt_o: out MemType;
            memAddr_o: out std_logic_vector(AddrWidth);
            memData_o: out std_logic_vector(DataWidth);

            tempProduct_i: in std_logic_vector(DoubleDataWidth);
            cnt_i: in std_logic_vector(CntWidth);
            tempProduct_o: out std_logic_vector(DoubleDataWidth);
            cnt_o: out std_logic_vector(CntWidth);

            -- for cp0 coprocessor --
            cp0RegData_i: in std_logic_vector(DataWidth);
            wbCP0RegData_i: in std_logic_vector(DataWidth);
            wbCP0RegWriteAddr_i: in std_logic_vector(CP0RegAddrWidth);
            wbCP0RegWe_i: in std_logic;
            memCP0RegData_i: in std_logic_vector(DataWidth);
            memCP0RegWriteAddr_i: in std_logic_vector(CP0RegAddrWidth);
            memCP0RegWe_i: in std_logic;
            cp0RegReadAddr_o: out std_logic_vector(CP0RegAddrWidth);
            cp0RegData_o: out std_logic_vector(DataWidth);
            cp0RegWriteAddr_o: out std_logic_vector(CP0RegAddrWidth);
            cp0RegWe_o: out std_logic;

            -- for exception --
            exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
            currentInstAddr_i: in std_logic_vector(AddrWidth);
            exceptCause_o: out std_logic_vector(ExceptionCauseWidth);
            currentInstAddr_o: out std_logic_vector(AddrWidth);
            isInDelaySlot_o: out std_logic
        );
    end component;

    component ex_mem
        port (
            rst, clk: in std_logic;
            stall_i: in std_logic_vector(StallWidth);
            toWriteReg_i: in std_logic;
            writeRegAddr_i: in std_logic_vector(RegAddrWidth);
            writeRegData_i: in std_logic_vector(DataWidth);
            toWriteReg_o: out std_logic;
            writeRegAddr_o: out std_logic_vector(RegAddrWidth);
            writeRegData_o: out std_logic_vector(DataWidth);

            toWriteHi_i, toWriteLo_i: in std_logic;
            writeHiData_i, writeLoData_i: in std_logic_vector(DataWidth);
            toWriteHi_o, toWriteLo_o: out std_logic;
            writeHiData_o, writeLoData_o: out std_logic_vector(DataWidth);

            memt_i: in MemType;
            memAddr_i: in std_logic_vector(AddrWidth);
            memData_i: in std_logic_vector(DataWidth);
            memt_o: out MemType;
            memAddr_o: out std_logic_vector(AddrWidth);
            memData_o: out std_logic_vector(DataWidth);

            tempProduct_i: in std_logic_vector(DoubleDataWidth);
            cnt_i: in std_logic_vector(CntWidth);
            tempProduct_o: out std_logic_vector(DoubleDataWidth);
            cnt_o: out std_logic_vector(CntWidth);

            -- for cp0 coprocessor --
            cp0RegData_i: in std_logic_vector(DataWidth);
            cp0RegWriteAddr_i: in std_logic_vector(cp0RegAddrWidth);
            cp0RegWe_i: in std_logic;
            cp0RegData_o: out std_logic_vector(DataWidth);
            cp0RegWriteAddr_o: out std_logic_vector(CP0RegAddrWidth);
            cp0RegWe_o: out std_logic;

            -- for exception --
            flush_i: in std_logic;
            exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
            currentInstAddr_i: in std_logic_vector(AddrWidth);
            isInDelaySlot_i: in std_logic;
            exceptCause_o: out std_logic_vector(ExceptionCauseWidth);
            currentInstAddr_o: out std_logic_vector(AddrWidth);
            isInDelaySlot_o: out std_logic
        );
    end component;

    component mem
        port (
            rst: in std_logic;
            toWriteReg_i: in std_logic;
            writeRegAddr_i: in std_logic_vector(RegAddrWidth);
            writeRegData_i: in std_logic_vector(DataWidth);
            toWriteReg_o: out std_logic;
            writeRegAddr_o: out std_logic_vector(RegAddrWidth);
            writeRegData_o: out std_logic_vector(DataWidth);

            toWriteHi_i, toWriteLo_i: in std_logic;
            writeHiData_i, writeLoData_i: in std_logic_vector(DataWidth);
            toWriteHi_o, toWriteLo_o: out std_logic;
            writeHiData_o, writeLoData_o: out std_logic_vector(DataWidth);

            memt_i: in MemType;
            memAddr_i: in std_logic_vector(AddrWidth);
            memData_i: in std_logic_vector(DataWidth); -- Data to store
            loadedData_i: in std_logic_vector(DataWidth); -- Data loaded from RAM
            savingData_o: out std_logic_vector(DataWidth);
            memAddr_o: out std_logic_vector(AddrWidth);
            dataEnable_o: out std_logic;
            dataWrite_o: out std_logic;
            dataByteSelect_o: out std_logic_vector(3 downto 0);

            -- for cp0 coprocessor --
            cp0RegData_i: in std_logic_vector(DataWidth);
            cp0RegWriteAddr_i: in std_logic_vector(CP0RegAddrWidth);
            cp0RegWe_i: in std_logic;
            cp0RegData_o: out std_logic_vector(DataWidth);
            cp0RegWriteAddr_o: out std_logic_vector(CP0RegAddrWidth);
            cp0RegWe_o: out std_logic;

            -- for exception --
            exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
            currentInstAddr_i: in std_logic_vector(AddrWidth);
            isInDelaySlot_i: in std_logic;
            cp0Status_i: in std_logic_vector(DataWidth);
            cp0Cause_i: in std_logic_vector(DataWidth);
            cp0Epc_i: in std_logic_vector(DataWidth);
            wbCP0RegWe_i: in std_logic;
            wbCP0RegWriteAddr_i: in std_logic_vector(CP0RegAddrWidth);
            wbCP0RegData_i: in std_logic_vector(DataWidth);
            cp0EPC_o: out std_logic_vector(DataWidth);
            exceptCause_o: out std_logic_vector(ExceptionCauseWidth);
            currentInstAddr_o: out std_logic_vector(AddrWidth);
            isInDelaySlot_o: out std_logic
        );
    end component;

    component mem_wb
        port (
            rst, clk: in std_logic;
            stall_i: in std_logic_vector(StallWidth);
            toWriteReg_i: in std_logic;
            writeRegAddr_i: in std_logic_vector(RegAddrWidth);
            writeRegData_i: in std_logic_vector(DataWidth);
            toWriteReg_o: out std_logic;
            writeRegAddr_o: out std_logic_vector(RegAddrWidth);
            writeRegData_o: out std_logic_vector(DataWidth);

            toWriteHi_i, toWriteLo_i: in std_logic;
            writeHiData_i, writeLoData_i: in std_logic_vector(DataWidth);
            toWriteHi_o, toWriteLo_o: out std_logic;
            writeHiData_o, writeLoData_o: out std_logic_vector(DataWidth);

            -- for cp0 coprocessor --
            memCP0RegData_i: in std_logic_vector(DataWidth);
            memCP0RegWriteAddr_i: in std_logic_vector(CP0RegAddrWidth);
            memCP0RegWe_i: in std_logic;
            wbCP0RegData_o: out std_logic_vector(DataWidth);
            wbCP0RegWriteAddr_o: out std_logic_vector(CP0RegAddrWidth);
            wbCP0RegWe_o: out std_logic;

            -- for exception --
            flush_i: in std_logic
        );
    end component;

    component hi_lo
        port (
            rst, clk: in std_logic;
            writeHiEnable_i, writeLoEnable_i: in std_logic;
            writeHiData_i, writeLoData_i: in std_logic_vector(DataWidth);
            readHiData_o, readLoData_o: out std_logic_vector(DataWidth)
        );
    end component;

    component ctrl is
        port (
            rst: in std_logic;
            ifToStall_i, idToStall_i, exToStall_i, memToStall_i: in std_logic;
            stall_o: out std_logic_vector(StallWidth);
            cp0Epc_i: in std_logic_vector(DataWidth);
            exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
            newPC_o: out std_logic_vector(AddrWidth);
            flush_o: out std_logic
        );
    end component;

    component cp0_reg
        port (
            clk, rst: in std_logic;
            raddr_i: in std_logic_vector(CP0RegAddrWidth);
            data_i: in std_logic_vector(DataWidth);
            waddr_i: in std_logic_vector(CP0RegAddrWidth);
            we_i: in std_logic;
            int_i: in std_logic_vector(intWidth);

            data_o: out std_logic_vector(DataWidth);
            status_o: out std_logic_vector(DataWidth);
            count_o: out std_logic_vector(DataWidth);
            compare_o: out std_logic_vector(DataWidth);
            cause_o: out std_logic_vector(DataWidth);
            epc_o: out std_logic_vector(DataWidth);
            config_o: out std_logic_vector(DataWidth);
            prid_o: out std_logic_vector(DataWidth);
            timerInt_o: out std_logic;

            exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
            currentInstAddr_i: in std_logic_vector(AddrWidth);
            isInDelaySlot_i: in std_logic
        );
    end component;

    component conv_endian
        port (
            input: in std_logic_vector(31 downto 0);
            output: out std_logic_vector(31 downto 0)
        );
    end component;

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
    -- x: conv_endian

    -- Signal connecting pc_reg and if_id --
    signal pc_12: std_logic_vector(AddrWidth);
    signal instEnable_12: std_logic;

    -- Signals connecting if_id and id --
    signal pc_24: std_logic_vector(AddrWidth);
    signal inst_24: std_logic_vector(InstWidth);
    signal exceptCause_24: std_logic_vector(ExceptionCauseWidth);

    -- Signals connecting conv_endian and if_id --
    signal inst_x2: std_logic_vector(InstWidth);

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
    signal exceptCause_45: std_logic_vector(ExceptionCauseWidth);
    signal currentInstAddr_45: std_logic_vector(AddrWidth);

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
    signal exCurrentInstAddr_56: std_logic_vector(AddrWidth);

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
    signal cp0RegWe_67: std_logic;
    signal tempProduct_67, tempProduct_76: std_logic_vector(DoubleDataWidth);
    signal cnt_67, cnt_76: std_logic_vector(CntWidth);
    signal exceptCause_67: std_logic_vector(ExceptionCauseWidth);
    signal currentInstAddr_67: std_logic_vector(AddrWidth);
    signal isInDelaySlot_67: std_logic;

    -- Signals connecting ex and cp0 --
    signal cp0RegReadAddr_6c: std_logic_vector(CP0RegAddrWidth);

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
    signal cp0RegWe_78: std_logic;
    signal exceptCause_78: std_logic_vector(ExceptionCauseWidth);
    signal currentInstAddr_78: std_logic_vector(AddrWidth);
    signal isInDelaySlot_78: std_logic;

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
    signal cp0RegWe_89: std_logic;
    signal wbCP0RegWe_98: std_logic;
    signal wbCP0RegWriteAddr_98: std_logic_vector(CP0RegAddrWidth);
    signal wbCP0RegData_98: std_logic_vector(DataWidth);

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
    signal wbCP0RegData_96: std_logic_vector(DataWidth);
    signal wbCP0RegWriteAddr_96: std_logic_vector(CP0RegAddrWidth);
    signal wbCP0RegWe_96: std_logic;

    -- Signals connecting mem_wb and cp0 --
    signal wbCP0RegData_9c: std_logic_vector(DataWidth);
    signal wbCP0RegWriteAddr_9c: std_logic_vector(CP0RegAddrWidth);
    signal wbCP0RegWe_9c: std_logic;

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

    -- Signals connecting id and ctrl --
    signal idToStall_4b: std_logic;

    -- Signals connecting ex and ctrl --
    signal exToStall_6b: std_logic;

    -- Signals connecting ctrl and others --
    signal stall: std_logic_vector(StallWidth);

    -- Signals connecting id and pc --
    signal branchTargetAddress_41: std_logic_vector(AddrWidth);
    signal branchFlag_41: std_logic;

    -- Signals connecting cp0 and ex --
    signal data_c6: std_logic_vector(DataWidth);

    -- Signals connecting cp0 and mem --
    signal status_c8: std_logic_vector(DataWidth);
    signal cause_c8: std_logic_vector(DataWidth);
    signal epc_c8: std_logic_vector(AddrWidth);
    signal exceptCause_8c: std_logic_vector(ExceptionCauseWidth);
    signal currentInstAddr_8c: std_logic_vector(AddrWidth);
    signal isInDelaySlot_8c: std_logic;

    -- Signals connecting cp0 and ctrl --
    signal cp0Epc_8b: std_logic_vector(DataWidth);
    signal exceptCause_8b: std_logic_vector(ExceptionCauseWidth);

begin

    pc_reg_ist: pc_reg
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

    if_id_ist: if_id
        port map (
            rst => rst, clk => clk,
            stall_i => stall,
            pc_i => pc_12,
            instEnable_i => instEnable_12,
            inst_i => inst_x2,
            exceptCause_i => instExcept_i,
            pc_o => pc_24,
            inst_o => inst_24,
            flush_i => flush_b2,
            exceptCause_o => exceptCause_24
        );
    instAddr_o <= pc_12;

    conv_endian_ist: conv_endian
        port map (
            input => instData_i,
            output => inst_x2
        );

    regfile_ist: regfile
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

    id_ist: id
        port map (
            rst => rst,
            pc_i => pc_24,
            inst_i => inst_24,
            regData1_i => regData1_34,
            regData2_i => regData2_34,
            exToWriteReg_i => exToWriteReg_64,
            exWriteRegAddr_i => exWriteRegAddr_64,
            exWriteRegData_i => exWriteRegData_64,
            memToWriteReg_i => memToWriteReg_84,
            memWriteRegAddr_i => memWriteRegAddr_84,
            memWriteRegData_i => memWriteRegData_84,
            isInDelaySlot_i => isInDelaySlot_54,
            toStall_o => idToStall_4b,
            regReadEnable1_o => regReadEnable1_43,
            regReadEnable2_o => regReadEnable2_43,
            regReadAddr1_o => regReadAddr1_43,
            regReadAddr2_o => regReadAddr2_43,
            alut_o => alut_45,
            memt_o => memt_45,
            lastMemt_i => lastMemt_64,
            operand1_o => operand1_45,
            operand2_o => operand2_45,
            operandX_o => operandX_45,
            toWriteReg_o => toWriteReg_45,
            writeRegAddr_o => writeRegAddr_45,
            isInDelaySlot_o => isInDelaySlot_45,
            linkAddr_o => linkAddr_45,
            nextInstInDelaySlot_o => nextInstInDelaySlot_45,
            branchTargetAddress_o => branchTargetAddress_41,
            branchFlag_o => branchFlag_41,
            exceptCause_i => exceptCause_24,
            exceptCause_o => exceptCause_45,
            currentInstAddr_o => currentInstAddr_45
        );

    id_ex_ist: id_ex
        port map (
            rst => rst, clk => clk,
            stall_i => stall,
            alut_i => alut_45,
            memt_i => memt_45,
            operand1_i => operand1_45,
            operand2_i => operand2_45,
            operandX_i => operandX_45,
            toWriteReg_i => toWriteReg_45,
            writeRegAddr_i => writeRegAddr_45,
            idIsInDelaySlot_i => isInDelaySlot_45,
            idLinkAddress_i => linkAddr_45,
            nextInstInDelaySlot_i => nextInstInDelaySlot_45,
            flush_i => flush_b5,
            idExceptCause_i => exceptCause_45,
            idCurrentInstAddr_i => currentInstAddr_45,
            alut_o => alut_56,
            memt_o => memt_56,
            operand1_o => operand1_56,
            operand2_o => operand2_56,
            operandX_o => operandX_56,
            toWriteReg_o => toWriteReg_56,
            writeRegAddr_o => writeRegAddr_56,
            isInDelaySlot_o => isInDelaySlot_54,
            exIsInDelaySlot_o => exIsInDelaySlot_56,
            exLinkAddress_o => exLinkAddress_56,
            exExceptCause_o => exExceptCause_56,
            exCurrentInstAddr_o => exCurrentInstAddr_56
        );

    ex_ist: ex
        port map (
            rst => rst,
            alut_i => alut_56,
            memt_i => memt_56,
            operand1_i => operand1_56,
            operand2_i => operand2_56,
            operandX_i => operandX_56,
            toWriteReg_i => toWriteReg_56,
            writeRegAddr_i => writeRegAddr_56,
            isInDelaySlot_i => exIsInDelaySlot_56,
            linkAddress_i => exLinkAddress_56,
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

            cp0RegData_i => data_c6,
            wbCP0RegData_i => wbCP0RegData_96,
            wbCP0RegWriteAddr_i => wbCP0RegWriteAddr_96,
            wbCP0RegWe_i => wbCP0RegWe_96,
            memCP0RegData_i => cp0RegData_86,
            memCP0RegWriteAddr_i => cp0RegWriteAddr_86,
            memCP0RegWe_i => cp0RegWe_86,
            cp0RegReadAddr_o => cp0RegReadAddr_6c,
            cp0RegData_o => cp0RegData_67,
            cp0RegWriteAddr_o => cp0RegWriteAddr_67,
            cp0RegWe_o => cp0RegWe_67,

            exceptCause_i => exExceptCause_56,
            currentInstAddr_i => exCurrentInstAddr_56,
            exceptCause_o => exceptCause_67,
            currentInstAddr_o => currentInstAddr_67,
            isInDelaySlot_o => isInDelaySlot_67
        );
    exToWriteReg_64 <= toWriteReg_67;
    exWriteRegAddr_64 <= writeRegAddr_67;
    exWriteRegData_64 <= writeRegData_67;
    lastMemt_64 <= memt_67;

    ex_mem_ist: ex_mem
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
            cp0RegWe_i => cp0RegWe_67,
            cp0RegData_o => cp0RegData_78,
            cp0RegWriteAddr_o => cp0RegWriteAddr_78,
            cp0RegWe_o => cp0RegWe_78,

            flush_i => flush_b7,
            exceptCause_i => exceptCause_67,
            currentInstAddr_i => currentInstAddr_67,
            isInDelaySlot_i => isInDelaySlot_67,
            exceptCause_o => exceptCause_78,
            currentInstAddr_o => currentInstAddr_78,
            isInDelaySlot_o => isInDelaySlot_78
        );

    mem_ist: mem
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
            dataEnable_o => dataEnable_o,
            dataWrite_o => dataWrite_o,
            loadedData_i => dataData_i,
            savingData_o => dataData_o,
            memAddr_o => dataAddr_o,
            dataByteSelect_o => dataByteSelect_o,

            cp0RegData_i => cp0RegData_78,
            cp0RegWriteAddr_i => cp0RegWriteAddr_78,
            cp0RegWe_i => cp0RegWe_78,
            cp0RegData_o => cp0RegData_89,
            cp0RegWriteAddr_o => cp0RegWriteAddr_89,
            cp0RegWe_o => cp0RegWe_89,
            exceptCause_i => exceptCause_78 and dataExcept_i,
            -- If exceptCause_78 = NO_CAUSE (0x1f), exceptCause_i = dataExcept_i
            -- If exceptCause_78 /= NO_CAUSE, dataEnable_o = DISABLE, dataExcept_i = NO_CAUSE, so exceptCause_i = exceptCause_78
            currentInstAddr_i => currentInstAddr_78,
            isInDelaySlot_i => isInDelaySlot_78,

            cp0Status_i => status_c8,
            cp0Cause_i => cause_c8,
            cp0Epc_i => epc_c8,
            wbCP0RegWe_i => wbCP0RegWe_98,
            wbCP0RegWriteAddr_i => wbCP0RegWriteAddr_98,
            wbCP0RegData_i => wbCP0RegData_98,
            cp0EPC_o => cp0EPC_8b,
            exceptCause_o => exceptCause_8c,
            currentInstAddr_o => currentInstAddr_8c,
            isInDelaySlot_o => isInDelaySlot_8c
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
    exceptCause_8b <= exceptCause_8c;

    mem_wb_ist: mem_wb
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
            memCP0RegWe_i => cp0RegWe_89,
            wbCP0RegData_o => wbCP0RegData_9c,
            wbCP0RegWriteAddr_o => wbCP0RegWriteAddr_9c,
            wbCP0RegWe_o => wbCP0RegWe_9c,
            flush_i => flush_b9
        );
    wbToWriteHi_96 <= toWriteHi_9a;
    wbToWriteLo_96 <= toWriteLo_9a;
    wbWriteHiData_96 <= writeHiData_9a;
    wbWriteLoData_96 <= writeLoData_9a;
    wbCP0RegData_96 <= wbCP0RegData_9c;
    wbCP0RegWriteAddr_96 <= wbCP0RegWriteAddr_9c;
    wbCP0RegWe_96 <= wbCP0RegWe_9c;
    wbCP0RegData_98 <= wbCP0RegData_96;
    wbCP0RegWriteAddr_98 <= wbCP0RegWriteAddr_96;
    wbCP0RegWe_98 <= wbCP0RegWe_96;

    hi_lo_ist: hi_lo
        port map(
            rst => rst, clk => clk,
            writeHiEnable_i => toWriteHi_9a,
            writeLoEnable_i => toWriteLo_9a,
            writeHiData_i => writeHiData_9a,
            writeLoData_i => writeLoData_9a,
            readHiData_o => hiData_a6,
            readLoData_o => loData_a6
        );

    ctrl_ist: ctrl
        port map(
            rst => rst,
            ifToStall_i => ifToStall_i,
            idToStall_i => idToStall_4b,
            exToStall_i => exToStall_6b,
            memToStall_i => memToStall_i,
            stall_o => stall,
            flush_o => flush_b1,
            newPC_o => newPC_b1,
            exceptCause_i => exceptCause_8b,
            cp0Epc_i => cp0EPC_8b
        );
    flush_b2 <= flush_b1;
    flush_b5 <= flush_b1;
    flush_b7 <= flush_b1;
    flush_b9 <= flush_b1;

    cp0_reg_ist: cp0_reg
        port map(
            rst => rst,
            clk => clk,
            int_i => int_i,
            raddr_i => cp0RegReadAddr_6c,
            data_i => wbCP0RegData_9c,
            waddr_i => wbCP0RegWriteAddr_9c,
            we_i => wbCP0RegWe_9c,
            data_o => data_c6,
            exceptCause_i => exceptCause_8c,
            currentInstAddr_i => currentInstAddr_8c,
            isInDelaySlot_i => isInDelaySlot_8c,
            epc_o => epc_c8,
            status_o => status_c8,
            cause_o => cause_c8,
            timerInt_o => timerInt_o
        );
end bhv;
