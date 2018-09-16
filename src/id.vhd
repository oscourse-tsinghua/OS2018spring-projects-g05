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
    generic (
        extraCmd: boolean;
        memPushForward: boolean
    );
    port (
        rst: in std_logic;

        pc_i: in std_logic_vector(AddrWidth);
        inst_i: in std_logic_vector(InstWidth);
        regData1_i: in std_logic_vector(DataWidth);
        regData2_i: in std_logic_vector(DataWidth);
        regReadAddr1_o: out std_logic_vector(RegAddrWidth);
        regReadAddr2_o: out std_logic_vector(RegAddrWidth);

        fpRegReadAddr1_o: out std_logic_vector(RegAddrWidth);
        fpRegReadDouble1_o: out std_logic;
        fpRegData1_i: in std_logic_vector(DoubleDataWidth);
        fpRegReadAddr2_o: out std_logic_vector(RegAddrWidth);
        fpRegReadDouble2_o: out std_logic;
        fpRegData2_i: in std_logic_vector(DoubleDataWidth);

        -- Push Forward --
        exMemt_i: in MemType;
        exToWriteReg_i: in std_logic;
        exWriteRegAddr_i: in std_logic_vector(RegAddrWidth);
        exWriteRegData_i: in std_logic_vector(DataWidth);
        fpMemt_i: in FPMemType;
        memMemt_i: in MemType;
        memToWriteReg_i: in std_logic;
        memWriteRegAddr_i: in std_logic_vector(RegAddrWidth);
        memWriteRegDataShort_i: in std_logic_vector(DataWidth);
        memWriteRegDataLong_i: in std_logic_vector(DataWidth);

        -- Push Forward for CP1 --
        exToWriteFPReg_i: in std_logic;
        exWriteFPDouble_i: in std_logic;
        exWriteFPRegAddr_i: in std_logic_vector(AddrWidth);
        exWriteFPRegData_i: in std_logic_vector(DoubleDataWidth);
        exWriteFPTarget_i: in FloatTargetType;

        memToWriteFPReg_i: in std_logic;
        memWriteFPDouble_i: in std_logic;
        memWriteFPRegAddr_i: in std_logic_vector(AddrWidth);
        memWriteFPRegData_i: in std_logic_vector(DoubleDataWidth);
        memWriteFPTarget_i: in FloatTargetType;

        toStall_o: out std_logic;
        flushForceWrite_o: out std_logic;

        alut_o: out AluType;
        fpAlut_o: out FPAluType;
        memt_o: out MemType;
        fpMemt_o: out FPMemType;
        operand1_o: out std_logic_vector(DataWidth);
        operand2_o: out std_logic_vector(DataWidth);
        operandX_o: out std_logic_vector(DataWidth);
        toWriteReg_o: out std_logic;
        writeRegAddr_o: out std_logic_vector(RegAddrWidth);
        foperand1_o: out std_logic_vector(DoubleDataWidth);
        foperand2_o: out std_logic_vector(DoubleDataWidth);
        toWriteFPReg_o: out std_logic;
        writeFPRegAddr_o: out std_logic_vector(RegAddrWidth);
        writeFPDouble_o: out std_logic;

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

        if (extraCmd) then
            case (instOp) is
                when OP_SPECIAL2 =>
                    saShouleBeZero := true;
                    case (instFunc) is
                        when FUNC_MADD | FUNC_MADDU | FUNC_MSUB | FUNC_MSUBU =>
                            rdShouleBeZero := true;
                        when others =>
                    end case;

                when JMP_BLEZL | JMP_BGTZL =>
                    rtShouleBeZero := true;

                when others =>
                    null;
            end case;
        end if;

        case (instOp) is
            when OP_SPECIAL =>
                if (instFunc /= FUNC_SLL and instFunc /= FUNC_SRL and instFunc /= FUNC_SRA and instFunc /= JMP_JR and instFunc /= FUNC_TNE and instFunc /= FUNC_TEQ) then
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

            when JMP_BGTZ | JMP_BLEZ =>
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

    function floatgreater(a: std_logic_vector(DoubleDataWidth);
                          b: std_logic_vector(DoubleDataWidth)) return std_logic is
        variable comp_residual: std_logic;
    begin
        if (a(63) = '1') and (b(63) = '0') then
            return '0';
        elsif (a(63) = '0') and (b(63) = '1') then
            return '1';
        else
            if (unsigned(a(62 downto 0)) < unsigned(b(62 downto 0))) then
                return a(63);
            elsif (unsigned(a(62 downto 0)) > unsigned(b(62 downto 0))) then
                return a(63) xor '1';
            end if;
        end if;
        return '0';
    end floatgreater;

    function floatless(a: std_logic_vector(DoubleDataWidth);
                       b: std_logic_vector(DoubleDataWidth)) return std_logic is
        variable comp_residual: std_logic;
    begin
        if (a(63) = '1') and (b(63) = '0') then
            return '1';
        elsif (a(63) = '0') and (b(63) = '1') then
            return '0';
        else
            if (unsigned(a(62 downto 0)) > unsigned(b(62 downto 0))) then
                return a(63);
            elsif (unsigned(a(62 downto 0)) < unsigned(b(62 downto 0))) then
                return a(63) xor '1';
            end if;
        end if;
        return '0';
    end floatless;

    function floateq(a: std_logic_vector(DoubleDataWidth);
                     b: std_logic_vector(DoubleDataWidth)) return std_logic is
    begin
        if a = b then
            return '1';
        else
            return '0';
        end if;
    end floateq;

    function floatorder(a: std_logic_vector(DoubleDataWidth)) return std_logic is
    begin
        if (a(62 downto 52) = 11sb"1") and (a(51 downto 0) /= 52ub"0") then
            return '0';
        end if;
        return '1';
    end floatorder;

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
    signal cc: std_logic_vector(7 downto 0);

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
        variable oprSrcF1, oprSrcF2: FOprSrcType;
        variable operand1, operand2, operandX: std_logic_vector(DataWidth);
        variable foperand1, foperand2: std_logic_vector(DoubleDataWidth);
        variable isInvalid, jumpToRs, condJump, branchToJump, branchToLink: std_logic;
        variable branchFlag: std_logic;
        variable branchTargetAddress: std_logic_vector(AddrWidth);
        variable blNullify, branchLikely, tneFlag, teqFlag: std_logic;
        variable cCondFlag: std_logic;
        variable cResult: std_logic_vector(3 downto 0);
        variable cWriteID: std_logic_vector(2 downto 0);
        variable cCondCode: std_logic_vector(3 downto 0);
        variable cTFFlag, ccJump: std_logic;
    begin
        oprSrc1 := INVALID;
        oprSrc2 := INVALID;
        oprSrcX := INVALID;
        oprSrcF1 := INVALID;
        oprSrcF2 := INVALID;
        fpAlut_o <= INVALID;
        alut_o <= INVALID;
        memt_o <= INVALID;
        fpMemt_o <= INVALID;
        toWriteReg_o <= NO;
        writeRegAddr_o <= (others => '0');
        toStall_o <= PIPELINE_NONSTOP;
        blNullify := PIPELINE_NONSTOP;
        branchLikely := NO;
        tneFlag := NO;
        teqFlag := NO;

        toWriteFPReg_o <= NO;
        writeFPRegAddr_o <= (others => '0');

        linkAddr_o <= (others => '0');
        branchTargetAddress := (others => '0');
        branchFlag := NO;
        nextInstInDelaySlot_o <= NO;
        jumpToRs := NO;
        condJump := NO;
        ccJump := NO;
        exceptCause_o <= exceptCause_i;
        tlbRefill_o <= tlbRefill_i;
        regReadAddr1_o <= (others => '0');
        regReadAddr2_o <= (others => '0');
        isIdEhb_o <= NO;
        flushForceWrite_o <= NO;

        writeFPDouble_o <= NO;

        -- Assign 'X' to them, otherwise it will introduce a level latch to keep prior values
        operand1 := (others => 'X');
        operand2 := (others => 'X');
        operandX := (others => 'X');
        foperand1 := (others => 'X');
        foperand2 := (others => 'X');

        cWriteID := (others => '0');
        cCondFlag := NO;

        if (rst = RST_ENABLE) then
            cc <= (others => '0');
        else
            isInvalid := YES;

            if (extraCmd) then
                case (instOp) is
                    when OP_SPECIAL =>
                        case (instFunc) is
                            when FUNC_MOVN =>
                                oprSrc1 := REG;
                                oprSrc2 := REG;
                                alut_o <= ALU_MOVN;
                                toWriteReg_o <= YES;
                                writeRegAddr_o <= instRd;
                                isInvalid := NO;

                            when FUNC_MOVZ =>
                                oprSrc1 := REG;
                                oprSrc2 := REG;
                                alut_o <= ALU_MOVZ;
                                toWriteReg_o <= YES;
                                writeRegAddr_o <= instRd;
                                isInvalid := NO;

                            when FUNC_SYNC =>
                                if (inst_i(25 downto 16) =10ub"0") then
                                    oprSrc1 := INVALID;
                                    oprSrc2 := INVALID;
                                    toWriteReg_o <= NO;
                                    isInvalid := NO;
                                end if;

                            when FUNC_TNE =>
                                oprSrc1 := REG;
                                oprSrc2 := REG;
                                toWriteReg_o <= NO;
                                writeRegAddr_o <= (others => '0');
                                tneFlag := YES;
                                isInvalid := NO;

                            when FUNC_TEQ =>
                                oprSrc1 := REG;
                                oprSrc2 := REG;
                                toWriteReg_o <= NO;
                                writeRegAddr_o <= (others => '0');
                                teqFlag := YES;
                                isInvalid := NO;

                            when others =>
                                null;
                        end case;

                    when OP_SPECIAL2 =>
                        case (instFunc) is
                            when FUNC_CLO =>
                                oprSrc1 := REG;
                                oprSrc2 := INVALID;
                                alut_o <= ALU_CLO;
                                toWriteReg_o <= YES;
                                writeRegAddr_o <= instRd;
                                isInvalid := NO;

                            when FUNC_CLZ =>
                                oprSrc1 := REG;
                                oprSrc2 := INVALID;
                                alut_o <= ALU_CLZ;
                                toWriteReg_o <= YES;
                                writeRegAddr_o <= instRd;
                                isInvalid := NO;

                            when FUNC_MUL =>
                                oprSrc1 := REG;
                                oprSrc2 := REG;
                                alut_o <= ALU_MUL;
                                toWriteReg_o <= YES;
                                writeRegAddr_o <= instRd;
                                isInvalid := NO;

                            when FUNC_MADD =>
                                oprSrc1 := REG;
                                oprSrc2 := REG;
                                alut_o <= ALU_MADD;
                                toWriteReg_o <= NO;
                                writeRegAddr_o <= (others => '0');
                                isInvalid := NO;

                            when FUNC_MADDU =>
                                oprSrc1 := REG;
                                oprSrc2 := REG;
                                alut_o <= ALU_MADDU;
                                toWriteReg_o <= NO;
                                writeRegAddr_o <= (others => '0');
                                isInvalid := NO;

                            when FUNC_MSUB =>
                                oprSrc1 := REG;
                                oprSrc2 := REG;
                                alut_o <= ALU_MSUB;
                                toWriteReg_o <= NO;
                                writeRegAddr_o <= (others => '0');
                                isInvalid := NO;

                            when FUNC_MSUBU =>
                                oprSrc1 := REG;
                                oprSrc2 := REG;
                                alut_o <= ALU_MSUBU;
                                toWriteReg_o <= NO;
                                writeRegAddr_o <= (others => '0');
                                isInvalid := NO;

                            when FUNC_SDBBP =>
                                oprSrc1 := INVALID;
                                oprSrc2 := INVALID;
                                toWriteReg_o <= NO;
                                isInvalid := NO;

                            when others =>
                                null;
                        end case;

                    when OP_LL =>
                        oprSrc1 := REG;
                        oprSrc2 := INVALID;
                        oprSrcX := IMM;
                        alut_o <= ALU_LOAD;
                        memt_o <= MEM_LL;
                        toWriteReg_o <= YES;
                        writeRegAddr_o <= instRt;
                        isInvalid := NO;

                    -- For LWL and LWR, we load rt here, fill the bytes to be loaded
                    -- in MEM, and write it back in WB. This might be slow because a
                    -- LWL is usually followed by a LWR, in which case there will be
                    -- a pipeline stall. Luckily, LWL and LWR instructions are few.
                    when OP_LWL =>
                        oprSrc1 := REG;
                        oprSrc2 := REG;
                        oprSrcX := IMM;
                        alut_o <= ALU_STORE; -- Because we want to load rt
                        memt_o <= MEM_LWL;
                        toWriteReg_o <= YES;
                        writeRegAddr_o <= instRt;
                        isInvalid := NO;

                    when OP_LWR =>
                        oprSrc1 := REG;
                        oprSrc2 := REG;
                        oprSrcX := IMM;
                        alut_o <= ALU_STORE; -- Because we want to load rt
                        memt_o <= MEM_LWR;
                        toWriteReg_o <= YES;
                        writeRegAddr_o <= instRt;
                        isInvalid := NO;

                    when OP_SC =>
                        oprSrc1 := REG;
                        oprSrc2 := REG;
                        oprSrcX := IMM;
                        alut_o <= ALU_STORE;
                        memt_o <= MEM_SC;
                        toWriteReg_o <= YES;
                        writeRegAddr_o <= instRt;
                        isInvalid := NO;

                    when OP_SWL =>
                        oprSrc1 := REG;
                        oprSrc2 := REG;
                        oprSrcX := IMM;
                        alut_o <= ALU_STORE;
                        memt_o <= MEM_SWL;
                        isInvalid := NO;

                    when OP_SWR =>
                        oprSrc1 := REG;
                        oprSrc2 := REG;
                        oprSrcX := IMM;
                        alut_o <= ALU_STORE;
                        memt_o <= MEM_SWR;
                        isInvalid := NO;

                    when OP_CACHE | OP_PREF =>
                        -- Currently not implemented
                        oprSrc1 := INVALID;
                        oprSrc2 := INVALID;
                        toWriteReg_o <= NO;
                        isInvalid := NO;

                    when OP_LWC1 =>
                        oprSrc1 := REG;
                        oprSrcX := IMM;
                        fpAlut_o <= FP_LOAD;
                        fpMemt_o <= FMEM_LW;
                        toWriteFPReg_o <= YES;
                        writeFPRegAddr_o <= instRt;
                        isInvalid := NO;

                    when OP_LDC1 =>
                        oprSrc1 := REG;
                        oprSrcX := IMM;
                        fpAlut_o <= FP_LOAD;
                        fpMemt_o <= FMEM_LD;
                        toWriteFPReg_o <= YES;
                        writeFPRegAddr_o <= instRt;
                        writeFPDouble_o <= YES;
                        isInvalid := NO;

                    when OP_SWC1 =>
                        oprSrc1 := REG;
                        oprSrcF1 := SINGLE;
                        oprSrcX := IMM;
                        fpAlut_o <= FP_STORE;
                        fpMemt_o <= FMEM_SW;
                        toWriteFPReg_o <= NO;
                        isInvalid := NO;
                
                    when OP_SDC1 =>
                        oprSrc1 := REG;
                        oprSrcF1 := PAIRED;
                        oprSrcX := IMM;
                        fpAlut_o <= FP_STORE;
                        fpMemt_o <= FMEM_SD;
                        toWriteFPReg_o <= NO;
                        isInvalid := NO;

                    when OP_JMPSPECIAL =>
                        case (instRt) is
                            when JMP_BLTZL =>
                                condJump := YES;
                                oprSrc1 := REG;
                                oprSrc2 := INVALID;
                                isInvalid := NO;
                                branchLikely := YES;

                            when JMP_BGEZL =>
                                condJump := YES;
                                oprSrc1 := REG;
                                oprSrc2 := INVALID;
                                isInvalid := NO;
                                branchLikely := YES;

                            when others =>
                                null;
                        end case;

                    when JMP_BEQL =>
                        condJump := YES;
                        oprSrc1 := REG;
                        oprSrc2 := REG;
                        toWriteReg_o <= NO;
                        writeRegAddr_o <= (others => '0');
                        isInvalid := NO;
                        branchLikely := YES;

                    when JMP_BGTZL =>
                        condJump := YES;
                        oprSrc1 := REG;
                        oprSrc2 := INVALID;
                        isInvalid := NO;
                        branchLikely := YES;

                    when JMP_BLEZL =>
                        condJump := YES;
                        oprSrc1 := REG;
                        oprSrc2 := INVALID;
                        isInvalid := NO;
                        branchLikely := YES;

                    when JMP_BNEL =>
                        condJump := YES;
                        oprSrc1 := REG;
                        oprSrc2 := REG;
                        isInvalid := NO;
                        branchLikely := YES;

                    when OP_COP0 =>
                        case (instRs) is
                            when RS_WAIT_OR_TLBINVF =>
                                if (inst_i(InstFuncIdx) = FUNC_WAIT and inst_i(25) = '1') then
                                    oprSrc1 := INVALID;
                                    oprSrc2 := INVALID;
                                    toWriteReg_o <= NO;
                                    isInvalid := NO;
                                elsif (inst_i(20 downto 6) = 15ub"0" and inst_i(InstFuncIdx) = FUNC_TLBINVF) then
                                    isInvalid := NO;
                                    alut_o <= ALU_TLBINVF;
                                end if;

                            -- Note: in release 6, we need to clear register rt --
                            when RS_MFH =>
                                if (inst_i(InstSaFuncIdx) = 8ub"0") then
                                    alut_o <= ALU_MFH;
                                    oprSrc1 := INVALID;
                                    oprSrc2 := REG;
                                    toWriteReg_o <= YES;
                                    writeRegAddr_o <= instRt;
                                    isInvalid := NO;
                                end if;

                            when others =>
                                null;
                        end case;

                        if (inst_i(25) = '1' and inst_i(24 downto 6) = 19ub"0") then -- bit 25 is CO
                            case (instFunc) is
                                when FUNC_DERET =>
                                    isInvalid := NO;
                                    exceptCause_o <= DERET_CAUSE;

                                when FUNC_TLBWI =>
                                    isInvalid := NO;
                                    alut_o <= ALU_TLBWI;

                                when FUNC_TLBWR =>
                                    isInvalid := NO;
                                    alut_o <= ALU_TLBWR;

                                when FUNC_TLBP =>
                                    isInvalid := NO;
                                    alut_o <= ALU_TLBP;

                                when FUNC_TLBR =>
                                    isInvalid := NO;
                                    alut_o <= ALU_TLBR;

                                when others =>
                                    null;
                            end case;
                        end if;
                    when OP_COP1 =>
                        case (instRs) is
                            when RS_MF =>
                                oprSrcF2 := SINGLE;
                                writeFPRegAddr_o <= instRt;
                                toWriteFPReg_o <= YES;
                                fpAlut_o <= MF;
                                isInvalid := NO;

                            when RS_MT =>
                                oprSrc2 := REG;
                                fpAlut_o <= MT;
                                isInvalid := NO;
                                toWriteFPReg_o <= YES;
                                writeFPRegAddr_o <= instRd;

                            when RS_CF =>
                                oprSrcF1 := INVALID;
                                oprSrcF2 := REGID;
                                fpAlut_o <= CF;
                                isInvalid := NO;
                                toWriteFPReg_o <= YES;
                                writeFPRegAddr_o <= instRt;

                            when RS_CT =>
                                oprSrc2 := REG;
                                fpAlut_o <= CT;
                                isInvalid := NO;
                                toWriteFPReg_o <= YES;
                                writeFPRegAddr_o <= instRd;

                            --when RS_BC =>
                            --    isInvalid := NO;
                            --    cWriteID := inst_i(20 downto 18);
                            --    cTFFlag := inst_i(16);
                            --    ccJump := YES;

                            when FMT_S | FMT_D =>
                                case (instFunc) is
                                    when FUNC_FADD =>
                                        fpAlut_o <= ADD;
                                        isInvalid := NO;
                                        toWriteFPReg_o <= YES;
                                        if (instRs = FMT_D) then
                                            oprSrcF1 := PAIRED;
                                            oprSrcF2 := PAIRED;
                                            writeFPDouble_o <= YES;
                                        else
                                            oprSrcF1 := SINGLE;
                                            oprSrcF2 := SINGLE;
                                            writeFPDouble_o <= NO;
                                        end if;
                                        writeFPRegAddr_o <= inst_i(10 downto 6);

                                    when FUNC_FSUB =>
                                        fpAlut_o <= SUB;
                                        isInvalid := NO;
                                        toWriteFPReg_o <= YES;
                                        if (instRs = FMT_D) then
                                            oprSrcF1 := PAIRED;
                                            oprSrcF2 := PAIRED;
                                            writeFPDouble_o <= YES;
                                        elsif (instRs = FMT_S) then
                                            oprSrcF1 := SINGLE;
                                            oprSrcF2 := SINGLE;
                                            writeFPDouble_o <= NO;
                                        end if;
                                        writeFPRegAddr_o <= inst_i(10 downto 6);

                                    when FUNC_FMUL =>
                                        fpAlut_o <= MUL;
                                        isInvalid := NO;
                                        toWriteFPReg_o <= YES;
                                        if (instRs = FMT_D) then
                                            oprSrcF1 := PAIRED;
                                            oprSrcF2 := PAIRED;
                                            writeFPDouble_o <= YES;
                                        elsif (instRs = FMT_S) then
                                            oprSrcF1 := SINGLE;
                                            oprSrcF2 := SINGLE;
                                            writeFPDouble_o <= NO;
                                        end if;
                                        writeFPRegAddr_o <= inst_i(10 downto 6);

                                    when FUNC_CVT_D =>
                                        if (instRs = FMT_S) then
                                            fpAlut_o <= CVT_D;
                                            isInvalid := NO;
                                            toWriteFPReg_o <= YES;
                                            oprSrcF2 := SINGLE;
                                            writeFPDouble_o <= YES;
                                            writeFPRegAddr_o <= inst_i(10 downto 6);
                                        end if;

                                    when FUNC_CVT_S =>
                                        if (instRs = FMT_D) then
                                            fpAlut_o <= CVT_S;
                                            isInvalid := NO;
                                            toWriteFPReg_o <= YES;
                                            oprSrcF2 := PAIRED;
                                            writeFPDouble_o <= NO;
                                            writeFPRegAddr_o <= inst_i(10 downto 6);
                                        end if;

                                    when others =>
                                        null;
                                end case;

                            --    if (inst_i(7 downto 4) = "0011") then
                            --        oprSrcF1 := PAIRED;
                            --        oprSrcF2 := PAIRED;
                            --        cCondFlag := YES;
                            --        cCondCode := inst_i(3 downto 0);
                            --        cWriteID := inst_i(10 downto 8);
                            --        isInvalid := NO;
                            --    end if;

                            when others =>
                                null;
                        end case;

                    when others =>
                        null;
                end case;
            end if;

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
                            if (extraCmd and inst_i(10) = '1') then
                                isIdEhb_o <= YES;
                            end if;

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
                            null;
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
                    regReadAddr1_o <= instRs;
                    operand1 := regData1_i;
                    if (instRs /= 5ub"0") then
                        -- Ex Push Forward, Mem Wait --
                        if (exToWriteReg_i = YES and exWriteRegAddr_i = instRs) then
                            operand1 := exWriteRegData_i;
                            if (exMemt_i /= INVALID) then
                                toStall_o <= PIPELINE_STOP;
                            end if;
                        elsif (exWriteFPTarget_i = REG and exWriteFPRegAddr_i(4 downto 0) = instRs and exToWriteFPReg_i = YES) then
                            operand1 := exWriteFPRegData_i(31 downto 0);
                        elsif (memToWriteReg_i = YES and memWriteRegAddr_i = instRs) then
                            operand1 := memWriteRegDataShort_i;
                            if (memMemt_i /= INVALID) then
                                if (memPushForward) then
                                    operand1 := memWriteRegDataLong_i;
                                else
                                    toStall_o <= PIPELINE_STOP;
                                end if;
                            end if;
                        elsif (memWriteFPTarget_i = REG and memWriteFPRegAddr_i(4 downto 0) = instRs and memToWriteFPReg_i = YES) then
                            operand1 := memWriteFPRegData_i(31 downto 0);
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
                    regReadAddr2_o <= instRt;
                    operand2 := regData2_i;
                    if (instRt /= 5ub"0") then
                        -- Ex Push Forward, Mem Wait --
                        if (exToWriteReg_i = YES and exWriteRegAddr_i = instRt) then
                            operand2 := exWriteRegData_i;
                            if (exMemt_i /= INVALID) then
                                toStall_o <= PIPELINE_STOP;
                            end if;
                        elsif (exToWriteFPReg_i = YES and exWriteFPTarget_i = REG and exWriteFPRegAddr_i(4 downto 0) = instRt) then
                            operand2 := exWriteFPRegData_i(31 downto 0);
                        elsif (memToWriteReg_i = YES and memWriteRegAddr_i = instRt) then
                            operand2 := memWriteRegDataShort_i;
                            if (memMemt_i /= INVALID) then
                                if (memPushForward) then
                                    operand2 := memWriteRegDataLong_i;
                                else
                                    toStall_o <= PIPELINE_STOP;
                                end if;
                            end if;
                        elsif (memToWriteFPReg_i = YES and memWriteFPTarget_i = REG and memWriteFPRegAddr_i(4 downto 0) = instRt) then
                            operand2 := memWriteFPRegData_i(31 downto 0);
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

            case oprSrcF1 is
                -- Single Push Forward, Paired Wait --
                when SINGLE =>
                    fpRegReadAddr1_o <= instRt;
                    fpRegReadDouble1_o <= NO;
                    foperand1 := fpRegData1_i;
                    -- Ex Push Forward, Mem Wait --
                    if (exToWriteFPReg_i = YES) and (exWriteFPTarget_i = FREG) and ((exWriteFPRegAddr_i(4 downto 0) = instRt)
                        or (exWriteFPRegAddr_i(4 downto 1) = instRt(4 downto 1) and exWriteFPDouble_i = YES))  then
                        if (exWriteFPDouble_i = NO) then
                            foperand1 := exWriteFPRegData_i;
                        else
                            if (instRt(0) = '1') then
                                foperand1 := 32ub"0" & exWriteFPRegData_i(63 downto 32);
                            else
                                foperand1 := 32ub"0" & exWriteFPRegData_i(31 downto 0);
                            end if;
                        end if;
                        if (fpMemt_i /= INVALID) then
                            toStall_o <= PIPELINE_STOP;
                        end if;
                    elsif (memToWriteFPReg_i = YES) and (memWriteFPTarget_i = FREG) and ((memWriteFPRegAddr_i(4 downto 0) = instRt)
                        or (memWriteFPRegAddr_i(4 downto 1) = instRt(4 downto 1) and memWriteFPDouble_i = YES)) then
                            toStall_o <= PIPELINE_STOP;
                    end if;

                when PAIRED =>
                    fpRegReadAddr1_o <= instRt;
                    fpRegReadDouble1_o <= YES;
                    foperand1 := fpregData1_i;
                    if (exToWriteFPReg_i = YES) and (exWriteFPRegAddr_i(4 downto 1) = instRt(4 downto 1)) then
                        toStall_o <= PIPELINE_STOP;
                    elsif (memToWriteFPReg_i = YES) and (memWriteFPRegAddr_i(4 downto 1) = instRt(4 downto 1)) then
                        toStall_o <= PIPELINE_STOP;
                    end if;

                when REGID =>
                    foperand1 := 59ub"0" & instRt;

                when others =>
                    foperand1 := (others => '0');
            end case;

            case oprSrcF2 is
                -- Single Push Forward, Paired Wait --
                when SINGLE =>
                    fpRegReadAddr2_o <= instRd;
                    fpRegReadDouble2_o <= NO;
                    foperand2 := fpRegData2_i;
                    -- Ex Push Forward, Mem Wait --
                    if (exToWriteFPReg_i = YES) and (exWriteFPTarget_i = FREG) and ((exWriteFPRegAddr_i(4 downto 0) = instRd)
                        or (exWriteFPRegAddr_i(4 downto 1) = instRd(4 downto 1) and exWriteFPDouble_i = YES))  then
                        if (exWriteFPDouble_i = NO) then
                            foperand2 := exWriteFPRegData_i;
                        else
                            if (instRd(0) = '1') then
                                foperand2 := 32ub"0" & exWriteFPRegData_i(63 downto 32);
                            else
                                foperand2 := 32ub"0" & exWriteFPRegData_i(31 downto 0);
                            end if;
                        end if;
                        if (fpMemt_i /= INVALID) then
                            toStall_o <= PIPELINE_STOP;
                        end if;
                    elsif (memToWriteFPReg_i = YES) and (memWriteFPTarget_i = FREG) and ((memWriteFPRegAddr_i(4 downto 0) = instRd)
                        or (memWriteFPRegAddr_i(4 downto 1) = instRd(4 downto 1) and memWriteFPDouble_i = YES)) then
                            toStall_o <= PIPELINE_STOP;
                    end if;

                when PAIRED =>
                    fpRegReadAddr2_o <= instRd;
                    fpRegReadDouble2_o <= YES;
                    foperand2 := fpregData2_i;
                    if (exToWriteFPReg_i = YES) and (exWriteFPRegAddr_i(4 downto 1) = instRd(4 downto 1)) then
                        toStall_o <= PIPELINE_STOP;
                    elsif (memToWriteFPReg_i = YES) and (memWriteFPRegAddr_i(4 downto 1) = instRd(4 downto 1)) then
                        toStall_o <= PIPELINE_STOP;
                    end if;

                when REGID =>
                    foperand2 := 59ub"0" & instRd;

                when others =>
                    foperand2 := (others => '0');
            end case;
        end if;

        if (cCondFlag = YES) then
            cResult(3) := floatgreater(foperand2, foperand1);
            cResult(2) := floatless(foperand2, foperand1);
            cResult(1) := floateq(foperand2, foperand1);
            cResult(0) := not (floatorder(foperand1) and floatorder(foperand2));
            if ((cResult(2 downto 0) and cCondCode(2 downto 0)) /= "000") then
                cc(conv_integer(cWriteID)) <= '1';
            else
                cc(conv_integer(cWriteID)) <= '0';
            end if;
        end if;

        if (jumpToRs = YES) then
            branchTargetAddress := operand1;
        end if;

        if (ccJump = YES) then
            nextInstInDelaySlot_o <= YES;
            if (cc(conv_integer(cWriteID)) = cTFFlag) then
                branchTargetAddress := pcPlus4 + instOffsetImm - instImmSign;
                branchFlag := YES;
            end if;
        end if;

        if (condJump = YES) then
            branchToJump := NO;
            branchToLink := NO;
            nextInstInDelaySlot_o <= YES;
            if (instOp = OP_JMPSPECIAL) then
                if (instRt = JMP_BGEZ or (extraCmd and instRt = JMP_BGEZL)) then
                    if (operand1(31) = '0') then
                        branchToJump := YES;
                    end if;
                end if;
                if (instRt = JMP_BLTZ or (extraCmd and instRt = JMP_BLTZL)) then
                    if (operand1(31) = '1') then
                        branchToJump := YES;
                    end if;
                end if;
                if (instRt = JMP_BGEZAL) then
                    if (operand1(31) = '0') then
                        branchToJump := YES;
                    end if;
                    branchToLink := YES;
                end if;
                if (instRt = JMP_BLTZAL) then
                    if (operand1(31) = '1') then
                        branchToJump := YES;
                    end if;
                    branchToLink := YES;
                end if;
            end if;
            if (instOp = JMP_BEQ or (extraCmd and instOp = JMP_BEQL)) then
                if (operand1 = operand2) then
                    branchToJump := YES;
                end if;
            end if;
            if (instOp = JMP_BGTZ or (extraCmd and instOp = JMP_BGTZL)) then
                if (operand1(31) = '0' and operand1 /= 32ux"0") then
                    branchToJump := YES;
                end if;
            end if;
            if (instOp = JMP_BLEZ or (extraCmd and instOp = JMP_BLEZL)) then
                if (operand1(31) = '1' or operand1 = 32ux"0") then
                    branchToJump := YES;
                end if;
            end if;
            if (instOp = JMP_BNE or (extraCmd and instOp = JMP_BNEL)) then
                if (operand1 /= operand2) then
                    branchToJump := YES;
                end if;
            end if;

            if (branchToJump = YES) then
                branchTargetAddress := pcPlus4 + instOffsetImm - instImmSign;
                branchFlag := YES;
            elsif (extraCmd and branchLikely = YES) then
                blNullify := PIPELINE_STOP;
                nextInstInDelaySlot_o <= NO;
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

        if (extraCmd and tneFlag = YES and operand1 /= operand2) then
            exceptCause_o <= TRAP_CAUSE;
        end if;
        if (extraCmd and teqFlag = YES and operand1 = operand2) then
            exceptCause_o <= TRAP_CAUSE;
        end if;
        operand1_o <= operand1;
        operand2_o <= operand2;
        operandX_o <= operandX;
        foperand1_o <= foperand1;
        foperand2_o <= foperand2;
        branchFlag_o <= branchFlag;
        branchTargetAddress_o <= branchTargetAddress;
        blNullify_o <= blNullify;
    end process;
end bhv;
