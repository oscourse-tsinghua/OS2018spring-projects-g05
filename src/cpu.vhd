library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.alu_const.all;

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
            pcEnable_o: out std_logic
        );
    end component;

    component if_id
        port (
            rst, clk: in std_logic;
            stall_i: in std_logic_vector(StallWidth);
            pc_i: in std_logic_vector(AddrWidth);
            inst_i: in std_logic_vector(InstWidth);
            pc_o: out std_logic_vector(AddrWidth);
            inst_o: out std_logic_vector(InstWidth)
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

            toStall_o: out std_logic;
            regReadEnable1_o: out std_logic;
            regReadEnable2_o: out std_logic;
            regReadAddr1_o: out std_logic_vector(RegAddrWidth);
            regReadAddr2_o: out std_logic_vector(RegAddrWidth);
            alut_o: out AluType;
            operand1_o: out std_logic_vector(DataWidth);
            operand2_o: out std_logic_vector(DataWidth);
            toWriteReg_o: out std_logic;
            writeRegAddr_o: out std_logic_vector(RegAddrWidth)
        );
    end component;

    component id_ex
        port (
            rst, clk: in std_logic;
            stall_i: in std_logic_vector(StallWidth);
            alut_i: in AluType;
            operand1_i: in std_logic_vector(DataWidth);
            operand2_i: in std_logic_vector(DataWidth);
            toWriteReg_i: in std_logic;
            writeRegAddr_i: in std_logic_vector(RegAddrWidth);

            alut_o: out AluType;
            operand1_o: out std_logic_vector(DataWidth);
            operand2_o: out std_logic_vector(DataWidth);
            toWriteReg_o: out std_logic;
            writeRegAddr_o: out std_logic_vector(RegAddrWidth)
        );
    end component;

    component ex
        port (
            rst: in std_logic;
            alut_i: in AluType;
            operand1_i: in std_logic_vector(DataWidth);
            operand2_i: in std_logic_vector(DataWidth);
            toWriteReg_i: in std_logic;
            writeRegAddr_i: in std_logic_vector(RegAddrWidth);

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

            tempProduct_i: in std_logic_vector(DoubleDataWidth);
            cnt_i: in std_logic_vector(CntWidth);
            tempProduct_o: out std_logic_vector(DoubleDataWidth);
            cnt_o: out std_logic_vector(CntWidth)
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

            tempProduct_i: in std_logic_vector(DoubleDataWidth);
            cnt_i: in std_logic_vector(CntWidth);
            tempProduct_o: out std_logic_vector(DoubleDataWidth);
            cnt_o: out std_logic_vector(CntWidth)
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
            writeHiData_o, writeLoData_o: out std_logic_vector(DataWidth)
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
            writeHiData_o, writeLoData_o: out std_logic_vector(DataWidth)
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
            idToStall_i, exToStall_i: in std_logic;
            stall_o: out std_logic_vector(StallWidth)
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
    -- x: conv_endian

    -- Signals connecting pc_reg and if_id --
    signal pc_12: std_logic_vector(AddrWidth);

    -- Signals connecting if_id and id --
    signal pc_24: std_logic_vector(AddrWidth);
    signal inst_24: std_logic_vector(InstWidth);

    -- Signals connecting conv_endian and if_id --
    signal inst_x2: std_logic_vector(InstWidth);

    -- Signals connecting regfile and id --
    signal regReadEnable1_43, regReadEnable2_43: std_logic;
    signal regReadAddr1_43, regReadAddr2_43: std_logic_vector(RegAddrWidth);
    signal regData1_34, regData2_34: std_logic_vector(DataWidth);

    -- Signals connecting id and id_ex --
    signal alut_45: AluType;
    signal operand1_45: std_logic_vector(DataWidth);
    signal operand2_45: std_logic_vector(DataWidth);
    signal toWriteReg_45: std_logic;
    signal writeRegAddr_45: std_logic_vector(RegAddrWidth);

    -- Signals connecting id_ex and ex --
    signal alut_56: AluType;
    signal operand1_56: std_logic_vector(DataWidth);
    signal operand2_56: std_logic_vector(DataWidth);
    signal toWriteReg_56: std_logic;
    signal writeRegAddr_56: std_logic_vector(RegAddrWidth);

    -- Signals connecting ex and id --
    signal exToWriteReg_64: std_logic;
    signal exWriteRegAddr_64: std_logic_vector(RegAddrWidth);
    signal exWriteRegData_64: std_logic_vector(DataWidth);

    -- Signals connecting ex and ex_mem --
    signal toWriteReg_67: std_logic;
    signal writeRegAddr_67: std_logic_vector(RegAddrWidth);
    signal writeRegData_67: std_logic_vector(DataWidth);
    signal toWriteHi_67, toWriteLo_67: std_logic;
    signal writeHiData_67, writeLoData_67: std_logic_vector(DataWidth);
    signal tempProduct_67, tempProduct_76: std_logic_vector(DoubleDataWidth);
    signal cnt_67, cnt_76: std_logic_vector(CntWidth);

    -- Signals connecting ex_mem and mem --
    signal toWriteReg_78: std_logic;
    signal writeRegAddr_78: std_logic_vector(RegAddrWidth);
    signal writeRegData_78: std_logic_vector(DataWidth);
    signal toWriteHi_78, toWriteLo_78: std_logic;
    signal writeHiData_78, writeLoData_78: std_logic_vector(DataWidth);

    -- Signals connecting mem and id --
    signal memToWriteReg_84: std_logic;
    signal memWriteRegAddr_84: std_logic_vector(RegAddrWidth);
    signal memWriteRegData_84: std_logic_vector(DataWidth);

    -- Signals connecting mem and ex --
    signal memToWriteHi_86, memToWriteLo_86: std_logic;
    signal memWriteHiData_86, memWriteLoData_86: std_logic_vector(DataWidth);

    -- Signals connecting mem and mem_wb --
    signal toWriteReg_89: std_logic;
    signal writeRegAddr_89: std_logic_vector(RegAddrWidth);
    signal writeRegData_89: std_logic_vector(DataWidth);
    signal toWriteHi_89, toWriteLo_89: std_logic;
    signal writeHiData_89, writeLoData_89: std_logic_vector(DataWidth);

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

    -- Signals connecting hi_lo and ex --
    signal hiData_a6, loData_a6: std_logic_vector(DataWidth);

    -- Signals connecting id and ctrl --
    signal idToStall_4b: std_logic;

    -- Signals connecting ex and ctrl --
    signal exToStall_6b: std_logic;

    -- Signals connecting ctrl and others --
    signal stall: std_logic_vector(StallWidth);

begin

    pc_reg_ist: pc_reg
        port map (
           rst => rst, clk => clk,
           stall_i => stall,
           pc_o => pc_12,
           pcEnable_o => instEnable_o
        );

    if_id_ist: if_id
        port map (
            rst => rst, clk => clk,
            stall_i => stall,
            pc_i => pc_12,
            inst_i => inst_x2,
            pc_o => pc_24,
            inst_o => inst_24
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
            toStall_o => idToStall_4b,
            regReadEnable1_o => regReadEnable1_43,
            regReadEnable2_o => regReadEnable2_43,
            regReadAddr1_o => regReadAddr1_43,
            regReadAddr2_o => regReadAddr2_43,
            alut_o => alut_45,
            operand1_o => operand1_45,
            operand2_o => operand2_45,
            toWriteReg_o => toWriteReg_45,
            writeRegAddr_o => writeRegAddr_45
        ); 

    id_ex_ist: id_ex
        port map (
            rst => rst, clk => clk,
            stall_i => stall,
            alut_i => alut_45,
            operand1_i => operand1_45,
            operand2_i => operand2_45,
            toWriteReg_i => toWriteReg_45,
            writeRegAddr_i => writeRegAddr_45,
            alut_o => alut_56,
            operand1_o => operand1_56,
            operand2_o => operand2_56,
            toWriteReg_o => toWriteReg_56,
            writeRegAddr_o => writeRegAddr_56
        );

    ex_ist: ex
        port map (
            rst => rst,
            alut_i => alut_56,
            operand1_i => operand1_56,
            operand2_i => operand2_56,
            toWriteReg_i => toWriteReg_56,
            writeRegAddr_i => writeRegAddr_56,
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

            tempProduct_i => tempProduct_76,
            cnt_i => cnt_76,
            tempProduct_o => tempProduct_67,
            cnt_o => cnt_67
        );
    exToWriteReg_64 <= toWriteReg_67;
    exWriteRegAddr_64 <= writeRegAddr_67;
    exWriteRegData_64 <= writeRegData_67;

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

            tempProduct_i => tempProduct_67,
            cnt_i => cnt_67,
            tempProduct_o => tempProduct_76,
            cnt_o => cnt_76
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
            writeLoData_o => writeLoData_89
        );
    memToWriteReg_84 <= toWriteReg_89;
    memWriteRegAddr_84 <= writeRegAddr_89;
    memWriteRegData_84 <= writeRegData_89;
    memToWriteHi_86 <= toWriteHi_89;
    memToWriteLo_86 <= toWriteLo_89;
    memWriteHiData_86 <= writeHiData_89;
    memWriteLoData_86 <= writeLoData_89;

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
            writeLoData_o => writeLoData_9a
        );
    wbToWriteHi_96 <= toWriteHi_9a;
    wbToWriteLo_96 <= toWriteLo_9a;
    wbWriteHiData_96 <= writeHiData_9a;
    wbWriteLoData_96 <= writeLoData_9a;

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
            idToStall_i => idToStall_4b,
            exToStall_i => exToStall_6b,
            stall_o => stall
        );

end bhv;