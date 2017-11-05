library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
-- NOTE: std_logic_unsigned cannot be used at the same time with std_logic_unsigned
--       Use numeric_std if signed number is needed (different API)
use work.cp0_const.all;
use work.global_const.all;
use work.except_const.all;

entity cp0_reg is
    port(
        -- input signals for CP0 processor
        -- refers to page 295 in that book
        we_i: in std_logic;
        rst, clk: in std_logic;
        waddr_i: in std_logic_vector(CP0RegAddrWidth);
        raddr_i: in std_logic_vector(CP0RegAddrWidth);
        data_i: in std_logic_vector(DataWidth);
        int_i: in std_logic_vector(IntWidth);

        -- output signals for CP0 processor
        -- refers to page 295 in that book still
        -- NOTE: These are REGISTERS
        data_o: out std_logic_vector(DataWidth);
        count_o: out std_logic_vector(DataWidth);
        compare_o: out std_logic_vector(DataWidth);
        status_o: out std_logic_vector(DataWidth);
        cause_o: out std_logic_vector(DataWidth);
        epc_o: out std_logic_vector(DataWidth);
        config_o: out std_logic_vector(DataWidth);
        prid_o: out std_logic_vector(DataWidth);
        timerInt_o: out std_logic;

        -- for exception --
        exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
        currentInstAddr_i: in std_logic_vector(AddrWidth);
        isIndelaySlot_i: in std_logic
    );
end cp0_reg;

architecture bhv of cp0_reg is
begin
    process(clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                count_o <= (others => '0');
                compare_o <= (others => '0');
                status_o <= "00010000000000000000000000000000";
                cause_o <= (others => '0');
                epc_o <= (others => '0');
                config_o <= "00000000000000001000000000000000";
                prid_o <= "00000000010011000000000100000010";
                timerInt_o <= INTERRUPT_NOT_ASSERT;
            else
                count_o <= count_o + 1;
                cause_o(CauseIpHardBits) <= int_i;
                if ((compare_o /= 32ux"0") and (count_o = compare_o)) then
                    timerInt_o <= INTERRUPT_ASSERT;
                end if;
                if (we_i = ENABLE) then
                    case (waddr_i) is
                        when COUNT_PROCESSOR =>
                            count_o <= data_i;

                        when COMPARE_PROCESSOR =>
                            compare_o <= data_i;
                            timerInt_o <= INTERRUPT_NOT_ASSERT;

                        when STATUS_PROCESSOR =>
                            status_o <= data_i;

                        when EPC_PROCESSOR =>
                            epc_o <= data_i;

                        when CAUSE_PROCESSOR =>
                            cause_o(CauseIpSoftBits) <= data_i(CauseIpSoftBits);
                            cause_o(CAUSE_IV_BIT) <= data_i(CAUSE_IV_BIT);
                            cause_o(CAUSE_WP_BIT) <= data_i(CAUSE_WP_BIT);

                        when others =>
                            null;
                    end case;
                end if;

                if ((exceptCause_i /= NO_CAUSE) and (exceptCause_i /= ERET_CAUSE)) then
                    status_o(STATUS_EXL_BIT) <= '1';
                    if (isIndelaySlot_i = IN_DELAY_SLOT_FLAG) then
                        epc_o <= currentInstAddr_i - 4;
                        cause_o(CAUSE_BD_BIT) <= '1';
                    else
                        epc_o <= currentInstAddr_i;
                        cause_o(CAUSE_BD_BIT) <= '0';
                    end if;
                    cause_o(CauseExcCodeBits) <= exceptCause_i;
                end if;
                if (exceptCause_i = ERET_CAUSE) then
                    status_o(STATUS_EXL_BIT) <= '0';
                end if;
            end if;
        end if;
    end process;

    process (all)
    begin
        if (rst = RST_ENABLE) then
            data_o <= (others => '0');
        else
            case (raddr_i) is
                when COUNT_PROCESSOR =>
                    data_o <= count_o;

                when COMPARE_PROCESSOR =>
                    data_o <= compare_o;

                when STATUS_PROCESSOR =>
                    data_o <= status_o;

                when CAUSE_PROCESSOR =>
                    data_o <= cause_o;

                when EPC_PROCESSOR =>
                    data_o <= epc_o;

                when PRID_PROCESSOR =>
                    data_o <= prid_o;

                when CONFIG_PROCESSOR =>
                    data_o <= config_o;

                when others =>
                    null;
            end case;
        end if;
    end process;
end bhv;
