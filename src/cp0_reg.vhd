library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
-- NOTE: std_logic_unsigned cannot be used at the same time with std_logic_unsigned
--       Use numeric_std if signed number is needed (different API)
use work.cp0_const.all;
use work.global_const.all;

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
        data_o: out std_logic_vector(DataWidth);
        count_o: out std_logic_vector(DataWidth);
        compare_o: out std_logic_vector(DataWidth);
        status_o: out std_logic_vector(DataWidth);
        cause_o: out std_logic_vector(DataWidth);
        epc_o: out std_logic_vector(DataWidth);
        config_o: out std_logic_vector(DataWidth);
        prid_o: out std_logic_vector(DataWidth);
        timer_int_o: out std_logic
    );
end cp0_reg;

architecture bhv of cp0_reg is
begin
    process(clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                count_o <= CP0_ZERO_WORD;
                compare_o <= CP0_ZERO_WORD;
                status_o <= "00010000000000000000000000000000";
                cause_o <= CP0_ZERO_WORD;
                epc_o <= CP0_ZERO_WORD;
                config_o <= "00000000000000001000000000000000";
                prid_o <= "00000000010011000000000100000010";
                timer_int_o <= INTERRUPT_NOT_ASSERT;
            else
                count_o <= count_o + 1;
                cause_o(ExternalInterruptAssertIdx) <= int_i;
                if (compare_o /= CP0_ZERO_WORD and count_o = compare_o)
                    timer_int_o <= INTERRUPT_ASSERT;
                end if;
                if (we_i = ENABLE)
                    case (waddr_i) is
                        -- count processor --
                        when COUNT_PROCESSOR =>
                            count_o <= data_i;

                        -- compare proessor --                        
                        when COMPARE_PROCESSOR =>
                            compare_o <= data_i;
                            timer_int_o <= INTERRUPT_NOT_ASSERT;

                        -- status processor --
                        when STATUS_PROCESSOR =>
                            status_o <= data_i;

                        -- epc processor --
                        when EPC_PROCESSOR =>
                            epc_o <= data_i;

                        -- cause processor --
                        when CAUSE_PROCESSOR =>
                            cause_o(CP0IP10Idx) <= data_i(CP0IP10Idx);
                            cause_o(CP0IVIdx) <= data_i(CP0IVIdx);
                            cause_o(CP0WPIdx) <= data_i(CP0WPIdx);

                        -- others --
                        when others =>
                            null;
                    end case;
            end if;
        end if;
    end process;
    
    process (all)
    begin
        if (rst = RST_ENABLE) then
            data_o <= CP0_ZERO_WORD;
        else
            case (raddr_i) is
                -- count processor --
                when COUNT_PROCESSOR =>
                    data_o <= count_o;

                -- compare processor --
                when COMPARE_PROCESSOR =>
                    data_o <= compare_o;

                -- status processor --
                when STATUS_PROCESSOR =>
                    data_o <= status_o;

                -- cause processor --
                when CAUSE_PROCESSOR =>
                    data_o <= cause_o;

                -- epc processor --
                when EPC_PROCESSOR =>
                    data_o <= epc_o;

                -- prid processor --
                when PRID_PROCESSOR =>
                    data_o <= prid_o;

                when CONFIG_PROCESSOR =>
                    data_o <= config_o;

                when others =>
                    null;
        end if;
    end process;
end bhv;