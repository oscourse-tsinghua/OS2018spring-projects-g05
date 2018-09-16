library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.global_const.all;
use work.bus_const.all;

entity cache is
    generic (
        enableCache: std_logic
    );
    port (
        clk, rst: in std_logic;
        vAddr_i: in std_logic_vector(AddrWidth);

        -- From / to CPU
        req_i: in BusC2D;
        res_o: out BusD2C;
        sync_i: in std_logic_vector(2 downto 0);

        -- From / to devices
        req_o: out BusC2D;
        res_i: in BusD2C;
        mon_i: in BusC2D;
        llBit_i: in std_logic;
        llLoc_i: in std_logic_vector(AddrWidth)
    );
end cache;

architecture bhv of cache is
    constant OFFSET_WIDTH: integer := 2;
    constant INDEX_WIDTH: integer := 4;
    constant TAG_WIDTH: integer := 32 - OFFSET_WIDTH - INDEX_WIDTH;

    constant INDEX_NUM: integer := 2 ** INDEX_WIDTH;

    type CacheItemType is record
        present: std_logic;
        tag: std_logic_vector(TAG_WIDTH - 1 downto 0);
        data: std_logic_vector(DataWidth);
    end record CacheItemType;

    type CacheTableType is array(0 to INDEX_NUM - 1) of CacheItemType;

    signal table: CacheTableType;
    signal reqTag, monTag: std_logic_vector(TAG_WIDTH - 1 downto 0);
    signal reqIndex, monIndex: integer;
    signal readFromCache, satisfied: std_logic;
begin

    readFromCache <= NO when
                        (vAddr_i(31 downto 28) >= 4x"a" and vAddr_i(31 downto 28) < 4x"c") or
                        sync_i /= "000" or
                        (llBit_i = '1' and llLoc_i = req_i.addr)
                     else
                         enableCache;

    process (all) begin
        reqTag <= (others => 'X');
        reqIndex <= 0; -- Make it not overflow during simulation
        monTag <= (others => 'X');
        monIndex <= 0;
        if (req_i.enable = ENABLE) then
            reqTag <= req_i.addr(31 downto 32 - TAG_WIDTH);
            reqIndex <= conv_integer(req_i.addr(31 - TAG_WIDTH downto 32 - TAG_WIDTH - INDEX_WIDTH));
        end if;
        if (mon_i.enable = ENABLE) then
            monTag <= mon_i.addr(31 downto 32 - TAG_WIDTH);
            monIndex <= conv_integer(mon_i.addr(31 - TAG_WIDTH downto 32 - TAG_WIDTH - INDEX_WIDTH));
        end if;
    end process;

    process (all) begin
        res_o.busy <= PIPELINE_NONSTOP;
        res_o.dataLoad <= (others => 'X');
        req_o.enable <= DISABLE;
        satisfied <= NO;
        if (req_i.enable = ENABLE) then
            if (
                readFromCache = YES and req_i.write = NO and
                table(reqIndex).tag = reqTag and table(reqIndex).present = '1'
            ) then
                res_o.busy <= PIPELINE_NONSTOP;
                res_o.dataLoad <= table(reqIndex).data;
                satisfied <= YES;
            else
                res_o.busy <= res_i.busy;
                res_o.dataLoad <= res_i.dataLoad;
                req_o.enable <= ENABLE;
            end if;
        end if;
    end process;
    req_o.write <= req_i.enable and req_i.write;
    req_o.addr <= req_i.addr;
    req_o.byteSelect <= "1111" when req_i.write = NO else req_i.byteSelect;
    req_o.dataSave <= req_i.dataSave;

    process (clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                table <= (others => (present => '0', tag => (others => '0'), data => 32ux"0"));
            else
                if (mon_i.enable = ENABLE and mon_i.write = YES) then -- Put this before the reading part
                    if (table(monIndex).present = '1' and table(monIndex).tag = monTag) then
                        if (mon_i.byteSelect(0) = '1') then
                            table(monIndex).data(7 downto 0) <= mon_i.dataSave(7 downto 0);
                        end if;
                        if (mon_i.byteSelect(1) = '1') then
                            table(monIndex).data(15 downto 8) <= mon_i.dataSave(15 downto 8);
                        end if;
                        if (mon_i.byteSelect(2) = '1') then
                            table(monIndex).data(23 downto 16) <= mon_i.dataSave(23 downto 16);
                        end if;
                        if (mon_i.byteSelect(3) = '1') then
                            table(monIndex).data(31 downto 24) <= mon_i.dataSave(31 downto 24);
                        end if;
                    end if;
                end if;
                if (
                    req_i.enable = ENABLE and req_i.write = NO and
                    satisfied = NO and res_i.busy = PIPELINE_NONSTOP
                ) then
                    table(reqIndex) <= (present => '1', tag => reqTag, data => res_i.dataLoad);
                end if;
            end if;
        end if;
    end process;

end bhv;

