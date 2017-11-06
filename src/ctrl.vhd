library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.except_const.all;

-- stall: std_logic_vector(0 to 5)
-- stall(0) = '1':  pc stay the same
-- stall(1) = '1':  if stop
-- stall(2) = '1':  id stop
-- stall(3) = '1':  ex stop
-- stall(4) = '1': mem stop
-- stall(5) = '1':  wb stop

entity ctrl is
    port (
        rst: in std_logic;
        ifToStall_i, idToStall_i, exToStall_i, memToStall_i: in std_logic;
        stall_o: out std_logic_vector(StallWidth);
        exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
        cp0Epc_i: in std_logic_vector(DataWidth);
        newPC_o: out std_logic_vector(AddrWidth);
        flush_o: out std_logic
    );
end ctrl;

architecture bhv of ctrl is
begin
    process(all) begin
        if (rst = RST_ENABLE) then
            stall_o <= (others => '0');
            flush_o <= '0';
            newPC_o <= (others => '0');
        else
            if (exceptCause_i /= NO_CAUSE) then
                flush_o <= '1';
                stall_o <= (others => '0');
                case (exceptCause_i) is
                    when EXTERNAL_CAUSE =>
                        newPC_o <= EXTERNAL_INTERRUPT_BRANCH_ADDR;
                    when SYSCALL_CAUSE =>
                        newPC_o <= SYSCALL_EXCEPTION_BRANCH_ADDR;
                    when INVALID_INST_CAUSE =>
                        newPC_o <= INVALID_INST_EXCEPTION_BRANCH_ADDR;
                    when OVERFLOW_CAUSE =>
                        newPC_o <= OVERFLOW_EXCEPTION_BRANCH_ADDR;
                    when ERET_Cause =>
                        newPC_o <= cp0Epc_i;
                    when others =>
                        null;
                end case;
            else
                flush_o <= '0';
                if (memToStall_i = PIPELINE_STOP) then
                    stall_o <= "111110";
                elsif (exToStall_i = PIPELINE_STOP) then
                    stall_o <= "111100";
                elsif (idToStall_i = PIPELINE_STOP) then
                    stall_o <= "111000";
                elsif (ifToStall_i = PIPELINE_STOP) then
                    stall_o <= "110000";
                else
                    stall_o <= "000000";
                end if;
            end if;
        end if;
    end process;
end bhv;
