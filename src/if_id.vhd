library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.except_const.all;

entity if_id is
    port (
        rst, clk: in std_logic;

        pc_i: in std_logic_vector(AddrWidth);
        instEnable_i: in std_logic; -- Disabled for 1 period when powered up
        inst_i: in std_logic_vector(InstWidth);
        stall_i: in std_logic_vector(StallWidth);
        pc_o: out std_logic_vector(AddrWidth);
        valid_o: out std_logic; -- There IS an instruction, not pipeline stopping
        inst_o: out std_logic_vector(InstWidth);

        exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
        tlbRefill_i: in std_logic;
        exceptCause_o: out std_logic_vector(ExceptionCauseWidth);
        tlbRefill_o: out std_logic;
        flush_i: in std_logic
    );
end if_id;

architecture bhv of if_id is
begin
    process(clk) begin
        if (rising_edge(clk)) then
            if (
                (rst = RST_ENABLE) or
                (flush_i = YES) or
                (instEnable_i = DISABLE) or
                ((stall_i(IF_STOP_IDX) = PIPELINE_STOP and stall_i(ID_STOP_IDX) = PIPELINE_NONSTOP))
            ) then
                pc_o <= (others => '0');
                valid_o <= NO;
                inst_o <= (others => '0');
                exceptCause_o <= NO_CAUSE;
                tlbRefill_o <= '0';
            elsif (stall_i(IF_STOP_IDX) = PIPELINE_NONSTOP) then
                pc_o <= pc_i;
                valid_o <= YES;
                inst_o <= inst_i;
                exceptCause_o <= exceptCause_i;
                tlbRefill_o <= tlbRefill_i;
            end if;
        end if;
    end process;
end bhv;
