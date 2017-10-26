library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.global_const.all;
use work.inst_const.all;

entity pc_reg is
    port (
        rst, clk: in std_logic;
        stall_i: in std_logic_vector(StallWidth);
        branch_target_address_i: in std_logic_vector(AddrWidth);
        branch_flag_i: in std_logic;
        pc_o: out std_logic_vector(AddrWidth);
        pcEnable_o: out std_logic
    );
end pc_reg;

architecture bhv of pc_reg is
    signal pc: std_logic_vector(AddrWidth);
begin
    process(clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                pcEnable_o <= DISABLE;
                pc <= (others => '0');
            elsif (stall_i(PC_STOP_IDX) = PIPELINE_NONSTOP) then
                pcEnable_o <= ENABLE;
                if (branch_flag_i == BRANCH_FLAG) then
                    pc <= branch_target_address_i;
                else
                    pc <= pc + 4;
                end if;
            end if;
        end if;
    end process;

    pc_o <= pc;
end bhv;