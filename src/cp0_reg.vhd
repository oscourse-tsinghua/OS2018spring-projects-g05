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
        currentInstAddr_i, currentAccessAddr_i: in std_logic_vector(AddrWidth);
        isIndelaySlot_i: in std_logic;

        isKernelMode_o: out std_logic;

        -- For MMU
        isTlbwi_i: in std_logic;
        isTlbwr_i: in std_logic;
        entryIndex_o: out std_logic_vector(TLBIndexWidth);
        entryWrite_o: out std_logic;
        entry_o: out TLBEntry;

        -- Connect ctrl, for address error after eret instruction
        ctrlBadVAddr_i: in std_logic_vector(AddrWidth);
        ctrlToWriteBadVAddr_i: in std_logic
    );
end cp0_reg;

architecture bhv of cp0_reg is
    type RegArray is array (0 to CP0_MAX_ID) of std_logic_vector(DataWidth);
    signal regArr, curArr: RegArray;
    -- curArr including the data that will be written to regArr in the next period
begin
    status_o <= curArr(STATUS_REG);
    cause_o <= curArr(CAUSE_REG);
    epc_o <= curArr(EPC_REG);

    data_o <= curArr(conv_integer(raddr_i));

    timerInt_o <= INTERRUPT_ASSERT when
                  curArr(COMPARE_REG) /= 32ux"0" and curArr(COMPARE_REG) = curArr(COUNT_REG) else
                  INTERRUPT_NOT_ASSERT;

    isKernelMode_o <= curArr(STATUS_REG)(STATUS_ERL_BIT) or
                      curArr(STATUS_REG)(STATUS_EXL_BIT) or
                      not curArr(STATUS_REG)(STATUS_UM_BIT);

    entryIndex_o <= curArr(RANDOM_REG)(TLBIndexWidth) when isTlbwr_i = '1' else curArr(INDEX_REG)(TLBIndexWidth);

    entryWrite_o <= isTlbwi_i or isTlbwr_i;

    entry_o.hi <= curArr(ENTRY_HI_REG);
    entry_o.lo0 <= curArr(ENTRY_LO0_REG);
    entry_o.lo1 <= curArr(ENTRY_LO1_REG);

    process (all) begin
        for i in 0 to CP0_MAX_ID loop
            curArr(i) <= regArr(i);
        end loop;
        if (rst = RST_DISABLE and we_i = ENABLE) then
            case (conv_integer(waddr_i)) is
                when COMPARE_REG =>
                    curArr(COMPARE_REG) <= data_i;
                when CAUSE_REG =>
                    curArr(CAUSE_REG)(CauseIpSoftBits) <= data_i(CauseIpSoftBits);
                    curArr(CAUSE_REG)(CAUSE_IV_BIT) <= data_i(CAUSE_IV_BIT);
                    curArr(CAUSE_REG)(CAUSE_WP_BIT) <= data_i(CAUSE_WP_BIT);
                when others =>
                    curArr(conv_integer(waddr_i)) <= data_i;
            end case;
        end if;
    end process;

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
            else
                regArr(CAUSE_REG)(CauseIpHardBits) <= int_i;

                regArr(COUNT_REG) <= regArr(COUNT_REG) + 1;
                -- The exception handler will reset COUNT register

                if (regArr(RANDOM_REG) = regArr(WIRED_REG)) then
                    regArr(RANDOM_REG) <= conv_std_logic_vector(TLB_ENTRY_NUM - 1, 32);
                else
                    regArr(RANDOM_REG) <= regArr(RANDOM_REG) - 1;
                end if;

                if (we_i = ENABLE) then
                    regArr(conv_integer(waddr_i)) <= curArr(conv_integer(waddr_i));
                    -- We only assign the `waddr_i`-th register, in order not to interfere the counters above
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
                case (exceptCause_i) is
                    when ERET_CAUSE =>
                        regArr(STATUS_REG)(STATUS_EXL_BIT) <= '0';
                    when TLB_LOAD_CAUSE|TLB_STORE_CAUSE|ADDR_ERR_LOAD_OR_IF_CAUSE|ADDR_ERR_STORE_CAUSE =>
                        regArr(BAD_V_ADDR_REG) <= currentAccessAddr_i;
                        regArr(ENTRY_HI_REG)(EntryHiVPN2Bits) <= currentAccessAddr_i(EntryHiVPN2Bits);
                    when others =>
                        null;
                end case;
                if (ctrlToWriteBadVAddr_i = YES) then
                    regArr(BAD_V_ADDR_REG) <= ctrlBadVAddr_i;
                    regArr(STATUS_REG)(STATUS_EXL_BIT) <= '1';
                    if (isIndelaySlot_i = IN_DELAY_SLOT_FLAG) then
                        regArr(EPC_REG) <= currentInstAddr_i - 4;
                        regArr(CAUSE_REG)(CAUSE_BD_BIT) <= '1';
                    else
                        regArr(EPC_REG) <= currentInstAddr_i;
                        regArr(CAUSE_REG)(CAUSE_BD_BIT) <= '0';
                    end if;
                    regArr(CAUSE_REG)(CauseExcCodeBits) <= ADDR_ERR_LOAD_OR_IF_CAUSE;                    
                end if;
            end if;
        end if;
    end process;
end bhv;

