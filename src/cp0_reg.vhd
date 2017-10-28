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
        waddr_i: in std_logic_vector(CP0ProcessorIdWidth);
        raddr_i: in std_logic_vector(CP0ProcessorIdWidth);
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
    signal pc: std_logic_vector(AddrWidth);
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
            end if;
        end if;
    end process;
end bhv;