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
        regReadEnable1_o: out std_logic;
        regReadEnable2_o: out std_logic;
        regReadAddr1_o: out std_logic_vector(RegAddrWidth);
        regReadAddr2_o: out std_logic_vector(RegAddrWidth);

        -- Push Forward --
        exToWriteReg_i: in std_logic;
        exWriteRegAddr_i: in std_logic_vector(RegAddrWidth);
        exWriteRegData_i: in std_logic_vector(DataWidth);
        memToWriteReg_i: in std_logic;
        memWriteRegAddr_i: in std_logic_vector(RegAddrWidth);

        nextWillStall_i: in std_logic;
        toStall_o: out std_logic;
        flushForceWrite_o: out std_logic;

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
        isInDelaySlot_o: out std_logic;
        blNullify_o: out std_logic; -- for "branch likely": skipping the delay slot is equivalent to nullifying next inst
        linkAddr_o: out std_logic_vector(AddrWidth);

        -- For Exceptions --
        valid_i: in std_logic;
        valid_o: out std_logic;
        exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
        tlbRefill_i: in std_logic;
        exceptCause_o: out std_logic_vector(ExceptionCauseWidth);
        tlbRefill_o: out std_logic;
        currentInstAddr_o: out std_logic_vector(AddrWidth);

        -- hazard barrier --
        isIdEhb_o: out std_logic
    );
end id;

architecture bhv of id is

    function zeroJudge(instOp: std_logic_vector(InstOpWidth);
                       instRs: std_logic_vector(InstRsWidth);
                       instRt: std_logic_vector(InstRtWidth);
                       instRd: std_logic_vector(InstRdWidth);
                       instSa: std_logic_vector(InstSaWidth);
                       instFunc: std_logic_vector(InstFuncWidth)) return boolean is
        variable opShouleBeZero: boolean;
        variable rsShouleBeZero: boolean;
        variable rtShouleBeZero: boolean;
        variable rdShouleBeZero: boolean;
        variable saShouleBeZero: boolean;
        variable funcShouleBeZero: boolean;
    begin
        rsShouleBeZero := false;
        rtShouleBeZero := false;
        rdShouleBeZero := false;
        saShouleBeZero := false;

        case (instOp) is
            when OP_SPECIAL =>
                if (instFunc /= FUNC_SLL and instFunc /= FUNC_SRL and instFunc /= FUNC_SRA and instFunc /= JMP_JR) then
                    saShouleBeZero := true;
                end if;
                case (instFunc) is
                    when FUNC_MFHI | FUNC_MFLO =>
                        rsShouleBeZero := true;
                        rtShouleBeZero := true;
                    when FUNC_MTHI | FUNC_MTLO | JMP_JR =>
                        rtShouleBeZero := true;
                        rdShouleBeZero := true;
                    when JMP_JALR =>
                        rtShouleBeZero := true;
                    when FUNC_MULT | FUNC_MULTU =>
                        rdShouleBeZero := true;
                    when others =>
                end case;

            when OP_LUI =>
                rsShouleBeZero := true;
            when JMP_BGTZ | JMP_BLEZ  =>
                rtShouleBeZero := true;

            when others =>
        end case;

        if (opShouleBeZero and instOp /= "000000") then
            return false;
        end if;
        if (rsShouleBeZero and instRs /= "00000") then
            return false;
        end if;
        if (rtShouleBeZero and instRt /= "00000") then
            return false;
        end if;
        if (rdShouleBeZero and instRd /= "00000") then
            return false;
        end if;
        if (saShouleBeZero and instSa /= "00000") then
            return false;
        end if;
        return true;
    end zeroJudge;

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
    instImmSign <= inst_i(InstImmSignIdx) & 17ub"0";
    instOffsetImm <= "0" & inst_i(InstUnsignedImmIdx) & "00";

    -- calculated the addresses that maybe used by jmp instructions first --
    pcPlus8 <= pc_i + "1000";
    pcPlus4 <= pc_i + "100";
    immInstrAddr <= pc_i(InstJmpUnchangeIdx) & inst_i(InstImmAddrIdx) & "00";

    isInDelaySlot_o <= isInDelaySlot_i;
    valid_o <= valid_i;

    process (all)
        -- indicates where the operand is from --
        variable oprSrc1, oprSrc2: OprSrcType;
        variable oprSrcX: XOprSrcType;
        variable operand1, operand2, operandX: std_logic_vector(DataWidth);
        variable isInvalid, jumpToRs, condJump, branchToJump, branchToLink: std_logic;
        variable branchFlag: std_logic;
        variable branchTargetAddress: std_logic_vector(AddrWidth);
        variable toStall, blNullify: std_logic;
    begin
        oprSrc1 := INVALID;
        oprSrc2 := INVALID;
        oprSrcX := INVALID;
        alut_o <= INVALID;
        memt_o <= INVALID;
        toWriteReg_o <= NO;
        writeRegAddr_o <= (others => '0');
        toStall := PIPELINE_NONSTOP;
        blNullify := PIPELINE_NONSTOP;

        linkAddr_o <= (others => '0');
        branchTargetAddress := (others => '0');
        branchFlag := NO;
        nextInstInDelaySlot_o <= NO;
        jumpToRs := NO;
        condJump := NO;
        exceptCause_o <= exceptCause_i;
        regReadEnable1_o <= DISABLE;
        regReadAddr1_o <= (others => '0');
        regReadEnable2_o <= DISABLE;
        regReadAddr2_o <= (others => '0');
        flushForceWrite_o <= NO;

        -- Assign 'X' to them, otherwise it will introduce a level latch to keep prior values
        operand1 := (others => 'X');
        operand2 := (others => 'X');
        operandX := (others => 'X');

        if (rst = RST_DISABLE) then
            isInvalid := YES;
            case (instOp) is
                when OP_SPECIAL =>
                    case (instFunc) is
                        when FUNC_OR =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_OR;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when FUNC_AND =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_AND;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when FUNC_XOR =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_XOR;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when FUNC_NOR =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_NOR;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when FUNC_SLL =>
                            oprSrc1 := SA;
                            oprSrc2 := REG;
                            alut_o <= ALU_SLL;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when FUNC_SLLV =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SLL;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when FUNC_SRL =>
                            oprSrc1 := SA;
                            oprSrc2 := REG;
                            alut_o <= ALU_SRL;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when FUNC_SRLV =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SRL;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when FUNC_SRA =>
                            oprSrc1 := SA;
                            oprSrc2 := REG;
                            alut_o <= ALU_SRA;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when FUNC_SRAV =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SRA;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when FUNC_MFHI =>
                            oprSrc1 := INVALID;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_MFHI;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when FUNC_MFLO =>
                            oprSrc1 := INVALID;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_MFLO;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when FUNC_MTHI =>
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_MTHI;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');
                            isInvalid := NO;

                        when FUNC_MTLO =>
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            alut_o <= ALU_MTLO;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');
                            isInvalid := NO;

                        when FUNC_ADD =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_ADD;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when FUNC_ADDU =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_ADDU;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when FUNC_SUB =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SUB;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when FUNC_SUBU =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SUBU;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when FUNC_SLT =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SLT;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when FUNC_SLTU =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_SLTU;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;

                        when FUNC_MULT =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MULT;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');
                            isInvalid := NO;

                        when FUNC_MULTU =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_MULTU;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');
                            isInvalid := NO;

                        when FUNC_DIV =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_DIV;
                            toWriteReg_o <= NO;
                            isInvalid := NO;

                        when FUNC_DIVU =>
                            oprSrc1 := REG;
                            oprSrc2 := REG;
                            alut_o <= ALU_DIVU;
                            toWriteReg_o <= NO;
                            isInvalid := NO;

                        when JMP_JR =>
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            jumpToRs := YES;
                            branchFlag := YES;
                            nextInstInDelaySlot_o <= YES;
                            linkAddr_o <= (others => '0');
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');
                            isInvalid := NO;

                        when JMP_JALR =>
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            jumpToRs := YES;
                            branchFlag := YES;
                            alut_o <= ALU_JBAL;
                            nextInstInDelaySlot_o <= YES;
                            linkAddr_o <= pcPlus8;
                            toWriteReg_o <= YES;
                            writeRegAddr_o <= instRd;
                            isInvalid := NO;
                            flushForceWrite_o <= YES;

                        when FUNC_SYSCALL =>
                            oprSrc1 := INVALID;
                            oprSrc2 := INVALID;
                            toWriteReg_o <= NO;
                            exceptCause_o <= SYSCALL_CAUSE;
                            isInvalid := NO;

                        when FUNC_BREAK =>
                            oprSrc1 := INVALID;
                            oprSrc2 := INVALID;
                            toWriteReg_o <= NO;
                            exceptCause_o <= BREAKPOINT_CAUSE;
                            isInvalid := NO;

                        when others =>
                            oprSrc1 := INVALID;
                            oprSrc2 := INVALID;
                            alut_o <= INVALID;
                            toWriteReg_o <= NO;
                            writeRegAddr_o <= (others => '0');
                    end case;

                when OP_ORI =>
                    oprSrc1 := REG;
                    oprSrc2 := IMM;
                    alut_o <= ALU_OR;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                when OP_ANDI =>
                    oprSrc1 := REG;
                    oprSrc2 := IMM;
                    alut_o <= ALU_AND;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                when OP_XORI =>
                    oprSrc1 := REG;
                    oprSrc2 := IMM;
                    alut_o <= ALU_XOR;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                when OP_LUI =>
                    oprSrc1 := IMM;
                    oprSrc2 := INVALID;
                    alut_o <= ALU_LUI;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                when OP_LB =>
                    oprSrc1 := REG;
                    oprSrc2 := INVALID;
                    oprSrcX := IMM;
                    alut_o <= ALU_LOAD;
                    memt_o <= MEM_LB;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                when OP_LBU =>
                    oprSrc1 := REG;
                    oprSrc2 := INVALID;
                    oprSrcX := IMM;
                    alut_o <= ALU_LOAD;
                    memt_o <= MEM_LBU;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                when OP_LH =>
                    oprSrc1 := REG;
                    oprSrc2 := INVALID;
                    oprSrcX := IMM;
                    alut_o <= ALU_LOAD;
                    memt_o <= MEM_LH;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                when OP_LHU =>
                    oprSrc1 := REG;
                    oprSrc2 := INVALID;
                    oprSrcX := IMM;
                    alut_o <= ALU_LOAD;
                    memt_o <= MEM_LHU;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                when OP_LW =>
                    oprSrc1 := REG;
                    oprSrc2 := INVALID;
                    oprSrcX := IMM;
                    alut_o <= ALU_LOAD;
                    memt_o <= MEM_LW;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                -- For LWL and LWR, we load rt here, fill the bytes to be loaded
                -- in MEM, and write it back in WB. This might be slow because a
                -- LWL is usually followed by a LWR, in which case there will be
                -- a pipeline stall. Luckily, LWL and LWR instructions are few.
                when OP_SB =>
                    oprSrc1 := REG;
                    oprSrc2 := REG;
                    oprSrcX := IMM;
                    alut_o <= ALU_STORE;
                    memt_o <= MEM_SB;
                    isInvalid := NO;

                when OP_SH =>
                    oprSrc1 := REG;
                    oprSrc2 := REG;
                    oprSrcX := IMM;
                    alut_o <= ALU_STORE;
                    memt_o <= MEM_SH;
                    isInvalid := NO;

                when OP_SW =>
                    oprSrc1 := REG;
                    oprSrc2 := REG;
                    oprSrcX := IMM;
                    alut_o <= ALU_STORE;
                    memt_o <= MEM_SW;
                    isInvalid := NO;

                when OP_ADDI =>
                    oprSrc1 := REG;
                    oprSrc2 := SGN_IMM;
                    alut_o <= ALU_ADD;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                when OP_ADDIU =>
                    oprSrc1 := REG;
                    oprSrc2 := SGN_IMM;
                    alut_o <= ALU_ADDU;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                when OP_SLTI =>
                    oprSrc1 := REG;
                    oprSrc2 := SGN_IMM;
                    alut_o <= ALU_SLT;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                when OP_SLTIU =>
                    oprSrc1 := REG;
                    oprSrc2 := SGN_IMM;
                    alut_o <= ALU_SLTU;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;
                    isInvalid := NO;

                when JMP_J =>
                    oprSrc1 := INVALID;
                    oprSrc2 := INVALID;
                    branchFlag := YES;
                    nextInstInDelaySlot_o <= YES;
                    linkAddr_o <= (others => '0');
                    branchTargetAddress := immInstrAddr;
                    toWriteReg_o <= NO;
                    writeRegAddr_o <= (others => '0');
                    isInvalid := NO;

                when JMP_JAL =>
                    oprSrc1 := INVALID;
                    oprSrc1 := INVALID;
                    branchFlag := YES;
                    alut_o <= ALU_JBAL;
                    nextInstInDelaySlot_o <= YES;
                    linkAddr_o <= pcPlus8;
                    branchTargetAddress := immInstrAddr;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= "11111";
                    isInvalid := NO;

                when JMP_BEQ =>
                    condJump := YES;
                    oprSrc1 := REG;
                    oprSrc2 := REG;
                    toWriteReg_o <= NO;
                    writeRegAddr_o <= (others => '0');
                    isInvalid := NO;

                when OP_JMPSPECIAL =>
                    case (instRt) is
                        when JMP_BLTZ | JMP_BLTZAL =>
                            condJump := YES;
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            isInvalid := NO;

                        when JMP_BGEZ | JMP_BGEZAL =>
                            condJump := YES;
                            oprSrc1 := REG;
                            oprSrc2 := INVALID;
                            isInvalid := NO;

                        when others =>
                            null;
                    end case;

                when JMP_BGTZ =>
                    condJump := YES;
                    oprSrc1 := REG;
                    oprSrc2 := INVALID;
                    isInvalid := NO;

                when JMP_BLEZ =>
                    condJump := YES;
                    oprSrc1 := REG;
                    oprSrc2 := INVALID;
                    isInvalid := NO;

                when JMP_BNE =>
                    condJump := YES;
                    oprSrc1 := REG;
                    oprSrc2 := REG;
                    isInvalid := NO;

                when OP_COP0 =>
                    case (instRs) is
                        when RS_MT =>
                            if (inst_i(InstSaFuncIdx) = 8ub"0") then
                                alut_o <= ALU_MTC0;
                                oprSrc1 := REGID;
                                oprSrc2 := REG;
                                oprSrcX := IMM;
                                toWriteReg_o <= NO;
                                writeRegAddr_o <= (others => '0');
                                isInvalid := NO;
                            end if;

                        when RS_MF =>
                            if (inst_i(InstSaFuncIdx) = 8ub"0") then
                                alut_o <= ALU_MFC0;
                                oprSrc1 := REGID;
                                oprSrc2 := INVALID;
                                oprSrcX := IMM;
                                toWriteReg_o <= YES;
                                writeRegAddr_o <= instRt;
                                isInvalid := NO;
                            end if;

                        when others =>
                            null;
                    end case;

                    if (inst_i(25) = '1' and inst_i(24 downto 6) = 19ub"0") then -- bit 25 is CO
                        case (instFunc) is
                            when FUNC_ERET =>
                                isInvalid := NO;
                                exceptCause_o <= ERET_CAUSE;
                            when others =>
                                null;
                        end case;
                    end if;

                when others =>
                    null;
            end case;

            if (isInvalid = YES or not zeroJudge(instOp, instRs, instRt, instRd, instSa, instFunc)) then
                exceptCause_o <= INVALID_INST_CAUSE;
            end if;

            case oprSrc1 is
                when REG =>
                    regReadEnable1_o <= ENABLE;
                    regReadAddr1_o <= instRs;
                    operand1 := regData1_i;
                    if (instRs /= 5ub"0") then
                        -- Ex Push Forward, Mem Wait --
                        if (exToWriteReg_i = YES and exWriteRegAddr_i = instRs) then
                            operand1 := exWriteRegData_i;
                            if (lastMemt_i /= INVALID) then
                                toStall := PIPELINE_STOP;
                            end if;
                        elsif (memToWriteReg_i = YES and memWriteRegAddr_i = instRs) then
                            toStall := PIPELINE_STOP;
                        end if;
                    end if;

                when SA =>
                    operand1 := 27ub"0" & instSa;

                when IMM =>
                    operand1 := 16ub"0" & instImm;

                when SGN_IMM =>
                    if (instImm(15) = '0') then
                        operand1 := 16ub"0" & instImm;
                    else
                        operand1 := 16sb"1" & instImm;
                    end if;

                when REGID =>
                    operand1 := 27ub"0" & instRd;

                when others =>
                    operand1 := (others => '0');
            end case;

            case oprSrc2 is
                when REG =>
                    regReadEnable2_o <= ENABLE;
                    regReadAddr2_o <= instRt;
                    operand2 := regData2_i;
                    if (instRt /= 5ub"0") then
                        -- Ex Push Forward, Mem Wait --
                        if (exToWriteReg_i = YES and exWriteRegAddr_i = instRt) then
                            operand2 := exWriteRegData_i;
                            if (lastMemt_i /= INVALID) then
                                toStall := PIPELINE_STOP;
                            end if;
                        elsif (memToWriteReg_i = YES and memWriteRegAddr_i = instRt) then
                            toStall := PIPELINE_STOP;
                        end if;
                    end if;

                when IMM =>
                    operand2 := 16ub"0" & instImm;

                when SGN_IMM =>
                    if (instImm(15) = '0') then
                        operand2 := 16ub"0" & instImm;
                    else
                        operand2 := 16sb"1" & instImm;
                    end if;

                when others =>
                    operand2 := (others => '0');
            end case;

            case oprSrcX is
                when IMM =>
                    operandX := 16ub"0" & instImm;

                when others =>
                    operandX := (others => '0');
            end case;
        end if;

        if (jumpToRs = YES) then
            branchTargetAddress := operand1;
        end if;

        if (condJump = YES) then
            branchToJump := NO;
            branchToLink := NO;
            nextInstInDelaySlot_o <= YES;
            case (instOp) is
                when OP_JMPSPECIAL =>
                    case (instRt) is
                        when JMP_BGEZ =>
                            if (operand1(31) = '0') then
                                branchToJump := YES;
                            end if;
                        when JMP_BLTZ =>
                            if (operand1(31) = '1') then
                                branchToJump := YES;
                            end if;
                        when JMP_BGEZAL =>
                            if (operand1(31) = '0') then
                                branchToJump := YES;
                            end if;
                            branchToLink := YES;
                        when JMP_BLTZAL =>
                            if (operand1(31) = '1') then
                                branchToJump := YES;
                            end if;
                            branchToLink := YES;
                        when others =>
                            null;
                    end case;
                when JMP_BEQ =>
                    if (operand1 = operand2) then
                        branchToJump := YES;
                    end if;
                when JMP_BGTZ =>
                    if (operand1(31) = '0' and operand1 /= 32ux"0") then
                        branchToJump := YES;
                    end if;
                when JMP_BLEZ =>
                    if (operand1(31) = '1' or operand1 = 32ux"0") then
                        branchToJump := YES;
                    end if;
                when JMP_BNE =>
                    if (operand1 /= operand2) then
                        branchToJump := YES;
                    end if;
                when others =>
                    null;
            end case;

            if (branchToJump = YES) then
                branchTargetAddress := pcPlus4 + instOffsetImm - instImmSign;
                branchFlag := YES;
            end if;

            if (branchToLink = YES) then
                linkAddr_o <= pcPlus8;
                toWriteReg_o <= YES;
                writeRegAddr_o <= "11111";
                alut_o <= ALU_JBAL;
            end if;
        end if;

        if ((jumpToRs = YES) and (branchTargetAddress(1 downto 0) /= "00")) then
            branchFlag := NO;
            currentInstAddr_o <= branchTargetAddress;
            branchTargetAddress := (others => '0');
            exceptCause_o <= ADDR_ERR_LOAD_OR_IF_CAUSE;
        else
            currentInstAddr_o <= pc_i;
        end if;

        if (nextWillStall_i = '1') then
            branchFlag := NO;
        end if;

        operand1_o <= operand1;
        operand2_o <= operand2;
        operandX_o <= operandX;
        branchFlag_o <= branchFlag;
        branchTargetAddress_o <= branchTargetAddress;
        toStall_o <= toStall;
        blNullify_o <= blNullify;
    end process;
end bhv;
