library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.global_const.all;
use work.inst_const.all;

entity pc_reg is
    generic (
        instEntranceAddr: std_logic_vector(AddrWidth)
    );
    port (
        rst, clk: in std_logic;
        stall_i: in std_logic_vector(StallWidth);
        branchTargetAddress_i: in std_logic_vector(AddrWidth);
        branchFlag_i: in std_logic;
        flush_i: in std_logic;
        newPc_i: in std_logic_vector(AddrWidth);
        pc_o: out std_logic_vector(AddrWidth);
        pcEnable_o: out std_logic
    );
end pc_reg;

architecture bhv of pc_reg is
    signal pc: std_logic_vector(AddrWidth);
    --signal lastBranchTargetAddress: std_logic_vector(AddrWidth);
    --signal lastBranchFlag: std_logic;
begin
    process(clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                pcEnable_o <= DISABLE;
                pc <= instEntranceAddr - 4;
                --lastBranchFlag <= NO;
            elsif (flush_i = YES) then
                pc <= newPc_i;
                --lastBranchFlag <= NO;
            elsif (stall_i(PC_STOP_IDX) = PIPELINE_NONSTOP) then
                pcEnable_o <= ENABLE;
                if (branchFlag_i = YES) then
                    pc <= branchTargetAddress_i;
                --elsif (lastBranchFlag = YES) then
                --    pc <= lastBranchTargetAddress;
                --    lastBranchFlag <= NO;
                else
                    pc <= pc + 4;
                end if;
            --elsif (lastBranchFlag = NO) then
            --    lastBranchFlag <= branchFlag_i;
            --    lastBranchTargetAddress <= branchTargetAddress_i;
            end if;
        end if;
    end process;

    pc_o <= pc;
end bhv;
