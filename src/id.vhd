library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.global_const.all;
use work.inst_const.all;
use work.alu_const.all;
use work.mem_const.all;
use ieee.numeric_std.all;

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

        toStall_o: out std_logic;
        regReadEnable1_o: out std_logic;
        regReadEnable2_o: out std_logic;
        regReadAddr1_o: out std_logic_vector(RegAddrWidth);
        regReadAddr2_o: out std_logic_vector(RegAddrWidth);
        alut_o: out AluType;
        memt_o: out MemType;
        lastMemt_i: in MemType; -- memt of last instruction, used to determine stalling
        operand1_o: out std_logic_vector(DataWidth);
        operand2_o: out std_logic_vector(DataWidth);
        operandX_o: out std_logic_vector(DataWidth);
        toWriteReg_o: out std_logic;
        writeRegAddr_o: out std_logic_vector(RegAddrWidth);
        
        -- For ju instructions --
        isInDelaySlot_i: in std_logic;
        nextInstInDelaySlot_o: out std_logic;
        branchFlag_o: out std_logic;
        branchTargetAddress_o: out std_logic_vector(AddrWidth);
        linkAddr_o: out std_logic_vector(AddrWidth);
        isInDelaySlot_o: out std_logic
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
    signal pcPlus8:  std_logic_vector(AddrWidth);
    signal pcPlus4:  std_logic_vector(AddrWidth);
    signal immInstrAddr: std_logic_vector(AddrWidth);
    signal jumpToRs: std_logic;
    signal condjump: std_logic;
    signal instImmSign: std_logic_vector(InstOffsetImmWidth);
    signal instOffsetImm: std_logic_vector(InstOffsetImmWidth);
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
    instImmSign <= inst_i(InstImmSignIdx) & "00000000000000000";
    instOffsetImm <= "0" & inst_i(InstUnsignedImmIdx) & "00";
    
    -- calculated the addresses that maybe used by jmp instructions first --
    pcPlus8 <= pc_i + "1000";
    pcPlus4 <= pc_i + "100";
    immInstrAddr <= pc_i(InstJmpUnchangeIdx) & inst_i(InstImmAddrIdx) & "00";
    process(all)
        -- indicates where the operand is from --
        variable oprSrc1, oprSrc2: OprSrcType;
        variable oprSrcX: XOprSrcType;
    begin
        oprSrc1 := INVALID;
        oprSrc2 := INVALID;
        oprSrcX := INVALID;
        alut_o <= INVALID;
        memt_o <= INVALID;
        toWriteReg_o <= NO;
        writeRegAddr_o <= (others => '0');
        toStall_o <= PIPELINE_NONSTOP;
        jumpToRs <= NO;
        linkAddr_o <= BRANCH_ZERO_WORD;
        branchTargetAddress_o <= BRANCH_ZERO_WORD;
        branchFlag_o <= NOT_BRANCH_FLAG;
        alut_o <= ALU_JR;
        nextInstInDelaySlot_o <= NOT_IN_DELAY_SLOT_FLAG;
        condJump <= NO;

        if (rst = RST_ENABLE) then
            oprSrc1 := INVALID;
            oprSrc2 := INVALID;
            alut_o <= INVALID;
            toWriteReg_o <= NO;
            writeRegAddr_o <= (others => '0');
            linkAddr_o <= BRANCH_ZERO_WORD;
            branchTargetAddress_o <= BRANCH_ZERO_WORD;
            branchFlag_o <= NOT_BRANCH_FLAG;
            nextInstInDelaySlot_o <= NOT_IN_DELAY_SLOT_FLAG;
            condJump <= NO;
            jumpToRs <= NO;
        else
            case (instOp) is
                -- special --
                when OP_SPECIAL =>
                    case (instFunc) is
                        -- or --
                        when OP_OR =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_OR;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- and --
                        when OP_AND =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_AND;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- xor --
                        when OP_XOR =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_XOR;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- nor --
                        when OP_NOR =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_NOR;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- sll --
                        when OP_SLL =>
                            oprSrc1 := SA;
                            oprSrc2 := REG;
                            alut_o <= ALU_SLL;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- sllv --
                        when OP_SLLV =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SLL;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- srl --
                        when OP_SRL =>
                            oprSrc1 := SA;
                            oprSrc2 := REG;
                            alut_o <= ALU_SRL;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- srlv --
                        when OP_SRLV =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SRL;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- sra --
                        when OP_SRA =>
                            oprSrc1 := SA;
                            oprSrc2 := REG;
                            alut_o <= ALU_SRA;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- srav --
                        when OP_SRAV =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SRA;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- movn --
                        when OP_MOVN =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MOVN;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- movz --
                        when OP_MOVZ =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MOVZ;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- mfhi --
                        when OP_MFHI =>
                            oprSrc1 := INVALID;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_MFHI;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- mflo --
                        when OP_MFLO =>
                            oprSrc1 := INVALID;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_MFLO;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- mthi --
                        when OP_MTHI =>
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_MTHI;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');

                        -- mtlo --
                        when OP_MTLO =>
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_MTLO;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');

                        -- add --
                        when OP_ADD =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_ADD;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- addu --
                        when OP_ADDU =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_ADDU;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- sub --
                        when OP_SUB =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SUB;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- subu --
                        when OP_SUBU =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SUBU;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- slt --
                        when OP_SLT =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SLT;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- sltu --
                        when OP_SLTU =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SLTU;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- mult --
                        when OP_MULT =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MULT;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');

                        -- multu --
                        when OP_MULTU =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MULTU;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');
                        
                        -- jr --
                        when JMP_JR =>
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            jumpToRs <= YES;
                            branchFlag_o <= BRANCH_FLAG;
                            alut_o <= ALU_JR;
                            nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                            linkAddr_o <= BRANCH_ZERO_WORD;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');

                        -- jalr --
                        when JMP_JALR =>
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            jumpToRs <= YES;
                            branchFlag_o <= BRANCH_FLAG;
                            alut_o <= ALU_JALR;
                            nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                            linkAddr_o <= pcPlus8;
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

                -- special2 --
                when OP_SPECIAL2 =>
                    case (instFunc) is
                        -- clo --
                        when OP_CLO =>
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_CLO;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- clz --
                        when OP_CLZ =>
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_CLZ;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- mul --
                        when OP_MUL =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MUL;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;

                        -- madd --
                        when OP_MADD =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MADD;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');

                        -- maddu --
                        when OP_MADDU =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MADDU;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');

                        -- msub --
                        when OP_MSUB =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MSUB;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');

                        -- msubu --
                        when OP_MSUBU =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MSUBU;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');

                        -- others --
                        when others =>
                            null;
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

                -- lui --
                when OP_LUI =>
                    oprSrc1 := IMM;
                    oprSrc2 := INVALID;
                    alut_o <= ALU_LUI;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;

                -- lb --
                when OP_LB =>
                    oprSrc1 := REG;
                    oprSrc2 := INVALID;
                    oprSrcX := IMM;
                    alut_o <= ALU_LOAD;
                    memt_o <= MEM_LB;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;

                -- lbu --
                when OP_LBU =>
                    oprSrc1 := REG;
                    oprSrc2 := INVALID;
                    oprSrcX := IMM;
                    alut_o <= ALU_LOAD;
                    memt_o <= MEM_LBU;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;

                -- lw --
                when OP_LW =>
                    oprSrc1 := REG;
                    oprSrc2 := INVALID;
                    oprSrcX := IMM;
                    alut_o <= ALU_LOAD;
                    memt_o <= MEM_LW;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;

                -- sb --
                when OP_SB =>
                    oprSrc1 := REG;
                    oprSrc2 := REG;
                    oprSrcX := IMM;
                    alut_o <= ALU_STORE;
                    memt_o <= MEM_SB;

                -- sw --
                when OP_SW =>
                    oprSrc1 := REG;
                    oprSrc2 := REG;
                    oprSrcX := IMM;
                    alut_o <= ALU_STORE;
                    memt_o <= MEM_SW;

                -- addi --
                when OP_ADDI =>
                    oprSrc1 := REG;
                    oprSrc2 := SGN_IMM;
                    alut_o <= ALU_ADD;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;

                -- addiu --
                when OP_ADDIU =>
                    oprSrc1 := REG;
                    oprSrc2 := SGN_IMM;
                    alut_o <= ALU_ADDU;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;

                -- slti --
                when OP_SLTI =>
                    oprSrc1 := REG;
                    oprSrc2 := SGN_IMM;
                    alut_o <= ALU_SLT;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;

                -- sltiu --
                when OP_SLTIU =>
                    oprSrc1 := REG;
                    oprSrc2 := SGN_IMM;
                    alut_o <= ALU_SLTU;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    
                -- j --
                when JMP_J =>
                    oprSrc1 := INVALID;
                    oprSrc2 := INVALID;
                    branchFlag_o <= BRANCH_FLAG;
                    alut_o <= ALU_J;
                    nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                    linkAddr_o <= BRANCH_ZERO_WORD;
                    branchTargetAddress_o <= immInstrAddr;
                    toWriteReg_o <= NO;
                    writeRegAddr_o <= (others => '0');
                    
                -- jal --
                when JMP_JAL =>
                    oprSrc1 := INVALID;
                    oprSrc1 := INVALID;
                    branchFlag_o <= BRANCH_FLAG;
                    alut_o <= ALU_JAL;
                    nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                    linkAddr_o <= pcPlus8;
                    branchTargetAddress_o <= immInstrAddr;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= "11111";
                
                -- beq --
                when JMP_BEQ =>
                    condJump <= YES;
                    oprSrc1 := REG;
                    oprSrc2 := REG;
                    alut_o <= ALU_BEQ;
                    toWriteReg_o <= NO;
                    writeRegAddr_o <= (others => '0');
                
                when OP_JMPSPECIAL =>
                    case (instRt) is
                        -- bltz --
                        when JMP_BLTZ =>
                            condJump <= YES;
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_BLTZ;
                        -- bgez --
                        when JMP_BGEZ =>
                            condJump <= YES;
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_BGEZ;
                        when others =>
                            null;
                    end case;

                -- bgtz --
                when JMP_BGTZ =>
                    condJump <= YES;
                    oprSrc1 := REG;
                    oprSrc2 := INVALID;
                    alut_o <= ALU_BGTZ;
                
                -- blez --
                when JMP_BLEZ =>
                    condJump <= YES;
                    oprSrc1 := REG;
                    oprSrc2 := INVALID;
                    alut_o <= ALU_BLEZ;
                
                -- bne --
                when JMP_BNE =>
                    condJump <= YES;
                    oprSrc1 := REG;
                    oprSrc2 := REG;
                    alut_o <= ALU_BNE;

                when others =>
                    null;
            end case;

            if ((inst_i(InstOpRsIdx) = "01000000100") and (inst_i(InstSaFuncIdx) = "00000000000")) then
                alut_o <= ALU_MTC0;
                oprSrc1 := REGID;
                oprSrc2 := REG;
                toWriteReg_o <= NO;
                writeRegAddr_o <= (others => '0');
            end if;

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
                        elsif (lastMemt_i /= INVALID) then
                            toStall_o <= PIPELINE_STOP;
                        end if;
                    end if;
                    if (jumpToRs = YES) then
                        branchTargetAddress_o <= operand1_o;
                    end if;

                when SA =>
                    regReadEnable1_o <= DISABLE;
                    regReadAddr1_o <= (others => '0');
                    operand1_o <= "000000000000000000000000000" & instSa;

                when IMM =>
                    regReadEnable1_o <= DISABLE;
                    regReadAddr1_o <= (others => '0');
                    operand1_o <= "0000000000000000" & instImm;

                when SGN_IMM =>
                    regReadEnable1_o <= DISABLE;
                    regReadAddr1_o <= (others => '0');
                    if (instImm(15) = '0') then
                        operand1_o <= "0000000000000000" & instImm;
                    else
                        operand1_o <= "1111111111111111" & instImm;
                    end if;

                when REGID =>
                    operand1_o <= "000000000000000000000000000" & instRd;

                when others =>
                    regReadEnable1_o <= DISABLE;
                    regReadAddr1_o <= (others => '0');
                    operand1_o <= (others => '0');
            end case;

            case oprSrc2 is
                when REG =>
                    regReadEnable2_o <= ENABLE;
                    regReadAddr2_o <= instRt;
                    operand2_o <= regData2_i;

                    -- Push Forward --
                    if (memToWriteReg_i = YES and memWriteRegAddr_i = instRt) then
                        operand2_o <= memWriteRegData_i;
                        if (instRt = "00000") then
                            operand2_o <= (others => '0');
                        end if;
                    end if;
                    if (exToWriteReg_i = YES and exWriteRegAddr_i = instRt) then
                        operand2_o <= exWriteRegData_i;
                        if (instRt = "00000") then
                            operand2_o <= (others => '0');
                        elsif (lastMemt_i /= INVALID) then
                            toStall_o <= PIPELINE_STOP;
                        end if;
                    end if;

                when IMM =>
                    regReadEnable2_o <= DISABLE;
                    regReadAddr2_o <= (others => '0');
                    operand2_o <= "0000000000000000" & instImm;

                when SGN_IMM =>
                    regReadEnable2_o <= DISABLE;
                    regReadAddr2_o <= (others => '0');
                    if (instImm(15) = '0') then
                        operand2_o <= "0000000000000000" & instImm;
                    else
                        operand2_o <= "1111111111111111" & instImm;
                    end if;

                when others =>
                    regReadEnable2_o <= DISABLE;
                    regReadAddr2_o <= (others => '0');
                    operand2_o <= (others => '0');
            end case;

            case oprSrcX is
                when IMM =>
                    operandX_o <= "0000000000000000" & instImm;

                when others =>
                    operandX_o <= (others => '0');
            end case;
        end if;
   
        if (condJump = YES) then
            case (instOp) is
                when OP_JMPSPECIAL =>
                    case (instRt) is
                        when JMP_BGEZ =>
                            if (operand1_o(31) = '0') then
                                branchTargetAddress_o <= pcPlus4 + instOffsetImm - instImmSign;
                                branchFlag_o <= BRANCH_FLAG;
                                nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                            end if;
                        when JMP_BLTZ =>
                            if (operand1_o(31) = '1') then
                                branchTargetAddress_o <= pcPlus4 + instOffsetImm - instImmSign;
                                branchFlag_o <= BRANCH_FLAG;
                                nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                            end if;
                        when others =>
                            null;
                    end case;
                when JMP_BEQ =>
                    if (operand1_o = operand2_o) then
                        branchTargetAddress_o <= pcPlus4 + instOffsetImm - instImmSign;
                        branchFlag_o <= BRANCH_FLAG;
                        nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                    end if;
                when JMP_BGTZ =>
                    if (operand1_o(31) = '0' and operand1_o /= "00000000000000000000000000000000") then
                        branchTargetAddress_o <= pcPlus4 + instOffsetImm - instImmSign;
                        branchFlag_o <= BRANCH_FLAG;
                        nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                    end if;
                when JMP_BLEZ =>
                    if (operand1_o(31) = '1' or operand1_o = "00000000000000000000000000000000") then
                        branchTargetAddress_o <= pcPlus4 + instOffsetImm - instImmSign;
                        branchFlag_o <= BRANCH_FLAG;
                        nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                    end if;
                when JMP_BNE =>
                    if (operand1_o /= operand2_o) then
                        branchTargetAddress_o <= pcPlus4 + instOffsetImm - instImmSign;
                        branchFlag_o <= BRANCH_FLAG;
                        nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                    end if;
                when others =>
                    null;
            end case;
        end if;

        if ((inst_i(InstOpRsIdx) = "01000000000") and (inst_i(InstSaFuncIdx) = "00000000000")) then
            alut_o <= ALU_MFC0;
            operand1_o <= "000000000000000000000000000" & instRd;
            operand2_o <= (others => '0');
            toWriteReg_o <= YES;
            writeRegAddr_o <= instRt;
        end if;
    end process;

    process(all) begin
        if (rst = RST_ENABLE) then
            isInDelaySlot_o <= NOT_IN_DELAY_SLOT_FLAG;
        else
            isInDelaySlot_o <= isInDelaySlot_i;
        end if;
    end process;
end bhv;
