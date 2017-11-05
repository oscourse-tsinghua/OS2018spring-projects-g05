library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.global_const.all;
use work.inst_const.all;
use work.alu_const.all;
use work.mem_const.all;
use work.except_const.all;

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
        isInDelaySlot_o: out std_logic;

        -- For Exceptions --
        exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
        exceptCause_o: out std_logic_vector(ExceptionCauseWidth);
        currentInstAddr_o: out std_logic_vector(AddrWidth)
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
    -- Address used by exception instructions
    currentInstAddr_o <= pc_i;

    isInDelaySlot_o <= isInDelaySlot_i;

    process(all)
        -- indicates where the operand is from --
        variable oprSrc1, oprSrc2: OprSrcType;
        variable oprSrcX: XOprSrcType;
        variable operand1, operand2, operandX: std_logic_vector(DataWidth);
        variable isInvalid, jumpToRs, condJump: std_logic;
    begin
        oprSrc1 := INVALID;
        oprSrc2 := INVALID;
        oprSrcX := INVALID;
        alut_o <= INVALID;
        memt_o <= INVALID;
        toWriteReg_o <= NO;
        writeRegAddr_o <= (others => '0');
        toStall_o <= PIPELINE_NONSTOP;
        linkAddr_o <= (others => '0');
        branchTargetAddress_o <= (others => '0');
        branchFlag_o <= NOT_BRANCH_FLAG;
        alut_o <= ALU_JR;
        nextInstInDelaySlot_o <= NOT_IN_DELAY_SLOT_FLAG;
        jumpToRs := NO;
        condJump := NO;
        exceptCause_o <= exceptCause_i;

        if (rst = RST_DISABLE) then
            isInvalid := YES;
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
                            isInvalid := NO;

                        -- and --
                        when OP_AND =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_AND;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- xor --
                        when OP_XOR =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_XOR;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- nor --
                        when OP_NOR =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_NOR;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- sll --
                        when OP_SLL =>
                            oprSrc1 := SA;
                            oprSrc2 := REG;
                            alut_o <= ALU_SLL;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- sllv --
                        when OP_SLLV =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SLL;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- srl --
                        when OP_SRL =>
                            oprSrc1 := SA;
                            oprSrc2 := REG;
                            alut_o <= ALU_SRL;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- srlv --
                        when OP_SRLV =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SRL;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- sra --
                        when OP_SRA =>
                            oprSrc1 := SA;
                            oprSrc2 := REG;
                            alut_o <= ALU_SRA;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- srav --
                        when OP_SRAV =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SRA;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- movn --
                        when OP_MOVN =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MOVN;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- movz --
                        when OP_MOVZ =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MOVZ;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- mfhi --
                        when OP_MFHI =>
                            oprSrc1 := INVALID;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_MFHI;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- mflo --
                        when OP_MFLO =>
                            oprSrc1 := INVALID;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_MFLO;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- mthi --
                        when OP_MTHI =>
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_MTHI;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');
                            isInvalid := NO;

                        -- mtlo --
                        when OP_MTLO =>
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_MTLO;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');
                            isInvalid := NO;

                        -- add --
                        when OP_ADD =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_ADD;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- addu --
                        when OP_ADDU =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_ADDU;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- sub --
                        when OP_SUB =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SUB;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- subu --
                        when OP_SUBU =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SUBU;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- slt --
                        when OP_SLT =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SLT;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- sltu --
                        when OP_SLTU =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SLTU;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- mult --
                        when OP_MULT =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MULT;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');
                            isInvalid := NO;

                        -- multu --
                        when OP_MULTU =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MULTU;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');
                            isInvalid := NO;

                        -- jr --
                        when JMP_JR =>
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            jumpToRs := YES;
                            branchFlag_o <= BRANCH_FLAG;
                            alut_o <= ALU_JR;
                            nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                            linkAddr_o <= (others => '0');
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');
                            isInvalid := NO;

                        -- jalr --
                        when JMP_JALR =>
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            jumpToRs := YES;
                            branchFlag_o <= BRANCH_FLAG;
                            alut_o <= ALU_JALR;
                            nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                            linkAddr_o <= pcPlus8;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when OP_SYSCALL =>
                            oprSrc1 := INVALID;
                            oprSrc2 := INVALID;
                            toWriteReg_o <= NO;
                            exceptCause_o <= SYSCALL_CAUSE;
                            isInvalid := NO;

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
                            isInvalid := NO;

                        -- clz --
                        when OP_CLZ =>
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_CLZ;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- mul --
                        when OP_MUL =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MUL;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        -- madd --
                        when OP_MADD =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MADD;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');
                            isInvalid := NO;

                        -- maddu --
                        when OP_MADDU =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MADDU;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');
                            isInvalid := NO;

                        -- msub --
                        when OP_MSUB =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MSUB;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');
                            isInvalid := NO;

                        -- msubu --
                        when OP_MSUBU =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MSUBU;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');
                            isInvalid := NO;

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
                    isInvalid := NO;

                -- andi --
                when OP_ANDI =>
                    oprSrc1 := REG;
                    oprSrc2 := IMM;
                    alut_o <= ALU_AND;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                -- xori --
                when OP_XORI =>
                    oprSrc1 := REG;
                    oprSrc2 := IMM;
                    alut_o <= ALU_XOR;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                -- lui --
                when OP_LUI =>
                    oprSrc1 := IMM;
                    oprSrc2 := INVALID;
                    alut_o <= ALU_LUI;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                -- lb --
                when OP_LB =>
                    oprSrc1 := REG;
                    oprSrc2 := INVALID;
                    oprSrcX := IMM;
                    alut_o <= ALU_LOAD;
                    memt_o <= MEM_LB;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                -- lbu --
                when OP_LBU =>
                    oprSrc1 := REG;
                    oprSrc2 := INVALID;
                    oprSrcX := IMM;
                    alut_o <= ALU_LOAD;
                    memt_o <= MEM_LBU;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                -- lw --
                when OP_LW =>
                    oprSrc1 := REG;
                    oprSrc2 := INVALID;
                    oprSrcX := IMM;
                    alut_o <= ALU_LOAD;
                    memt_o <= MEM_LW;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                -- sb --
                when OP_SB =>
                    oprSrc1 := REG;
                    oprSrc2 := REG;
                    oprSrcX := IMM;
                    alut_o <= ALU_STORE;
                    memt_o <= MEM_SB;
                    isInvalid := NO;

                -- sw --
                when OP_SW =>
                    oprSrc1 := REG;
                    oprSrc2 := REG;
                    oprSrcX := IMM;
                    alut_o <= ALU_STORE;
                    memt_o <= MEM_SW;
                    isInvalid := NO;

                -- addi --
                when OP_ADDI =>
                    oprSrc1 := REG;
                    oprSrc2 := SGN_IMM;
                    alut_o <= ALU_ADD;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                -- addiu --
                when OP_ADDIU =>
                    oprSrc1 := REG;
                    oprSrc2 := SGN_IMM;
                    alut_o <= ALU_ADDU;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                -- slti --
                when OP_SLTI =>
                    oprSrc1 := REG;
                    oprSrc2 := SGN_IMM;
                    alut_o <= ALU_SLT;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                -- sltiu --
                when OP_SLTIU =>
                    oprSrc1 := REG;
                    oprSrc2 := SGN_IMM;
                    alut_o <= ALU_SLTU;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                -- j --
                when JMP_J =>
                    oprSrc1 := INVALID;
                    oprSrc2 := INVALID;
                    branchFlag_o <= BRANCH_FLAG;
                    alut_o <= ALU_J;
                    nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                    linkAddr_o <= (others => '0');
                    branchTargetAddress_o <= immInstrAddr;
                    toWriteReg_o <= NO;
                    writeRegAddr_o <= (others => '0');
                    isInvalid := NO;

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
                    isInvalid := NO;

                -- beq --
                when JMP_BEQ =>
                    condJump := YES;
                    oprSrc1 := REG;
                    oprSrc2 := REG;
                    alut_o <= ALU_BEQ;
                    toWriteReg_o <= NO;
                    writeRegAddr_o <= (others => '0');
                    isInvalid := NO;

                when OP_JMPSPECIAL =>
                    case (instRt) is
                        -- bltz --
                        when JMP_BLTZ =>
                            condJump := YES;
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_BLTZ;
                            isInvalid := NO;

                        -- bgez --
                        when JMP_BGEZ =>
                            condJump := YES;
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_BGEZ;
                            isInvalid := NO;

                        when others =>
                            null;
                    end case;

                -- bgtz --
                when JMP_BGTZ =>
                    condJump := YES;
                    oprSrc1 := REG;
                    oprSrc2 := INVALID;
                    alut_o <= ALU_BGTZ;
                    isInvalid := NO;

                -- blez --
                when JMP_BLEZ =>
                    condJump := YES;
                    oprSrc1 := REG;
                    oprSrc2 := INVALID;
                    alut_o <= ALU_BLEZ;
                    isInvalid := NO;

                -- bne --
                when JMP_BNE =>
                    condJump := YES;
                    oprSrc1 := REG;
                    oprSrc2 := REG;
                    alut_o <= ALU_BNE;
                    isInvalid := NO;

                when others =>
                    null;
            end case;

            if ((inst_i(InstOpRsIdx) = "01000000100") and (inst_i(InstSaFuncIdx) = "00000000000")) then
                alut_o <= ALU_MTC0;
                oprSrc1 := REGID;
                oprSrc2 := REG;
                toWriteReg_o <= NO;
                writeRegAddr_o <= (others => '0');
                isInvalid := NO;
            end if;

            if ((inst_i(InstOpRsIdx) = "01000000000") and (inst_i(InstSaFuncIdx) = "00000000000")) then
                alut_o <= ALU_MFC0;
                oprSrc1 := REGID;
                oprSrc2 := INVALID;
                toWriteReg_o <= YES;
                writeRegAddr_o <= instRt;
                isInvalid := NO;
            end if;

            if (inst_i = INST_ERET) then
                toWriteReg_o <= NO;
                isInvalid := NO;
                exceptCause_o <= ERET_CAUSE;
            end if;

            if (isInvalid = YES) then
                exceptCause_o <= INVALID_INST_CAUSE;
            end if;

            case oprSrc1 is
                when REG =>
                    regReadEnable1_o <= ENABLE;
                    regReadAddr1_o <= instRs;
                    operand1 := regData1_i;

                    -- Push Forward --
                    if (memToWriteReg_i = YES and memWriteRegAddr_i = instRs) then
                        operand1 := memWriteRegData_i;
                        if (instRs = "00000") then
                            operand1 := (others => '0');
                        end if;
                    end if;
                    if (exToWriteReg_i = YES and exWriteRegAddr_i = instRs) then
                        operand1 := exWriteRegData_i;
                        if (instRs = "00000") then
                            operand1 := (others => '0');
                        elsif (lastMemt_i /= INVALID) then
                            toStall_o <= PIPELINE_STOP;
                        end if;
                    end if;

                when SA =>
                    regReadEnable1_o <= DISABLE;
                    regReadAddr1_o <= (others => '0');
                    operand1 := "000000000000000000000000000" & instSa;

                when IMM =>
                    regReadEnable1_o <= DISABLE;
                    regReadAddr1_o <= (others => '0');
                    operand1 := "0000000000000000" & instImm;

                when SGN_IMM =>
                    regReadEnable1_o <= DISABLE;
                    regReadAddr1_o <= (others => '0');
                    if (instImm(15) = '0') then
                        operand1 := "0000000000000000" & instImm;
                    else
                        operand1 := "1111111111111111" & instImm;
                    end if;

                when REGID =>
                    operand1 := "000000000000000000000000000" & instRd;

                when others =>
                    regReadEnable1_o <= DISABLE;
                    regReadAddr1_o <= (others => '0');
                    operand1 := (others => '0');
            end case;

            case oprSrc2 is
                when REG =>
                    regReadEnable2_o <= ENABLE;
                    regReadAddr2_o <= instRt;
                    operand2 := regData2_i;

                    -- Push Forward --
                    if (memToWriteReg_i = YES and memWriteRegAddr_i = instRt) then
                        operand2 := memWriteRegData_i;
                        if (instRt = "00000") then
                            operand2 := (others => '0');
                        end if;
                    end if;
                    if (exToWriteReg_i = YES and exWriteRegAddr_i = instRt) then
                        operand2 := exWriteRegData_i;
                        if (instRt = "00000") then
                            operand2 := (others => '0');
                        elsif (lastMemt_i /= INVALID) then
                            toStall_o <= PIPELINE_STOP;
                        end if;
                    end if;

                when IMM =>
                    regReadEnable2_o <= DISABLE;
                    regReadAddr2_o <= (others => '0');
                    operand2 := "0000000000000000" & instImm;

                when SGN_IMM =>
                    regReadEnable2_o <= DISABLE;
                    regReadAddr2_o <= (others => '0');
                    if (instImm(15) = '0') then
                        operand2 := "0000000000000000" & instImm;
                    else
                        operand2 := "1111111111111111" & instImm;
                    end if;

                when others =>
                    regReadEnable2_o <= DISABLE;
                    regReadAddr2_o <= (others => '0');
                    operand2 := (others => '0');
            end case;

            case oprSrcX is
                when IMM =>
                    operandX := "0000000000000000" & instImm;

                when others =>
                    operandX := (others => '0');
            end case;
        end if;

        if (jumpToRs = YES) then
            branchTargetAddress_o <= operand1;
        end if;

        if (condJump = YES) then
            case (instOp) is
                when OP_JMPSPECIAL =>
                    case (instRt) is
                        when JMP_BGEZ =>
                            if (operand1(31) = '0') then
                                branchTargetAddress_o <= pcPlus4 + instOffsetImm - instImmSign;
                                branchFlag_o <= BRANCH_FLAG;
                                nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                            end if;
                        when JMP_BLTZ =>
                            if (operand1(31) = '1') then
                                branchTargetAddress_o <= pcPlus4 + instOffsetImm - instImmSign;
                                branchFlag_o <= BRANCH_FLAG;
                                nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                            end if;
                        when others =>
                            null;
                    end case;
                when JMP_BEQ =>
                    if (operand1 = operand2) then
                        branchTargetAddress_o <= pcPlus4 + instOffsetImm - instImmSign;
                        branchFlag_o <= BRANCH_FLAG;
                        nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                    end if;
                when JMP_BGTZ =>
                    if (operand1(31) = '0' and operand1 /= "00000000000000000000000000000000") then
                        branchTargetAddress_o <= pcPlus4 + instOffsetImm - instImmSign;
                        branchFlag_o <= BRANCH_FLAG;
                        nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                    end if;
                when JMP_BLEZ =>
                    if (operand1(31) = '1' or operand1 = "00000000000000000000000000000000") then
                        branchTargetAddress_o <= pcPlus4 + instOffsetImm - instImmSign;
                        branchFlag_o <= BRANCH_FLAG;
                        nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                    end if;
                when JMP_BNE =>
                    if (operand1 /= operand2) then
                        branchTargetAddress_o <= pcPlus4 + instOffsetImm - instImmSign;
                        branchFlag_o <= BRANCH_FLAG;
                        nextInstInDelaySlot_o <= IN_DELAY_SLOT_FLAG;
                    end if;
                when others =>
                    null;
            end case;
        end if;

        operand1_o <= operand1;
        operand2_o <= operand2;
        operandX_o <= operandX;
    end process;
end bhv;
