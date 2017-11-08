library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
-- NOTE: std_logic_unsigned cannot be used at the same time with std_logic_unsigned
--       Use numeric_std if signed number is needed (different API)
use work.global_const.all;
use work.except_const.all;
use work.cp0_const.all;
use work.mmu_const.all;

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

        data_o: out std_logic_vector(DataWidth);
        timerInt_o: out std_logic;

        -- output signals for CP0 processor
        -- refers to page 295 in that book still
        status_o: out std_logic_vector(DataWidth);
        cause_o: out std_logic_vector(DataWidth);
        epc_o: out std_logic_vector(DataWidth);

        -- for exception --
        exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
        currentInstAddr_i: in std_logic_vector(AddrWidth);
        isIndelaySlot_i: in std_logic;

        -- To MMU
        isKernalMode_o: out std_logic;
        entryIndex_o: out std_logic_vector(TLBIndexWidth);
        entryWrite_o: out std_logic;
        entry_o: out TLBEntry
    );
end cp0_reg;

architecture bhv of cp0_reg is
    type RegArr is array (0 to CP0_MAX_ID) of std_logic_vector(DataWidth);
    signal regArr: RegArr;
begin
    status_o <= regArr(STATUS_REG);
    cause_o <= regArr(CAUSE_REG);
    epc_o <= regArr(EPC_REG);

    data_o <= regArr(conv_integer(raddr_i));

    process(clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                -- Please refer to MIPS Vol3 for reset value
                -- Undefined reset value are reset to 0 here for robustness
                regArr(INDEX_REG) <= (others => '0');
                regArr(RANDOM_REG) <= conv_std_logic_vector(TLB_ENTRY_NUM - 1);
                regArr(ENTRY_LO1_REG) <= (others => '0');
                regArr(ENTRY_LO2_REG) <= (others => '0');
                regArr(BAD_V_ADDR_REG) <= (others => '0');
                regArr(COUNT_REG) <= (others => '0');
                regArr(ENTRY_HI_REG) <= (others => '0');
                regArr(COMPARE_REG) <= (others => '0');
                regArr(STATUS_REG) <= (28 => '1', others => '0'); -- We don't use BEV bit. TODO: ERL bit?
                regArr(CAUSE_REG) <= (others => '0');
                regArr(EPC_REG) <= (others => '0');
                regArr(PRID_REG) <= (22 => '1', 19 => '1', 18 => '1', 8 => '1', 1 => '1', others => '0');
                regArr(CONFIG_REG) <= (15 => '1', others => '0');

                timerInt_o <= INTERRUPT_NOT_ASSERT;
            else
                regArr(COUNT_REG) <= regArr(COUNT_REG) + 1;
                regArr(CAUSE_REG)(CauseIpHardBits) <= int_i;
                if ((regArr(COMPARE_REG) /= 32ux"0") and (regArr(COUNT_REG) = regArr(COMPARE_REG))) then
                    timerInt_o <= INTERRUPT_ASSERT;
                end if;

                if (we_i = ENABLE) then
                    case (waddr_i) is
                        when COMPARE_REG =>
                            regArr(COMPARE_REG) <= data_i;
                            timerInt_o <= INTERRUPT_NOT_ASSERT;
                        when CAUSE_REG =>
                            regArr(CAUSE_REG)(CauseIpSoftBits) <= data_i(CauseIpSoftBits);
                            regArr(CAUSE_REG)(CAUSE_IV_BIT) <= data_i(CAUSE_IV_BIT);
                            regArr(CAUSE_REG)(CAUSE_WP_BIT) <= data_i(CAUSE_WP_BIT);
                        when others =>
                            regArr(conv_integer(waddr_i)) <= data_i;
                    end case;
                end if;

                if ((exceptCause_i /= NO_CAUSE) and (exceptCause_i /= ERET_CAUSE)) then
                    regArr(STATUS_REG)(STATUS_EXL_BIT) <= '1';
                    if (isIndelaySlot_i = IN_DELAY_SLOT_FLAG) then
                        regArr(EPC_REG) <= currentInstAddr_i - 4;
                        regArr(CAUSE_REG)(CAUSE_BD_BIT) <= '1';
                    else
                        regArr(EPC_REG) <= currentInstAddr_i;
                        regArr(CAUSE_REG)(CAUSE_BD_BIT) <= '0';
                    end if;
                    regArr(CAUSE_REG)(CauseExcCodeBits) <= exceptCause_i;
                end if;
                if (exceptCause_i = ERET_CAUSE) then
                    regArr(STATUS_REG)(STATUS_EXL_BIT) <= '0';
                end if;
            end if;
        end if;
    end process;
end bhv;

