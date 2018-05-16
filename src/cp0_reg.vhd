library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
-- NOTE: std_logic_unsigned cannot be used at the same time with std_logic_signed
--       Use numeric_std if signed number is needed (different API)
use work.global_const.all;
use work.except_const.all;
use work.cp0_const.all;
use work.cp0_config_const.all;
use work.mmu_const.all;

entity cp0_reg is
    port(
        rst, clk: in std_logic;

        we_i: in std_logic;
        waddr_i: in std_logic_vector(CP0RegAddrWidth);
        raddr_i: in std_logic_vector(CP0RegAddrWidth);
        data_i: in std_logic_vector(DataWidth);
        int_i: in std_logic_vector(IntWidth);
        cp0Sel_i: in std_logic_vector(SelWidth);
        data_o: out std_logic_vector(DataWidth);
        timerInt_o: out std_logic;
        status_o: out std_logic_vector(DataWidth);
        cause_o: out std_logic_vector(DataWidth);
        epc_o: out std_logic_vector(DataWidth);

        -- for exception --
        exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
        currentInstAddr_i, currentAccessAddr_i: in std_logic_vector(AddrWidth);
        memDataWrite_i: in std_logic;
        isIndelaySlot_i: in std_logic;
        isKernelMode_o: out std_logic;
        debugPoint_o: out std_logic;

        -- For MMU
        cp0Sp_i: in CP0Special;
        entryIndex_i: in std_logic_vector(TLBIndexWidth);
        entryIndexValid_i: in std_logic;
        entry_i: in TLBEntry;
        entryIndex_o: out std_logic_vector(TLBIndexWidth);
        entryWrite_o: out std_logic;
        entry_o: out TLBEntry;
        entryFlush_o: out std_logic;
        pageMask_o: out std_logic_vector(AddrWidth);

        -- Connect ctrl, for address error after eret instruction
        ctrlBadVAddr_i: in std_logic_vector(DataWidth);
        ctrlToWriteBadVAddr_i: in std_logic;

        -- Connect ctrl, for ExceptNormalBaseAddress modification
        cp0EBaseAddr_o: out std_logic_vector(DataWidth)
    );
end cp0_reg;

architecture bhv of cp0_reg is
    type RegArray is array (0 to CP0_MAX_ID) of std_logic_vector(DataWidth);
    signal regArr, curArr: RegArray;
    -- curArr including the data that will be written to regArr in the next period
    signal timerInt: std_logic;
    signal debugPoint: std_logic;
begin
    status_o <= curArr(STATUS_REG);
    cause_o <= curArr(CAUSE_REG);
    epc_o <= curArr(EPC_REG);

    data_o <= PRID_CONSTANT when (conv_integer(raddr_i) = PRID_OR_EBASE_REG and cp0Sel_i = "000") else
              CONFIG1_CONSTANT when (conv_integer(raddr_i) = CONFIG_REG and cp0Sel_i = "001") else
              curArr(BAD_V_ADDR_REG) when (conv_integer(raddr_i) = BAD_V_ADDR_REG and cp0Sel_i = "000") else -- BADVADDR and config1 is the only two registers we care with sel = 1 --
              curArr(PRID_OR_EBASE_REG) when (conv_integer(raddr_i) = PRID_OR_EBASE_REG and cp0Sel_i = "001") else
              curArr(conv_integer(raddr_i)) when cp0Sel_i = "000" else 
              32ux"0";

    timerInt_o <= timerInt;

    isKernelMode_o <= curArr(STATUS_REG)(STATUS_ERL_BIT) or
                      curArr(STATUS_REG)(STATUS_EXL_BIT) or
                      not curArr(STATUS_REG)(STATUS_UM_BIT);

    entryIndex_o <= curArr(RANDOM_REG)(TLBIndexWidth) when cp0Sp_i = CP0SP_TLBWR else curArr(INDEX_REG)(TLBIndexWidth);

    entryFlush_o <= '1' when cp0Sp_i = CP0SP_TLBINVF else '0';
    entryWrite_o <= '1' when cp0Sp_i = CP0SP_TLBWI or cp0Sp_i = CP0SP_TLBWR else '0';

    entry_o.hi <= curArr(ENTRY_HI_REG);
    entry_o.lo0 <= curArr(ENTRY_LO0_REG);
    entry_o.lo1 <= curArr(ENTRY_LO1_REG);
    -- debugPoint_o <= debugPoint;
    debugPoint_o <= debugPoint;

    -- we can still do this because PRID is a preset constant --
    cp0EBaseAddr_o <= curArr(PRID_OR_EBASE_REG);

    pageMask_o <= 4ub"0" & curArr(PAGEMASK_REG)(PageMaskMaskBits) & 12ub"0";

    process (all) begin
        for i in 0 to CP0_MAX_ID loop
            curArr(i) <= regArr(i);
        end loop;
        if (rst = RST_DISABLE and we_i = ENABLE) then
            case (conv_integer(waddr_i)) is
                when CAUSE_REG =>
                    curArr(CAUSE_REG)(CauseIpSoftBits) <= data_i(CauseIpSoftBits);
                    curArr(CAUSE_REG)(CAUSE_IV_BIT) <= data_i(CAUSE_IV_BIT);
                    curArr(CAUSE_REG)(CAUSE_WP_BIT) <= data_i(CAUSE_WP_BIT);
                when ENTRY_LO0_REG =>
                    curArr(ENTRY_LO0_REG)(EntryLoRWBits) <= data_i(EntryLoRWBits);
                when ENTRY_LO1_REG =>
                    curArr(ENTRY_LO1_REG)(EntryLoRWBits) <= data_i(EntryLoRWBits);
                when CONFIG_REG =>
                    if (cp0Sel_i = 3ub"0") then
                        -- only config0 could be writable --
                        if (data_i(2 downto 1) = "01") then
                            -- only write 2 or 3 should be allowed here --
                            curArr(CONFIG_REG)(Config0K0Bits) <= data_i(Config0K0Bits);
                        end if;
                    end if;
                when PRID_OR_EBASE_REG =>
                    -- PRID is not writable, but ebase is --
                    if (cp0Sel_i = "001") then
                        curArr(PRID_OR_EBASE_REG)(EbaseAddrBits) <= data_i(EbaseAddrBits);
                    end if;
                when CONTEXT_REG =>
                    curArr(CONTEXT_REG)(ContextPTEBaseBits) <= data_i(ContextPTEBaseBits);
                when PAGEMASK_REG =>
                    curArr(PAGEMASK_REG)(PageMaskMaskBits) <= data_i(PageMaskMaskBits);
                when WATCHHI_REG =>
                    curArr(WATCHHI_REG)(WATCHHI_G_BIT) <= data_i(WATCHHI_G_BIT);
                    curArr(WATCHHI_REG)(WatchHiASIDBits) <= data_i(WatchHiASIDBits);
                    curArr(WATCHHI_REG)(WatchHiMaskBits) <= data_i(WatchHiMaskBits);
                    curArr(WATCHHI_REG)(WatchHiW1CBits) <= curArr(WATCHHI_REG)(WatchHiW1CBits) and (not data_i(WatchHiW1CBits));
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
                regArr(STATUS_REG) <= (
                    STATUS_CP0_BIT => '1', STATUS_BEV_BIT => '1', STATUS_ERL_BIT => '1', StatusImBits => '1', others => '0'
                );
                regArr(CONTEXT_REG) <= (others => '0');
                regArr(PAGEMASK_REG) <= (others => '0');
                regArr(CAUSE_REG) <= (others => '0');
                regArr(EPC_REG) <= (others => '0');
                regArr(PRID_OR_EBASE_REG) <= (31 => '1', others => '0');
                regArr(CONFIG_REG) <= (31 => '1', 7 => '1', 1 => '1', 0 => '1', others => '0');
                regArr(WATCHLO_REG) <= (others => '0');
                regArr(WATCHHI_REG) <= (others => '0');

                timerInt <= INTERRUPT_NOT_ASSERT;
                debugPoint <= NO;
            else
                regArr(CAUSE_REG)(CauseIpHardBits) <= int_i;

                if (regArr(COUNT_REG) + 1 = regArr(COMPARE_REG)) then
                    timerInt <= INTERRUPT_ASSERT;
                end if;
                regArr(COUNT_REG) <= regArr(COUNT_REG) + 1;

                if (regArr(RANDOM_REG) = regArr(WIRED_REG)) then
                    regArr(RANDOM_REG) <= conv_std_logic_vector(TLB_ENTRY_NUM - 1, 32);
                else
                    regArr(RANDOM_REG) <= regArr(RANDOM_REG) - 1;
                end if;

                -- According to MIPS Spec. Vol. III, Table 7-1
                -- Software should pad 2 spaces for TLBP -> MFC0 INDEX
                -- And 3 spaces for TLBR -> MFC0 EntryHi (why EntryLo0/1 is not mentioned)
                -- So no forwarding is needed here
                if (cp0Sp_i = CP0SP_TLBP) then
                    regArr(INDEX_REG) <= 32x"0";
                    regArr(INDEX_REG)(31) <= not entryIndexValid_i;
                    regArr(INDEX_REG)(TLBIndexWidth) <= entryIndex_i;
                elsif (cp0Sp_i = CP0SP_TLBR) then
                    regArr(ENTRY_HI_REG) <= entry_i.hi;
                    regArr(ENTRY_LO0_REG) <= entry_i.lo0;
                    regArr(ENTRY_LO1_REG) <= entry_i.lo1;
                    regArr(ENTRY_LO0_REG)(ENTRY_LO_G_BIT) <= entry_i.lo0(ENTRY_LO_G_BIT) and entry_i.lo1(ENTRY_LO_G_BIT);
                    regArr(ENTRY_LO1_REG)(ENTRY_LO_G_BIT) <= entry_i.lo0(ENTRY_LO_G_BIT) and entry_i.lo1(ENTRY_LO_G_BIT);
                end if;

                if (we_i = ENABLE) then
                    regArr(conv_integer(waddr_i)) <= curArr(conv_integer(waddr_i));
                    -- We only assign the `waddr_i`-th register, in order not to interfere the counters above
                    if (conv_integer(waddr_i) = COMPARE_REG) then
                        timerInt <= INTERRUPT_NOT_ASSERT; -- Side effect
                    end if;
                end if;

                debugPoint <= NO;
                if (regArr(WATCHHI_REG)(WATCHHI_G_BIT) = '1' or regArr(WATCHHI_REG)(WatchHiASIDBits) = regArr(ENTRY_HI_REG)(EntryHiASIDBits)) then
                    if ((regArr(WATCHLO_REG)(WatchLoVAddrBits) = currentInstAddr_i(WatchLoVAddrBits)) and regArr(WATCHLO_REG)(WATCHLO_I_BIT) = '1') then
                        debugPoint <= YES;
                        regArr(WATCHHI_REG)(WATCHHI_I_BIT) <= '1';
                    end if;
                    if (regArr(WATCHLO_REG)(WatchLoVAddrBits) = currentAccessAddr_i(WatchLoVAddrBits)) then
                        if (regArr(WATCHLO_REG)(WATCHLO_R_BIT) = '1' and memDataWrite_i = '0') then
                            debugPoint <= YES;
                            regArr(WATCHHI_REG)(WATCHHI_R_BIT) <= '1';
                        elsif (regArr(WATCHLO_REG)(WATCHLO_W_BIT) = '1' and memDataWrite_i = '1') then
                            debugPoint <= YES;
                            regArr(WATCHHI_REG)(WATCHHI_W_BIT) <= '1';
                        end if;
                    end if;
                end if;

                if (((exceptCause_i /= NO_CAUSE) and (exceptCause_i /= ERET_CAUSE)) or (debugPoint = YES)) then
                    regArr(STATUS_REG)(STATUS_EXL_BIT) <= '1';
                    if (isIndelaySlot_i = IN_DELAY_SLOT_FLAG) then
                        regArr(EPC_REG) <= currentInstAddr_i - 4;
                        regArr(CAUSE_REG)(CAUSE_BD_BIT) <= '1';
                    else
                        regArr(EPC_REG) <= currentInstAddr_i;
                        regArr(CAUSE_REG)(CAUSE_BD_BIT) <= '0';
                    end if;
                    regArr(CAUSE_REG)(CauseExcCodeBits) <= exceptCause_i when debugPoint = NO
                                                                         else BREAKPOINT_CAUSE;
                end if;
                case (exceptCause_i) is
                    when ERET_CAUSE =>
                        regArr(STATUS_REG)(STATUS_EXL_BIT) <= '0';
                    when TLB_LOAD_CAUSE|TLB_STORE_CAUSE|ADDR_ERR_LOAD_OR_IF_CAUSE|ADDR_ERR_STORE_CAUSE =>
                        regArr(BAD_V_ADDR_REG) <= currentAccessAddr_i;
                        regArr(ENTRY_HI_REG)(EntryHiVPN2Bits) <= currentAccessAddr_i(EntryHiVPN2Bits);
                        regArr(CONTEXT_REG)(ContextBadVPNBits) <= currentAccessAddr_i(EntryHiVPN2Bits);
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

