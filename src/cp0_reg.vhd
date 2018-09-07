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
    generic (
        extraReg: boolean;
        holdFirstEpc: boolean;
        cpuId: std_logic_vector(9 downto 0)
    );
    port (
        rst, clk: in std_logic;

        we_i: in std_logic;
        waddr_i: in std_logic_vector(CP0RegAddrWidth);
        raddr_i: in std_logic_vector(CP0RegAddrWidth);
        wsel_i: in std_logic_vector(SelWidth);
        rsel_i: in std_logic_vector(SelWidth);
        data_i: in std_logic_vector(DataWidth);
        int_i: in std_logic_vector(IntWidth);
        data_o: out std_logic_vector(DataWidth);
        dataValid_o: out std_logic;
        timerInt_o: out std_logic;
        status_o: out std_logic_vector(DataWidth);
        cause_o: out std_logic_vector(DataWidth);
        epc_o: out std_logic_vector(DataWidth);

        -- for exception --
        -- These run in MEM stage
        valid_i: in std_logic;
        exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
        currentInstAddr_i, currentAccessAddr_i: in std_logic_vector(AddrWidth);
        memDataWrite_i: in std_logic;
        isIndelaySlot_i: in std_logic;
        exceptCause_o: out std_logic_vector(ExceptionCauseWidth);
        isKernelMode_o: out std_logic;
        tlbRefill_i: in std_logic;
        tlbRefill_o: out std_logic;

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
        cp0EBaseAddr_o: out std_logic_vector(DataWidth);
        depc_o: out std_logic_vector(AddrWidth)
    );
end cp0_reg;

architecture bhv of cp0_reg is
    type RegArray is array (0 to CP0_MAX_ID) of std_logic_vector(DataWidth);
    signal regArr, curArr: RegArray;
    -- curArr including the data that will be written to regArr in the next period
    signal exceptCause: std_logic_vector(ExceptionCauseWidth);
    signal tlbRefill: std_logic;
    signal debugPoint: std_logic;
    signal debugType: std_logic_vector(WatchHiW1CBits);
    signal exceptCauseDelay: std_logic_vector(ExceptionCauseWidth);
    signal currentInstAddrDelay, currentAccessAddrDelay: std_logic_vector(AddrWidth);
    signal isIndelaySlotDelay: std_logic;
begin
    status_o <= curArr(STATUS_REG);
    cause_o <= curArr(CAUSE_REG);
    epc_o <= curArr(EPC_REG);
    depc_o <= curArr(DEPC_REG);

    data_o <= PRID_CONSTANT when (conv_integer(raddr_i) = PRID_OR_EBASE_REG and rsel_i = "000") else
              regArr(PRID_OR_EBASE_REG) when (conv_integer(raddr_i) = PRID_OR_EBASE_REG and rsel_i = "001") else
              regArr(conv_integer(raddr_i)) when (rsel_i = "000" and conv_integer(raddr_i) /= PRID_OR_EBASE_REG) else
              32ux"0";
    dataValid_o <= not we_i;

    EXTRA: if extraReg generate
        isKernelMode_o <= curArr(STATUS_REG)(STATUS_ERL_BIT) or
                          curArr(STATUS_REG)(STATUS_EXL_BIT) or
                          not curArr(STATUS_REG)(STATUS_UM_BIT);

        entryIndex_o <= curArr(RANDOM_REG)(TLBIndexWidth) when cp0Sp_i = CP0SP_TLBWR else curArr(INDEX_REG)(TLBIndexWidth);

        entryFlush_o <= '1' when cp0Sp_i = CP0SP_TLBINVF else '0';
        entryWrite_o <= '1' when cp0Sp_i = CP0SP_TLBWI or cp0Sp_i = CP0SP_TLBWR else '0';

        pageMask_o <= 3ub"0" & curArr(PAGEMASK_REG)(PageMaskMaskBits) & 13ub"0";

        process (all) begin
            -- debug point --
            debugPoint <= NO;
            debugType <= "000";
            if (valid_i = YES) then
                if (
                    regArr(WATCHHI_REG)(WATCHHI_G_BIT) = '1' or
                    regArr(WATCHHI_REG)(WatchHiASIDBits) = regArr(ENTRY_HI_REG)(EntryHiASIDBits)
                ) then
                    if (
                        regArr(WATCHLO_REG)(WatchLoVAddrBits) = currentInstAddr_i(WatchLoVAddrBits) and
                        regArr(WATCHLO_REG)(WATCHLO_I_BIT) = '1'
                    ) then
                        debugPoint <= YES;
                        debugType <= "100";
                    end if;
                    if (regArr(WATCHLO_REG)(WatchLoVAddrBits) = currentAccessAddr_i(WatchLoVAddrBits)) then
                        if (regArr(WATCHLO_REG)(WATCHLO_R_BIT) = '1' and memDataWrite_i = '0') then
                            debugPoint <= YES;
                            debugType <= "010";
                        elsif (regArr(WATCHLO_REG)(WATCHLO_W_BIT) = '1' and memDataWrite_i = '1') then
                            debugPoint <= YES;
                            debugType <= "001";
                        end if;
                    end if;
                end if;
            end if;
        end process;
    end generate EXTRA;

    process (all) begin
        -- Add debug exception into `exceptCause` --
        exceptCause <= exceptCause_i;
        tlbRefill <= tlbRefill_i;
        if (
            extraReg and
            (debugPoint or regArr(CAUSE_REG)(CAUSE_WP_BIT)) = '1' and
            ((regArr(STATUS_REG)(STATUS_ERL_BIT) or regArr(STATUS_REG)(STATUS_EXL_BIT)) = '0')
        ) then
            -- `valid_i` can be 0 here
            -- When debugpoint happened with TLB or address exception, issue debug point first to improve robustness.
            exceptCause <= WATCH_CAUSE;
            tlbRefill <= '0';
        end if;
    end process;
    exceptCause_o <= exceptCause;
    tlbRefill_o <= tlbRefill;

    entry_o.hi <= curArr(ENTRY_HI_REG);
    entry_o.lo0 <= curArr(ENTRY_LO0_REG);
    entry_o.lo1 <= curArr(ENTRY_LO1_REG);

    -- we can still do this because PRID is a preset constant --
    cp0EBaseAddr_o <= curArr(PRID_OR_EBASE_REG);

    process (all) begin
        -- write to cp0 --
        for i in 0 to CP0_MAX_ID loop
            curArr(i) <= regArr(i);
        end loop;
        if (rst = RST_DISABLE and we_i = ENABLE) then
            case (conv_integer(waddr_i)) is
                when CAUSE_REG =>
                    curArr(CAUSE_REG)(CauseIpSoftBits) <= data_i(CauseIpSoftBits);
                    curArr(CAUSE_REG)(CAUSE_IV_BIT) <= data_i(CAUSE_IV_BIT);
                    if (data_i(CAUSE_WP_BIT) = '0') then -- we cannot write 1 when it's 0
                        curArr(CAUSE_REG)(CAUSE_WP_BIT) <= data_i(CAUSE_WP_BIT);
                    end if;
                when PRID_OR_EBASE_REG =>
                    -- PRID is not writable, but ebase is --
                    if (wsel_i = "001") then
                        curArr(PRID_OR_EBASE_REG)(EbaseAddrBits) <= data_i(EbaseAddrBits);
                    end if;
                when others =>
                    curArr(conv_integer(waddr_i)) <= data_i;
            end case;
        end if;
    end process;

    process (clk)
        variable epc: std_logic_vector(AddrWidth);
    begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                -- Please refer to MIPS Vol3 for reset value
                -- Undefined reset value are reset to 0 here for robustness
                regArr <= (others => (others => '0'));
                regArr(STATUS_REG) <= (
                    STATUS_CP0_BIT => '1', STATUS_BEV_BIT => '1', STATUS_ERL_BIT => '1', StatusImBits => '1', others => '0'
                );
                regArr(PRID_OR_EBASE_REG) <= "1000000000000000000000" & cpuId;

                timerInt_o <= INTERRUPT_NOT_ASSERT;
                exceptCauseDelay <= NO_CAUSE;
            else
                exceptCauseDelay <= exceptCause_i;
                currentInstAddrDelay <= currentInstAddr_i;
                currentAccessAddrDelay <= currentAccessAddr_i;
                isIndelaySlotDelay <= isIndelaySlot_i;

                regArr(CAUSE_REG)(CauseIpHardBits) <= int_i;
                regArr(COUNT_REG) <= regArr(COUNT_REG) + 1;

                if (extraReg) then
                    if (regArr(COUNT_REG) + 1 = regArr(COMPARE_REG)) then
                        timerInt_o <= INTERRUPT_ASSERT;
                    end if;

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
                end if;

                if (we_i = ENABLE) then
                    regArr(conv_integer(waddr_i)) <= curArr(conv_integer(waddr_i));
                    -- We only assign the `waddr_i`-th register, in order not to interfere the counters above
                    if (extraReg and conv_integer(waddr_i) = COMPARE_REG) then
                        timerInt_o <= INTERRUPT_NOT_ASSERT; -- Side effect
                    end if;
                end if;

                if (ctrlToWriteBadVAddr_i = YES) then
                    regArr(BAD_V_ADDR_REG) <= ctrlBadVAddr_i;
                    regArr(STATUS_REG)(STATUS_EXL_BIT) <= '1';
                    regArr(CAUSE_REG)(CauseExcCodeBits) <= ADDR_ERR_LOAD_OR_IF_CAUSE;
                    -- Not updating EPC and CAUSE[BD] because EXL = 1
                end if;

                if ((exceptCauseDelay /= NO_CAUSE) and (exceptCauseDelay /= ERET_CAUSE) and (not extraReg or exceptCauseDelay /= DERET_CAUSE)) then
                    if (not holdFirstEpc or curArr(STATUS_REG)(STATUS_EXL_BIT) = '0') then -- See doc of Status[EXL]
                        -- Here we use `curArr` instead of `regArr`, because this should happen at the same time
                        -- as the interrupt enabled
                        if (isInDelaySlotDelay = YES) then
                            epc := currentInstAddrDelay - 4;
                            regArr(CAUSE_REG)(CAUSE_BD_BIT) <= '1';
                        else
                            epc := currentInstAddrDelay;
                            regArr(CAUSE_REG)(CAUSE_BD_BIT) <= '0';
                        end if;
                        if (extraReg and exceptCauseDelay = WATCH_CAUSE) then
                            regArr(DEPC_REG) <= epc;
                        else
                            regArr(EPC_REG) <= epc;
                        end if;
                    end if;
                    regArr(STATUS_REG)(STATUS_EXL_BIT) <= '1';
                    regArr(CAUSE_REG)(CauseExcCodeBits) <= exceptCauseDelay;
                end if;
                if (extraReg) then
                    if (debugPoint = YES) then
                        regArr(WATCHHI_REG)(WatchHiW1CBits) <= debugType;
                        if ((regArr(STATUS_REG)(STATUS_ERL_BIT) or regArr(STATUS_REG)(STATUS_EXL_BIT)) = '1') then
                            -- Then we should pend the watch_cause --
                            regArr(CAUSE_REG)(CAUSE_WP_BIT) <= '1';
                        end if;
                    end if;
                    case (exceptCauseDelay) is
                        when DERET_CAUSE =>
                            if regArr(DEPC_REG)(1 downto 0) = "00" then
                                regArr(STATUS_REG)(STATUS_EXL_BIT) <= '0';
                            end if;
                        -- when WATCH_CAUSE =>
                            -- Software is responsible for clear the WP bit
                        when others =>
                            null;
                    end case;
                end if;
                if (exceptCauseDelay = ERET_CAUSE) then
                    if regArr(EPC_REG)(1 downto 0) = "00" then
                        regArr(STATUS_REG)(STATUS_EXL_BIT) <= '0';
                    end if;
                end if;
                if (
                    exceptCauseDelay = ADDR_ERR_LOAD_OR_IF_CAUSE or
                    exceptCauseDelay = ADDR_ERR_STORE_CAUSE or
                    (extraReg and (
                        exceptCauseDelay = TLB_LOAD_CAUSE or
                        exceptCauseDelay = TLB_STORE_CAUSE or
                        exceptCauseDelay = TLB_MODIFIED_CAUSE
                    ))
                ) then
                    -- If there's an exception of instruction address,
                    -- `currentAccessAddrDelay` should be the address of
                    -- that instruction. See mem.vhd.
                    regArr(BAD_V_ADDR_REG) <= currentAccessAddrDelay;
                    if (extraReg) then
                        regArr(ENTRY_HI_REG)(EntryHiVPN2Bits) <= currentAccessAddrDelay(EntryHiVPN2Bits);
                        regArr(CONTEXT_REG)(ContextBadVPNBits) <= currentAccessAddrDelay(EntryHiVPN2Bits);
                    end if;
                end if;
            end if;
        end if;
    end process;
end bhv;

