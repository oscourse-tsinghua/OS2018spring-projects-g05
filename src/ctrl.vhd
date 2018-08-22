library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
-- NOTE: std_logic_unsigned cannot be used at the same time with std_logic_signed
--       Use numeric_std if signed number is needed (different API)
use work.global_const.all;
use work.except_const.all;
use work.cp0_const.all;

-- stall: std_logic_vector(0 to 5)
-- stall(0) = '1':  pc stay the same
-- stall(1) = '1':  if stop
-- stall(2) = '1':  id stop
-- stall(3) = '1':  ex stop
-- stall(4) = '1': mem stop
-- stall(5) = '1':  wb stop

entity ctrl is
    generic (
        exceptBootBaseAddr:     std_logic_vector(AddrWidth);
        tlbRefillExl0Offset:    std_logic_vector(AddrWidth);
        generalExceptOffset:    std_logic_vector(AddrWidth);
        interruptIv1Offset:     std_logic_vector(AddrWidth)
    );
    port (
        rst, clk: in std_logic;

        -- Stall
        ifToStall_i, idToStall_i, exToStall_i, memToStall_i, blNullify_i: in std_logic;
        scStall_i: in integer;
        stall_o: out std_logic_vector(StallWidth);
        idNextInDelaySlot_i: in std_logic;

        -- Exception
        exceptionBase_i: in std_logic_vector(DataWidth);
        exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
        cp0Status_i, cp0Cause_i, cp0Epc_i: in std_logic_vector(DataWidth);
        depc_i: in std_logic_vector(AddrWidth);
        newPC_o: out std_logic_vector(AddrWidth);
        flush_o: out std_logic;
        toWriteBadVAddr_o: out std_logic;
        badVAddr_o: out std_logic_vector(AddrWidth);
        tlbRefill_i: in std_logic;

        -- Hazard Barrier
        isIdEhb_i: in std_logic;
        excp0regWe_i: in std_logic;
        memcp0regWe_i: in std_logic;
        wbcp0regWe_i: in std_logic
    );
end ctrl;

architecture bhv of ctrl is
    signal toWriteBadVAddr: std_logic;
    signal badVAddr: std_logic_vector(AddrWidth);
begin
    process(all)
        variable newPC, epc: std_logic_vector(AddrWidth);
    begin
        newPC_o <= (others => '0');
        newPC := (others => 'X');
        if (rst = RST_ENABLE) then
            stall_o <= (others => '0');
            flush_o <= '0';
            newPC_o <= (others => '0');
            badVAddr <= (others => '0');
            toWriteBadVAddr <= NO;
        else
            toWriteBadVAddr <= NO;
            badVAddr <= (others => '0');
            if (exceptCause_i /= NO_CAUSE) then
                flush_o <= '1';
                stall_o <= (others => '0');
                if (cp0Status_i(STATUS_BEV_BIT) = '0') then
                    newPC := exceptionBase_i;
                else
                    newPC := exceptBootBaseAddr;
                end if;
                if (exceptCause_i = ERET_CAUSE) then
                    epc := cp0Epc_i;
                    if (cp0Epc_i(1 downto 0) = "00") then
                        newPC := epc;
                    else
                        toWriteBadVAddr <= YES;
                        badVAddr <= epc;
                        newPC := newPC + generalExceptOffset;
                    end if;
                elsif (exceptCause_i = EXTERNAL_CAUSE and cp0Cause_i(CAUSE_IV_BIT) = '1') then
                    newPC := newPC + interruptIv1Offset;
                else
                    newPC := newPC + generalExceptOffset;
                end if;
                newPC_o <= newPC;
            else
                flush_o <= '0';
                if (memToStall_i = PIPELINE_STOP) then
                    stall_o <= "111110";
                elsif (exToStall_i = PIPELINE_STOP) then
                    stall_o <= "111100";
                elsif (idToStall_i = PIPELINE_STOP or (idNextInDelaySlot_i = YES and ifToStall_i = PIPELINE_STOP)) then
                    stall_o <= "111000";
                elsif (blNullify_i = PIPELINE_STOP) then
                    stall_o <= "010000";
                elsif (ifToStall_i = PIPELINE_STOP) then
                    stall_o <= "111000";
                else
                    stall_o <= "000000";
                end if;
            end if;
        end if;
    end process;

    process(clk) begin
        if (rising_edge(clk)) then
            badVAddr_o <= badVAddr;
            toWriteBadVAddr_o <= toWriteBadVAddr;
        end if;
    end process;
end bhv;
