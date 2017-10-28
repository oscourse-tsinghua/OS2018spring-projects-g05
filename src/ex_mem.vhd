library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.mem_const.all;

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
        exCP0RegData_i: in std_logic_vector(DataWidth);
        exCP0RegWriteAddr_i: in std_logic_vector(CP0RegAddrWidth);
        exCP0RegWe_i: in std_logic;
        memCP0RegData_o: out std_logic_vector(DataWidth);
        memCP0RegWriteAddr_o: out std_logic_vector(CP0RegAddrWidth);
        memCP0RegWe_o: out std_logic
    );
end ex_mem;

architecture bhv of ex_mem is
begin
    process(clk) begin
        if (rising_edge(clk)) then
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
            if (rst /= RST_ENABLE) then
                if (stall_i(EX_STOP_IDX) = PIPELINE_STOP and stall_i(MEM_STOP_IDX) = PIPELINE_NONSTOP) then
                    tempProduct_o <= tempProduct_i;
                    cnt_o <= cnt_i;
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
                end if;
            end if;
        end if;
    end process;
end bhv;
