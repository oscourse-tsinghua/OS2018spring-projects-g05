library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.alu_const.all;
use work.mem_const.all;
use work.except_const.all;

entity id_ex is
    port (
        rst, clk: in std_logic;

        -- basic operation --
        operand1_i: in std_logic_vector(DataWidth);
        operand2_i: in std_logic_vector(DataWidth);
        operandX_i: in std_logic_vector(DataWidth);
        toWriteReg_i: in std_logic;
        writeRegAddr_i: in std_logic_vector(RegAddrWidth);
        operand1_o: out std_logic_vector(DataWidth);
        operand2_o: out std_logic_vector(DataWidth);
        operandX_o: out std_logic_vector(DataWidth);
        toWriteReg_o: out std_logic;
        writeRegAddr_o: out std_logic_vector(RegAddrWidth);

        -- memory and stall --
        alut_i: in AluType;
        memt_i: in MemType;
        alut_o: out AluType;
        memt_o: out MemType;
        stall_i: in std_logic_vector(StallWidth);

        -- exception --
        idExceptCause_i: in std_logic_vector(ExceptionCauseWidth);
        idTlbRefill_i: in std_logic;
        exExceptCause_o: out std_logic_vector(ExceptionCauseWidth);
        exTlbRefill_o: out std_logic;
        valid_i: in std_logic;
        valid_o: out std_logic;
        noInt_i: in std_logic;
        noInt_o: out std_logic;
        flush_i: in std_logic;

        -- branch --
        idLinkAddress_i: in std_logic_vector(AddrWidth);
        idIsInDelaySlot_i: in std_logic;
        nextInstInDelaySlot_i: in std_logic;
        exLinkAddress_o: out std_logic_vector(AddrWidth);
        exIsInDelaySlot_o: out std_logic;
        isInDelaySlot_o: out std_logic;
        idCurrentInstAddr_i: in std_logic_vector(AddrWidth);
        exCurrentInstAddr_o: out std_logic_vector(AddrWidth);
        flushForceWrite_i: in std_logic;
        flushForceWrite_o: out std_logic
    );
end id_ex;

architecture bhv of id_ex is
    signal exValid, keepDelaySlot: std_logic;

    attribute dont_touch: string;
    attribute dont_touch of exValid: signal is "true";
    attribute dont_touch of keepDelaySlot: signal is "true";
    attribute dont_touch of idIsInDelaySlot_i: signal is "true";
begin
    keepDelaySlot <= YES when idIsInDelaySlot_i = YES and exValid = NO else NO;

    process(clk) begin
        if (rising_edge(clk)) then
            if (
                (rst = RST_ENABLE) or
                (flush_i = YES and keepDelaySlot = NO)
            ) then
                alut_o <= INVALID;
                memt_o <= INVALID;
                operand1_o <= (others => '0');
                operand2_o <= (others => '0');
                operandX_o <= (others => '0');
                toWriteReg_o <= NO;
                writeRegAddr_o <= (others => '0');
                exExceptCause_o <= NO_CAUSE;
                exTlbRefill_o <= '0';
                exLinkAddress_o <= (others => '0');
                exIsInDelaySlot_o <= NO;
                isInDelaySlot_o <= NO;
                exCurrentInstAddr_o <= (others => '0');
                exValid <= NO;
                noInt_o <= NO;
                flushForceWrite_o <= NO;
            elsif (stall_i(ID_STOP_IDX) = PIPELINE_STOP and stall_i(EX_STOP_IDX) = PIPELINE_NONSTOP) then
                alut_o <= INVALID;
                memt_o <= INVALID;
                operand1_o <= (others => '0');
                operand2_o <= (others => '0');
                operandX_o <= (others => '0');
                toWriteReg_o <= NO;
                writeRegAddr_o <= (others => '0');
                exExceptCause_o <= NO_CAUSE;
                exTlbRefill_o <= '0';
                exLinkAddress_o <= (others => '0');
                exIsInDelaySlot_o <= NO;
                -- Keep `isInDelaySlot_o` as old value
                exCurrentInstAddr_o <= (others => '0');
                exValid <= NO;
                noInt_o <= NO;
                flushForceWrite_o <= flushForceWrite_i;
            elsif (stall_i(ID_STOP_IDX) = PIPELINE_NONSTOP) then
                alut_o <= alut_i;
                memt_o <= memt_i;
                operand1_o <= operand1_i;
                operand2_o <= operand2_i;
                operandX_o <= operandX_i;
                toWriteReg_o <= toWriteReg_i;
                writeRegAddr_o <= writeRegAddr_i;
                exLinkAddress_o <= idLinkAddress_i;
                exIsInDelaySlot_o <= idIsInDelaySlot_i;
                if (valid_i = YES) then
                    isInDelaySlot_o <= nextInstInDelaySlot_i;
                end if;
                exExceptCause_o <= idExceptCause_i;
                exTlbRefill_o <= idTlbRefill_i;
                exCurrentInstAddr_o <= idCurrentInstAddr_i;
                exValid <= valid_i;
                noInt_o <= noInt_i;
                flushForceWrite_o <= flushForceWrite_i;
            end if;
        end if;
    end process;
    valid_o <= exValid;
end bhv;
