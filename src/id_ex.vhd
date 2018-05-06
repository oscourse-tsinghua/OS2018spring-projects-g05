library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.alu_const.all;
use work.mem_const.all;
use work.except_const.all;

entity id_ex is
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
        idLinkAddress_i: in std_logic_vector(AddrWidth);
        idIsInDelaySlot_i: in std_logic;
        nextInstInDelaySlot_i: in std_logic;
        flush_i: in std_logic;
        idCurrentInstAddr_i: in std_logic_vector(AddrWidth);
        idExceptCause_i: in std_logic_vector(ExceptionCauseWidth);
        valid_i: in std_logic;

        alut_o: out AluType;
        memt_o: out MemType;
        operand1_o: out std_logic_vector(DataWidth);
        operand2_o: out std_logic_vector(DataWidth);
        operandX_o: out std_logic_vector(DataWidth);
        toWriteReg_o: out std_logic;
        writeRegAddr_o: out std_logic_vector(RegAddrWidth);
        exLinkAddress_o: out std_logic_vector(AddrWidth);
        exIsInDelaySlot_o: out std_logic;
        isInDelaySlot_o: out std_logic;
        exCurrentInstAddr_o: out std_logic_vector(AddrWidth);
        exExceptCause_o: out std_logic_vector(ExceptionCauseWidth);
        valid_o: out std_logic
    );
end id_ex;

architecture bhv of id_ex is
begin
    process(clk) begin
        if (rising_edge(clk)) then
            if (
                (rst = RST_ENABLE) or
                (flush_i = YES)
            ) then
                alut_o <= INVALID;
                memt_o <= INVALID;
                operand1_o <= (others => '0');
                operand2_o <= (others => '0');
                operandX_o <= (others => '0');
                toWriteReg_o <= NO;
                writeRegAddr_o <= (others => '0');
                exExceptCause_o <= NO_CAUSE;
                exLinkAddress_o <= (others => '0');
                exIsInDelaySlot_o <= NO;
                isInDelaySlot_o <= NO;
                exCurrentInstAddr_o <= (others => '0');
                valid_o <= NO;
            elsif (stall_i(ID_STOP_IDX) = PIPELINE_STOP and stall_i(EX_STOP_IDX) = PIPELINE_NONSTOP) then
                alut_o <= INVALID;
                memt_o <= INVALID;
                operand1_o <= (others => '0');
                operand2_o <= (others => '0');
                operandX_o <= (others => '0');
                toWriteReg_o <= NO;
                writeRegAddr_o <= (others => '0');
                exExceptCause_o <= NO_CAUSE;
                exLinkAddress_o <= (others => '0');
                exIsInDelaySlot_o <= NO;
                -- Keep `isInDelaySlot_o` as old value
                exCurrentInstAddr_o <= (others => '0');
                valid_o <= NO;
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
                exCurrentInstAddr_o <= idCurrentInstAddr_i;
                valid_o <= valid_i;
            end if;
        end if;
    end process;
end bhv;
