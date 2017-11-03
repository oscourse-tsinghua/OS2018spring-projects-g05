library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

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
        idToStall_i, exToStall_i: in std_logic;
        stall_o: out std_logic_vector(StallWidth);
        exceptType_i: in std_logic_vector(ExceptionWidth);
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
            if (exceptType_i /= EXCEPTION_ZERO_WORD) then
                flush_o <= '1';
                stall_o <= (others => '0');
                case (exceptType_i) is
                    when EXTERNALEXCEPTION =>
                        newPC_o <= EXTERNALEXCEPTIONBRANCHADDR;
                    when SYSCALLEXCEPTION =>
                        newPC_o <= SYSCALLEXCEPTIONBRANCHADDR;
                    when INVALIDINSTEXCEPTION =>
                        newPC_o <= INVALIDINSTEXCEPTIONBRANCHADDR;
                    when OVERFLOWEXCEPTION =>
                        newPC_o <= OVERFLOWEXCEPTIONBRANCHADDR;
                    when ERETEXCEPTION =>
                        newPC_o <= cp0Epc_i;
                    when others =>
                        null;
                end case;
            elsif (exToStall_i = PIPELINE_STOP) then
                stall_o <= "111100";
                flush_o <= '0';
            elsif (idToStall_i = PIPELINE_STOP) then
                stall_o <= "111000";
                flush_o <= '0';
            else
                stall_o <= "000000";
                flush_o <= '0';
            end if;
        end if;
    end process;
end bhv;