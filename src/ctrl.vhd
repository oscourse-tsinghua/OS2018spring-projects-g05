library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-- NOTE: std_logic_unsigned cannot be used at the same time with std_logic_unsigned
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
        exceptNormalBaseAddr:   std_logic_vector(AddrWidth);
        exceptBootBaseAddr:     std_logic_vector(AddrWidth);
        tlbRefillExl0Offset:    std_logic_vector(AddrWidth);
        generalExceptOffset:    std_logic_vector(AddrWidth);
        interruptIv1Offset:     std_logic_vector(AddrWidth)
    );
    port (
        rst, clk: in std_logic;

        -- Stall
        ifToStall_i, idToStall_i, exToStall_i, memToStall_i: in std_logic;
        stall_o: out std_logic_vector(StallWidth);

        -- Exception
        exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
        cp0Status_i, cp0Cause_i, cp0Epc_i: in std_logic_vector(DataWidth);
        newPC_o: out std_logic_vector(AddrWidth);
        flush_o: out std_logic;
        toWriteBadVAddr_o: out std_logic;
        badVAddr_o: out std_logic_vector(AddrWidth)
    );
end ctrl;

architecture bhv of ctrl is
    signal toWriteBadVAddr: std_logic;
    signal badVAddr: std_logic_vector(AddrWidth);
begin
    process(all)
        variable newPC: std_logic_vector(AddrWidth);
    begin
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
                    newPC := exceptNormalBaseAddr;
                else
                    newPC := exceptBootBaseAddr;
                end if;
                if (exceptCause_i = ERET_CAUSE) then
                    if (cp0Epc_i(1 downto 0) = "00") then
                        newPC := cp0Epc_i;
                    else
                        toWriteBadVAddr <= YES;
                        badVAddr <= cp0Epc_i;
                        newPC := newPC + generalExceptOffset;
                    end if;
                elsif (
                    (exceptCause_i = TLB_LOAD_CAUSE or exceptCause_i = TLB_STORE_CAUSE) and
                    cp0Status_i(STATUS_EXL_BIT) = '0'
                ) then
                    newPC := newPC + tlbRefillExl0Offset;
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

    process(clk) begin
        if (rising_edge(clk)) then
            badVAddr_o <= badVAddr;
            toWriteBadVAddr_o <= toWriteBadVAddr;
        end if;
    end process;
end bhv;
