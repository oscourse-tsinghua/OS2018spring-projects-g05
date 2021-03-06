library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.global_const.all;
use work.cp0_const.all;

entity mem_wb is
    port (
        rst, clk: in std_logic;

        stall_i: in std_logic_vector(StallWidth);
        toWriteReg_i: in std_logic;
        writeRegAddr_i: in std_logic_vector(RegAddrWidth);
        writeRegData_i: in std_logic_vector(DataWidth);
        currentInstAddr_i: in std_logic_vector(AddrWidth);
        toWriteReg_o: out std_logic;
        writeRegAddr_o: out std_logic_vector(RegAddrWidth);
        writeRegData_o: out std_logic_vector(DataWidth);
        currentInstAddr_o: out std_logic_vector(AddrWidth);

        -- Hi Lo --
        toWriteHi_i, toWriteLo_i: in std_logic;
        writeHiData_i, writeLoData_i: in std_logic_vector(DataWidth);
        toWriteHi_o, toWriteLo_o: out std_logic;
        writeHiData_o, writeLoData_o: out std_logic_vector(DataWidth);

        -- interact with CP0 --
        memCP0RegData_i: in std_logic_vector(DataWidth);
        memCP0RegWriteAddr_i: in std_logic_vector(CP0RegAddrWidth);
        memCP0RegWriteSel_i: in std_logic_vector(SelWidth);
        memCP0RegWe_i: in std_logic;
        cp0Sp_i: in CP0Special;
        wbCP0RegData_o: out std_logic_vector(DataWidth);
        wbCP0RegWriteAddr_o: out std_logic_vector(CP0RegAddrWidth);
        wbCP0RegWriteSel_o: out std_logic_vector(SelWidth);
        wbCP0RegWe_o: out std_logic;
        cp0Sp_o: out CP0Special;
        flushForceWrite_i: in std_logic;

        -- for exception --
        flush_i: in std_logic
    );
end mem_wb;

architecture bhv of mem_wb is
begin
    process(clk) begin
        if (rising_edge(clk)) then
            if (
                (rst = RST_ENABLE) or
                (flush_i = YES) or
                (stall_i(MEM_STOP_IDX) = PIPELINE_STOP and stall_i(WB_STOP_IDX) = PIPELINE_NONSTOP)
            ) then
                if (flushForceWrite_i = NO) then
                    toWriteReg_o <= NO;
                    writeRegAddr_o <= (others => '0');
                    writeRegData_o <= (others => '0');
                    currentInstAddr_o <= (others => '0');
                else
                    toWriteReg_o <= toWriteReg_i;
                    writeRegAddr_o <= writeRegAddr_i;
                    writeRegData_o <= writeRegData_i;
                    currentInstAddr_o <= writeRegData_i - "1000";
                end if;

                toWriteHi_o <= NO;
                toWriteLo_o <= NO;
                writeHiData_o <= (others => '0');
                writeLoData_o <= (others => '0');

                wbCP0RegWe_o <= NO;
                wbCP0RegData_o <= (others => '0');
                wbCP0RegWriteAddr_o <= (others => '0');
                wbCP0RegWriteSel_o <= (others => '0');

                cp0Sp_o <= INVALID;
            elsif (stall_i(MEM_STOP_IDX) = PIPELINE_NONSTOP) then
                toWriteReg_o <= toWriteReg_i;
                writeRegAddr_o <= writeRegAddr_i;
                writeRegData_o <= writeRegData_i;

                toWriteHi_o <= toWriteHi_i;
                toWriteLo_o <= toWriteLo_i;
                writeHiData_o <= writeHiData_i;
                writeLoData_o <= writeLoData_i;

                wbCP0RegWe_o <= memCP0RegWe_i;
                wbCP0RegWriteAddr_o <= memCP0RegWriteAddr_i;
                wbCP0RegWriteSel_o <= memCP0RegWriteSel_i;
                wbCP0RegData_o <= memCP0RegData_i;

                cp0Sp_o <= cp0Sp_i;
                currentInstAddr_o <= currentInstAddr_i;
            end if;
        end if;
    end process;
end bhv;
