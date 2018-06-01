library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
-- NOTE: std_logic_unsigned cannot be used at the same time with std_logic_signed
--       Use numeric_std if signed number is needed (different API)
use work.global_const.all;
use work.except_const.all;
use work.mmu_const.all;
use work.cp0_const.all;

entity mmu is
    port (
        rst, clk: in std_logic;

        -- Translate the address
        enable_i: in std_logic;
        isKernelMode_i: in std_logic;
        isLoad_i: in std_logic; -- This address is used for loading rather than storing
        addr_i: in std_logic_vector(AddrWidth);
        addr_o: out std_logic_vector(AddrWidth);
        enable_o: out std_logic;
        exceptCause_o: out std_logic_vector(ExceptionCauseWidth);

        -- Manage TLB entry
        index_i: in std_logic_vector(TLBIndexWidth);
        index_o: out std_logic_vector(TLBIndexWidth);
        indexValid_o: out std_logic;
        entryWrite_i: in std_logic;
        entryFlush_i: in std_logic;
        entry_i: in TLBEntry;
        entry_o: out TLBEntry;
        pageMask_i: in std_logic_vector(AddrWidth)
    );
end mmu;

architecture bhv of mmu is
    type EntryArr is array (0 to TLB_ENTRY_NUM - 1) of TLBEntry;
    signal entries: EntryArr;
    signal pageMask: std_logic_vector(4 downto 0);
begin
    -- Translation
    -- We can't use 'Z' inside chip, so here we are using sequential look-up
    process (all)
        variable targetLo: std_logic_vector(DataWidth);
        variable addrExcept, tlbExcept: boolean;
    begin
        exceptCause_o <= NO_CAUSE;
        enable_o <= enable_i;
        addrExcept := false;
        tlbExcept := true;
        addr_o <= (others => '0');
        if (isKernelMode_i = NO and addr_i(31 downto 28) >= 4x"8") then
            -- kseg0, kseg1, kseg2
            addrExcept := true;
        end if;

        if (addr_i(31 downto 28) >= 4x"8" and addr_i(31 downto 28) < 4x"a") then
            -- kseg0 (unmapped)
            addr_o <= addr_i - 32x"80000000";
            tlbExcept := false;
        elsif (addr_i(31 downto 28) >= 4x"a" and addr_i(31 downto 28) < 4x"c") then
            -- kseg1 (unmapped)
            addr_o <= addr_i - 32x"a0000000";
            tlbExcept := false;
        else
            -- kuseg, kseg2 (mapped)
            for i in 0 to TLB_ENTRY_NUM - 1 loop
                if ((entries(i).hi(EntryHiVPN2Bits) or pageMask_i(EntryHiVPN2Bits)) = (addr_i(EntryHiVPN2Bits) or pageMask_i(EntryHiVPN2Bits))) then
                    -- VPN match
                    if (
                        (entries(i).lo0(ENTRY_LO_G_BIT) and entries(i).lo1(ENTRY_LO_G_BIT)) = '1' or -- global
                        entries(i).hi(EntryHiASIDBits) = entry_i.hi(EntryHiASIDBits) -- ASID match
                    ) then
                        if (addr_i(conv_integer(pageMask)) = '0') then
                            targetLo := entries(i).lo0;
                        else
                            targetLo := entries(i).lo1;
                        end if;
                        if (targetLo(ENTRY_LO_V_BIT) = '1') then
                            -- Valid
                            if (targetLo(ENTRY_LO_D_BIT) = '1' or isLoad_i = '1') then
                                -- Dirty or being read (Only dirty page can be written)
                                addr_o <= targetLo(25 downto conv_integer(pageMask) - 6) & addr_i(conv_integer(pageMask) - 1 downto 0);
                                tlbExcept := false;
                            end if;
                        end if;
                    end if;
                end if;
            end loop;
        end if;

        if (addrExcept) then
            enable_o <= DISABLE;
            if (isLoad_i = YES) then -- Conditional assignment in sequential code has not been supported in Vivado yet
                exceptCause_o <= ADDR_ERR_LOAD_OR_IF_CAUSE;
            else
                exceptCause_o <= ADDR_ERR_STORE_CAUSE;
            end if;
        end if;

        if (tlbExcept) then
            enable_o <= DISABLE;
            if (isLoad_i = YES) then
                exceptCause_o <= TLB_LOAD_CAUSE;
            else
                exceptCause_o <= TLB_STORE_CAUSE;
            end if;
        end if;
    end process;

    -- Store entry
    process (clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                for i in 0 to TLB_ENTRY_NUM - 1 loop
                    entries(i).hi <= (others => '0');
                    entries(i).lo0 <= (others => '0');
                    entries(i).lo1 <= (others => '0');
                end loop;
                pageMask <= 5ux"c";
            elsif (entryWrite_i = YES) then
                entries(conv_integer(index_i)) <= entry_i;
            elsif (entryFlush_i = YES) then
                for i in 0 to TLB_ENTRY_NUM - 1 loop
                    entries(i).lo0(ENTRY_LO_V_BIT) <= '0';
                    entries(i).lo1(ENTRY_LO_V_BIT) <= '0';
                end loop;
            else
                pageMask <= 5ux"c";
                for i in 28 downto 13 loop
                    if ((pageMask_i(i + 1) = '0') and (pageMask_i(i) = '1')) then
                        pageMask <= conv_std_logic_vector(i, 5);
                    end if;
                end loop;
            end if;
        end if;
    end process;

    -- Probe entry
    -- Here might be some bugs with the synthesisier, which failed to work with `process(all)`
    process (entries, entry_i) begin
        index_o <= 4x"0";
        indexValid_o <= '0';
        for i in 0 to TLB_ENTRY_NUM - 1 loop
            if (entries(i).hi(EntryHiVPN2Bits) = entry_i.hi(EntryHiVPN2Bits)) then
                if (
                    (entries(i).lo0(ENTRY_LO_G_BIT) and entries(i).lo1(ENTRY_LO_G_BIT)) = '1' or -- global
                    entries(i).hi(EntryHiASIDBits) = entry_i.hi(EntryHiASIDBits) -- ASID match
                ) then
                    index_o <= conv_std_logic_vector(i, 4);
                    indexValid_o <= '1';
                end if;
            end if;
        end loop;
    end process;

    entry_o <= entries(conv_integer(index_i));
end bhv;

