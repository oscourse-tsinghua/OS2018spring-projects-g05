library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
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

        isKernelMode_o: out std_logic;

        -- For MMU
        isTlbwi_i: in std_logic;
        isTlbwr_i: in std_logic;
        entryIndex_o: out std_logic_vector(TLBIndexWidth);
        entryWrite_o: out std_logic;
        entry_o: out TLBEntry
    );
end cp0_reg;

architecture bhv of cp0_reg is
    type RegArray is array (0 to CP0_MAX_ID) of std_logic_vector(DataWidth);
    signal regArr: RegArray;
begin
    status_o <= regArr(STATUS_REG);
    cause_o <= regArr(CAUSE_REG);
    epc_o <= regArr(EPC_REG);

    data_o <= regArr(conv_integer(raddr_i));

    isKernelMode_o <= regArr(STATUS_REG)(STATUS_ERL_BIT) or
                      regArr(STATUS_REG)(STATUS_EXL_BIT) or
                      not regArr(STATUS_REG)(STATUS_UM_BIT);

    entryIndex_o <= regArr(RANDOM_REG)(TLBIndexWidth) when isTlbwr_i = '1' else regArr(INDEX_REG)(TLBIndexWidth);

    entryWrite_o <= isTlbwi_i or isTlbwr_i;

    entry_o.hi <= regArr(ENTRY_HI_REG);
    entry_o.lo0 <= regArr(ENTRY_LO0_REG);
    entry_o.lo1 <= regArr(ENTRY_LO1_REG);

    process(clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                -- Please refer to MIPS Vol3 for reset value
                -- Undefined reset value are reset to 0 here for robustness
                regArr(INDEX_REG) <= (others => '0');
                regArr(RANDOM_REG) <= conv_std_logic_vector(TLB_ENTRY_NUM - 1, 32);
                regArr(ENTRY_LO0_REG) <= (others => '0');
                regArr(ENTRY_LO1_REG) <= (others => '0');
                regArr(WIRED_REG) <= (others => '0');
                regArr(BAD_V_ADDR_REG) <= (others => '0');
                regArr(COUNT_REG) <= (others => '0');
                regArr(ENTRY_HI_REG) <= (others => '0');
                regArr(COMPARE_REG) <= (others => '0');
                regArr(STATUS_REG) <= (STATUS_CP0_BIT => '1', STATUS_BEV_BIT => '1', STATUS_ERL_BIT => '1', others => '0');
                regArr(CAUSE_REG) <= (others => '0');
                regArr(EPC_REG) <= (others => '0');
                regArr(PRID_REG) <= (others => '0');
                regArr(CONFIG_REG) <= (others => '0');

                timerInt_o <= INTERRUPT_NOT_ASSERT;
            else
                regArr(CAUSE_REG)(CauseIpHardBits) <= int_i;

                if (regArr(COUNT_REG) + 1 = regArr(COMPARE_REG)) then
                    -- We use `regArr(COUNT_REG) + 1`, so no need to determine if `regArr(COMPARE_REG)` is zero (invalid)
                    timerInt_o <= INTERRUPT_ASSERT;
                else
                    regArr(COUNT_REG) <= regArr(COUNT_REG) + 1;
                end if;

                if (regArr(RANDOM_REG) = regArr(WIRED_REG)) then
                    regArr(RANDOM_REG) <= conv_std_logic_vector(TLB_ENTRY_NUM - 1, 32);
                else
                    regArr(RANDOM_REG) <= regArr(RANDOM_REG) - 1;
                end if;

                if (we_i = ENABLE) then
                    case (conv_integer(waddr_i)) is
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

