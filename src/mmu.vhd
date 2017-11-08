library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
-- NOTE: std_logic_unsigned cannot be used at the same time with std_logic_unsigned
--       Use numeric_std if signed number is needed (different API)
use work.global_const.all;
use work.except_const.all;
use work.mmu_const.all;

entity mmu is
    port (
        -- Translate the address
        isKernalMode_i: in std_logic;
        isLoad_i: in std_logic; -- This address is used for loading rather than storing
        addr_i: in std_logic_vector(AddrWidth);
        addr_o: out std_logic_vector(AddrWidth);
        exceptCause_o: out std_logic_vector(ExceptionCauseWidth);

        -- Update TLB entry
        index_i: in std_logic_vector(TLBIndexWidth);
        entryWrite_i: in std_logic;
        entry_i: in TLBEntry;
    );
end mmu;

architecture bhv of mmu is
    type EntryArr is array (0 to TLB_ENTRY_NUM - 1) of TLBEntry;
    signal entries: EntryArr;
begin
    -- Traslation
    -- We can't use 'Z' inside chip, so here we are using sequential look-up
    process (all)
        variable targetLo: std_logic_vector(DataWidth);
        variable addrExcept, tlbExcept: boolean;
    begin
        addrExcept := false;
        tlbExcept := true;
        if (isKernalMode_i = YES and addr_i(31 downto 28) >= 4x"8") then
            -- kseg0, kseg1, kseg2
            addrExcept := true;
        end if;

        if (addr_i(31 downto 28) >= 4x"8" and addr_i(31 downto 28) < 4x"c") then
            -- kseg0, kseg1 (unmapped)
            addr_o <= addr_i - 32x"80000000";
            tlbExcept := false;
        else
            -- kuseg, kseg2 (mapped)
            for i in 0 to TLB_ENTRY_NUM - 1 loop
                if (entries(i).hi(EntryHiVPN2Bits) = addr_i(EntryHiVPN2Bits)) then
                    -- VPN match
                    if (
                        (entries(i).lo0(ENTRY_LO_G_BIT) and entries(i).lo1(ENTRY_LO_G_BIT)) = '1' or -- global
                        entries(i).hi(EntryHiASIDBits) = addr_i(EntryHiASIDBits) -- ASID match
                    ) then
                        if (addr_i(12) = '0') then
                            targetLo := entries(i).lo0;
                        else
                            targetLo := entries(i).lo1;
                        end if;
                        if (targetLo(ENTRY_LO_V_BIT) = '1') then
                            -- Valid
                            if (targetLo(ENTRY_LO_D_BIT) = '1' or isLoad_i = '1')
                                -- Dirty or being read (Dirty page cannot be written)
                                addr_o <= targetLo(ENTRY_LO_FPN_BITS) & addr_i(11 downto 0);
                                tlbExcept := false;
                            end if;
                        end if;
                    end if;
                end if;
            end loop;
        end if;

        if (addrExcept) then
            if (isLoad_i = YES) then -- Conditional assignment in sequential code has not been supported in Vivado yet
                exceptCause_o <= ADDR_ERR_LOAD_CAUSE;
            else
                exceptCause_o <= ADDR_ERR_STORE_CAUSE;
            end if;
        end if;

        if (tlbExcept) then
            if (isLoad_i = YES) then
                exceptCause_o <= TLB_LOAD_CAUSE;
            else
                exceptCause_o <= TLB_SAVE_CAUSE;
            end if;
        end if;
    end process;

    -- Store entry
    process (clk) begin
        if (rising_edge(clk) and entryWrite_i = YES) then
            entries(conv_integer(index_i)) <= entry_i;
        end if;
    end process;
end bhv;

