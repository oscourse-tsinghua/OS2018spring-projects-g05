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
    generic (
        enableMMU: boolean
    );
    port (
        rst, clk: in std_logic;

        -- Translate the address
        isKernelMode_i: in std_logic;
        enable1_i, enable2_i: in std_logic;
        isLoad1_i, isLoad2_i: in std_logic; -- This address is used for loading rather than storing
        addr1_i, addr2_i: in std_logic_vector(AddrWidth);
        addr1_o, addr2_o: out std_logic_vector(AddrWidth);
        enable1_o, enable2_o: out std_logic;
        exceptCause1_o, exceptCause2_o: out std_logic_vector(ExceptionCauseWidth);
        tlbRefill1_o, tlbRefill2_o: out std_logic;

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

    procedure translate(
        signal enable_i, isLoad_i: in std_logic;
        signal addr_i: in std_logic_vector(AddrWidth);
        signal addr_o: out std_logic_vector(AddrWidth);
        signal enable_o: out std_logic;
        signal exceptCause_o: out std_logic_vector(ExceptionCauseWidth);
        signal tlbRefill_o: out std_logic
    ) is
        variable targetLo: std_logic_vector(DataWidth);
        variable addrExcept, tlbExcept, tlbInvalid, tlbModified: boolean;
    begin
        -- We can't use 'Z' inside chip, so here we are using sequential look-up
        addr_o <= (others => '0');
        enable_o <= enable_i;
        exceptCause_o <= NO_CAUSE;
        tlbRefill_o <= NO;
        addrExcept := false;
        tlbExcept := true;
        tlbInvalid := false;
        tlbModified := false;
        /*
        if (isKernelMode_i = NO and addr_i(31 downto 28) >= 4x"8") then
            -- kseg0, kseg1, kseg2
            addrExcept := true;
        end if;
        */ -- We delay exception handling for 1 period to speed up MEM,
           -- so `isKernelMode` is not readly during the immediately following IF

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
                                addr_o <= ((targetLo(25 downto 6) and ("1" & not pageMask_i(31 downto 13)))
                                          or ("0" & (pageMask_i(31 downto 13) and addr_i(30 downto 12))))
                                          & addr_i(11 downto 0);
                                tlbExcept := false;
                            else
                                tlbModified := true;
                            end if;
                        else
                            tlbInvalid := true;
                        end if;
                    end if;
                end if;
            end loop;
        end if;

        if (enable_i = ENABLE and addrExcept) then
            enable_o <= DISABLE;
            if (isLoad_i = YES) then -- Conditional assignment in sequential code has not been supported in Vivado yet
                exceptCause_o <= ADDR_ERR_LOAD_OR_IF_CAUSE;
            else
                exceptCause_o <= ADDR_ERR_STORE_CAUSE;
            end if;
        end if;

        if (enable_i = ENABLE and tlbExcept) then
            enable_o <= DISABLE;
            if (tlbModified) then
                exceptCause_o <= TLB_MODIFIED_CAUSE;
            else
                if (isLoad_i = YES) then
                    exceptCause_o <= TLB_LOAD_CAUSE;
                else
                    exceptCause_o <= TLB_STORE_CAUSE;
                end if;
                tlbRefill_o <= NO when tlbInvalid else YES;
            end if;
        end if;
    end translate;
begin
    BYPASS: if not enableMMU generate
        addr1_o <= addr1_i;
        enable1_o <= enable1_i;
        exceptCause1_o <= NO_CAUSE;
        tlbRefill1_o <= NO;
        addr2_o <= addr2_i;
        enable2_o <= enable2_i;
        exceptCause2_o <= NO_CAUSE;
        tlbRefill2_o <= NO;
        index_o <= (others => 'X');
        indexValid_o <= 'X';
        entry_o <= (others => (others => 'X'));
    end generate BYPASS;

    FUNCTIONING: if enableMMU generate
        -- Translation
        process (all)
        begin
            translate(
                enable_i => enable1_i,
                isLoad_i => isLoad1_i,
                addr_i => addr1_i,
                addr_o => addr1_o,
                enable_o => enable1_o,
                exceptCause_o => exceptCause1_o,
                tlbRefill_o => tlbRefill1_o
            );
        end process;
        process (all)
        begin
            translate(
                enable_i => enable2_i,
                isLoad_i => isLoad2_i,
                addr_i => addr2_i,
                addr_o => addr2_o,
                enable_o => enable2_o,
                exceptCause_o => exceptCause2_o,
                tlbRefill_o => tlbRefill2_o
            );
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
                else
                    if (entryWrite_i = YES) then
                        entries(conv_integer(index_i)) <= entry_i;
                    end if;
                    if (entryFlush_i = YES) then
                        for i in 0 to TLB_ENTRY_NUM - 1 loop
                            entries(i).lo0(ENTRY_LO_V_BIT) <= '0';
                            entries(i).lo1(ENTRY_LO_V_BIT) <= '0';
                        end loop;
                    end if;
                end if;
            end if;
        end process;

        process (all) begin
            pageMask <= 5ux"c";
            for i in 28 downto 13 loop
                if ((pageMask_i(i + 1) = '0') and (pageMask_i(i) = '1')) then
                    pageMask <= conv_std_logic_vector(i, 5);
                end if;
            end loop;
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
    end generate FUNCTIONING;
end bhv;

