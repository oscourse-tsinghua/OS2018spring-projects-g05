library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.inst_const.all;
use work.alu_const.all;

entity id is
    port (
        rst: in std_logic;
        pc_i: in std_logic_vector(AddrWidth);
        inst_i: in std_logic_vector(InstWidth);
        regData1_i: in std_logic_vector(DataWidth);
        regData2_i: in std_logic_vector(DataWidth);

        -- Push Forward --
        exToWriteReg_i: in std_logic;
        exWriteRegAddr_i: in std_logic_vector(RegAddrWidth);
        exWriteRegData_i: in std_logic_vector(DataWidth);
        memToWriteReg_i: in std_logic;
        memWriteRegAddr_i: in std_logic_vector(RegAddrWidth);
        memWriteRegData_i: in std_logic_vector(DataWidth);

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
end id;

architecture bhv of id is
    signal instOp:   std_logic_vector(InstOpWidth);
    signal instRs:   std_logic_vector(InstRsWidth);
    signal instRt:   std_logic_vector(InstRtWidth);
    signal instRd:   std_logic_vector(InstRdWidth);
    signal instSa:   std_logic_vector(InstSaWidth);
    signal instFunc: std_logic_vector(InstFuncWidth);
    signal instImm:  std_logic_vector(InstImmWidth);
    signal instAddr: std_logic_vector(InstAddrWidth);
begin

    -- Segment the instruction --
    instOp   <= inst_i(InstOpIdx);
    instRs   <= inst_i(InstRsIdx);
    instRt   <= inst_i(InstRtIdx);
    instRd   <= inst_i(InstRdIdx);
    instSa   <= inst_i(InstSaIdx);
    instFunc <= inst_i(InstFuncIdx);
    instImm  <= inst_i(InstImmIdx);
    instAddr <= inst_i(InstAddrIdx);

    process(rst, pc_i, regData1_i, regData2_i,
            exToWriteReg_i, exWriteRegAddr_i, exWriteRegData_i,
            memToWriteReg_i, memWriteRegAddr_i, memWriteRegData_i,
            instOp, instRs, instRt, instRd,
            instSa, instFunc, instImm, instAddr)
        -- indicates where the operand is from --
        variable oprSrc1, oprSrc2: OprSrcType := INVALID;
    begin
        if (rst = RST_ENABLE) then
            oprSrc1 := INVALID;
            oprSrc2 := INVALID;
            alut_o <= INVALID;
            toWriteReg_o <= NO;
            writeRegAddr_o <= (others => '0');
        else
            case (instOp) is
                when OP_SPECIAL =>
                    case (instSa) is
                        when (OP_SASPECIAL) =>
                            case (instFunc) is
                                -- or --
                                when OP_OR =>
                                    oprSrc1 := REG;
                                    oprSrc2 := REG;
                                    alut_o <= ALU_OR;
                                    toWriteReg_o <= YES;
                                    writeRegAddr_o <= instRd;
                                
                                -- others --
                                when others =>
                                    oprSrc1 := INVALID;
                                    oprSrc2 := INVALID;
                                    alut_o <= INVALID;
                                    toWriteReg_o <= NO;
                                    writeRegAddr_o <= (others => '0');
                            end case;
                        
                        when others =>
                            oprSrc1 := INVALID;
                            oprSrc2 := INVALID;
                            alut_o <= INVALID;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');
                    end case;

                -- ori --
                when OP_ORI =>
                    oprSrc1 := REG;
                    oprSrc2 := IMM;
                    alut_o <= ALU_OR;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;

                -- andi --
                when OP_ANDI =>
                    oprSrc1 := REG;
                    oprSrc2 := IMM;
                    alut_o <= ALU_AND;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;

                -- xori --
                when OP_XORI =>
                    oprSrc1 := REG;
                    oprSrc2 := IMM;
                    alut_o <= ALU_XOR;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;

                -- others --
                when others =>
                    oprSrc1 := INVALID;
                    oprSrc2 := INVALID;
                    alut_o <= INVALID;
                    toWriteReg_o <= NO;
                    writeRegAddr_o <= (others => '0');

            end case;

            case oprSrc1 is
                when REG =>
                    regReadEnable1_o <= ENABLE;
                    regReadAddr1_o <= instRs;
                    operand1_o <= regData1_i;

                    -- Push Forward --
                    if (memToWriteReg_i = YES and memWriteRegAddr_i = instRs) then
                        operand1_o <= memWriteRegData_i;
                        if (instRs = "00000") then
                            operand1_o <= (others => '0');
                        end if;
                    end if;
                    if (exToWriteReg_i = YES and exWriteRegAddr_i = instRs) then
                        operand1_o <= exWriteRegData_i;
                        if (instRs = "00000") then
                            operand1_o <= (others => '0');
                        end if;
                    end if;

                when IMM =>
                    regReadEnable1_o <= DISABLE;
                    regReadAddr1_o <= (others => '0');
                    operand1_o <= "0000000000000000" & instImm;
                when others =>
                    regReadEnable1_o <= DISABLE;
                    regReadAddr1_o <= (others => '0');
                    operand1_o <= (others => '0');
            end case;

            case oprSrc2 is
                when REG =>
                    regReadEnable2_o <= ENABLE;
                    regReadAddr2_o <= instRs;
                    operand2_o <= regData2_i;

                    -- Push Forward --
                    if (memToWriteReg_i = YES and memWriteRegAddr_i = instRs) then
                        operand2_o <= memWriteRegData_i;
                        if (instRs = "00000") then
                            operand2_o <= (others => '0');
                        end if;
                    end if;
                    if (exToWriteReg_i = YES and exWriteRegAddr_i = instRs) then
                        operand2_o <= exWriteRegData_i;
                        if (instRs = "00000") then
                            operand2_o <= (others => '0');
                        end if;
                    end if;

                when IMM =>
                    regReadEnable2_o <= DISABLE;
                    regReadAddr2_o <= (others => '0');
                    operand2_o <= "0000000000000000" & instImm;
                
                when SA =>
                    regReadEnable2_o <= DISABLE;
                    regReadAddr2_o <= (others => '0');
                    operand2_o <= "000000000000000000000000000" & instSa;
                
                when others =>
                    regReadEnable2_o <= DISABLE;
                    regReadAddr2_o <= (others => '0');
                    operand2_o <= (others => '0');
            end case;

        end if;
    end process;

end bhv;