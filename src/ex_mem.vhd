library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.global_const.all;
use work.mem_const.all;
use work.except_const.all;
use work.cp0_const.all;

entity ex_mem is
    port (
        rst, clk: in std_logic;

        stall_i: in std_logic_vector(StallWidth);
        toWriteReg_i: in std_logic;
        writeRegAddr_i: in std_logic_vector(RegAddrWidth);
        writeRegData_i: in std_logic_vector(DataWidth);
        toWriteReg_o: out std_logic;
        writeRegAddr_o: out std_logic_vector(RegAddrWidth);
        writeRegData_o: out std_logic_vector(DataWidth);

        -- Hi Lo --
        toWriteHi_i, toWriteLo_i: in std_logic;
        writeHiData_i, writeLoData_i: in std_logic_vector(DataWidth);
        toWriteHi_o, toWriteLo_o: out std_logic;
        writeHiData_o, writeLoData_o: out std_logic_vector(DataWidth);

        -- Memory --
        memt_i: in MemType;
        memAddr_i: in std_logic_vector(AddrWidth);
        memData_i: in std_logic_vector(DataWidth);
        memt_o: out MemType;
        memAddr_o: out std_logic_vector(AddrWidth);
        memData_o: out std_logic_vector(DataWidth);

        -- multi-period --
        tempProduct_i: in std_logic_vector(DoubleDataWidth);
        cnt_i: in std_logic_vector(CntWidth);
        tempProduct_o: out std_logic_vector(DoubleDataWidth);
        cnt_o: out std_logic_vector(CntWidth);

        -- interact with cp0 --
        cp0RegData_i: in std_logic_vector(DataWidth);
        cp0RegWriteAddr_i: in std_logic_vector(CP0RegAddrWidth);
        cp0RegWriteSel_i: in std_logic_vector(SelWidth);
        cp0RegWe_i: in std_logic;
        cp0Sp_i: in CP0Special;
        cp0RegData_o: out std_logic_vector(DataWidth);
        cp0RegWriteAddr_o: out std_logic_vector(CP0RegAddrWidth);
        cp0RegWriteSel_o: out std_logic_vector(SelWidth);
        cp0RegWe_o: out std_logic;
        cp0Sp_o: out CP0Special;

        -- for exception --
        valid_i: in std_logic;
        flush_i: in std_logic;
        exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
        tlbRefill_i: in std_logic;
        isInDelaySlot_i: in std_logic;
        currentInstAddr_i: in std_logic_vector(AddrWidth);
        valid_o: out std_logic;
        exceptCause_o: out std_logic_vector(ExceptionCauseWidth);
        tlbRefill_o: out std_logic;
        isInDelaySlot_o: out std_logic;
        currentInstAddr_o: out std_logic_vector(AddrWidth);
        flushForceWrite_i: in std_logic;
        flushForceWrite_o: out std_logic
    );
end ex_mem;

architecture bhv of ex_mem is
begin
    process(clk) begin
        if (rising_edge(clk)) then
            if (
                rst = RST_ENABLE or
                flush_i = YES or
                (stall_i(EX_STOP_IDX) = PIPELINE_STOP and stall_i(MEM_STOP_IDX) = PIPELINE_NONSTOP)
            ) then
                toWriteReg_o <= NO;
                writeRegAddr_o <= (others => '0');
                writeRegData_o <= (others => '0');

                toWriteHi_o <= NO;
                toWriteLo_o <= NO;
                writeHiData_o <= (others => '0');
                writeLoData_o <= (others => '0');

                memt_o <= INVALID;
                memAddr_o <= (others => '0');
                memData_o <= (others => '0');

                tempProduct_o <= (others => '0');
                cnt_o <= (others => '0');
                exceptCause_o <= NO_CAUSE;
                tlbRefill_o <= '0';
                isInDelaySlot_o <= NO;
                currentInstAddr_o <= (others => '0');

                cp0RegWe_o <= NO;
                cp0RegData_o <= (others => '0');
                cp0RegWriteAddr_o <= (others => '0');
                cp0RegWriteSel_o <= (others => '0');
                cp0Sp_o <= INVALID;

                valid_o <= NO;
                flushForceWrite_o <= NO;

                if (stall_i(EX_STOP_IDX) = PIPELINE_STOP and stall_i(MEM_STOP_IDX) = PIPELINE_NONSTOP) then
                    tempProduct_o <= tempProduct_i;
                    cnt_o <= cnt_i;
                end if;
            elsif (stall_i(EX_STOP_IDX) = PIPELINE_NONSTOP) then
                toWriteReg_o <= toWriteReg_i;
                writeRegAddr_o <= writeRegAddr_i;
                writeRegData_o <= writeRegData_i;

                toWriteHi_o <= toWriteHi_i;
                toWriteLo_o <= toWriteLo_i;
                writeHiData_o <= writeHiData_i;
                writeLoData_o <= writeLoData_i;

                memt_o <= memt_i;
                memAddr_o <= memAddr_i;
                memData_o <= memData_i;

                cp0RegWe_o <= cp0RegWe_i;
                cp0RegWriteAddr_o <= cp0RegWriteAddr_i;
                cp0RegWriteSel_o <= cp0RegWriteSel_i;
                cp0RegData_o <= cp0RegData_i;
                cp0Sp_o <= cp0Sp_i;

                exceptCause_o <= exceptCause_i;
                tlbRefill_o <= tlbRefill_i;
                isInDelaySlot_o <= isInDelaySlot_i;
                currentInstAddr_o <= currentInstAddr_i;

                valid_o <= valid_i;

                tempProduct_o <= tempProduct_i;
                cnt_o <= cnt_i;
                flushForceWrite_o <= flushForceWrite_i;
            end if;
        end if;
    end process;
end bhv;
