library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
-- NOTE: std_logic_unsigned cannot be used at the same time with std_logic_signed
--       Use numeric_std if signed number is needed (different API)
use work.global_const.all;
use work.cache_const.all;

entity cache is
    port (
        clk, rst: in std_logic;

        -- To CPU
        qryEnable_i, qryWrite_i, caching_i: in std_logic;
        qryBusy_o: out std_logic;
        qryDataLoad_o: out std_logic_vector(DataWidth);
        qryAddr_i: in std_logic_vector(AddrWidth);

        -- To device
        devEnable_o: out std_logic;
        devBusy_i: in std_logic;
        devDataLoad_i: in std_logic_vector(DataWidth);

        -- Update (From devctrl, because there are 2 caches)
        updEnable_i, updWrite_i, updBusy_i: in std_logic;
        updDataSave_i, updDataLoad_i: in std_logic_vector(DataWidth);
        updAddr_i: in std_logic_vector(AddrWidth);
        updByteSelect_i: in std_logic_vector(3 downto 0)
    );
end cache;

architecture bhv of cache is
    signal cacheArr: CacheArrType;

    procedure locate(
        signal addr_i: in std_logic_vector(AddrWidth);
        variable lidValid_o: out std_logic;
        variable gid_o, lid_o, oid_o: out integer
    ) is
        variable tagPart: std_logic_vector(CacheTagWidth);
        variable groupPart: std_logic_vector(CacheGroupWidth);
        variable offsetPart: std_logic_vector(CacheOffsetWidth);
        variable lidValid: std_logic;
        variable gid, lid, oid: integer;
    begin
        tagPart := addr_i(CacheTagWidth);
        groupPart := addr_i(CacheGroupWidth);
        offsetPart := addr_i(CacheOffsetWidth);

        gid := conv_integer(groupPart);
        oid := conv_integer(offsetPart);
        lidValid := NO;
        lid := 0;
        for i in 0 to CACHE_WAY_NUM - 1 loop
            if (cacheArr(gid)(i).valid = YES and cacheArr(gid)(i).tag = tagPart) then
                lid := i;
                lidValid := YES;
            end if;
        end loop;

        lidValid_o := lidValid;
        gid_o := gid;
        lid_o := lid;
        oid_o := oid;
    end locate;

    signal updBitSelect: std_logic_vector(DataWidth);
    signal random: std_logic_vector(CACHE_WAY_BITS - 1 downto 0);

begin

    process (cacheArr, caching_i, qryEnable_i, qryWrite_i, qryAddr_i, devBusy_i, devDataLoad_i) -- Issue #6 agian
        variable lidValid: std_logic;
        variable gid, lid, oid: integer;
    begin
        devEnable_o <= DISABLE;
        qryBusy_o <= PIPELINE_NONSTOP;
        qryDataLoad_o <= 32ux"0";

        if (qryEnable_i = ENABLE) then
            devEnable_o <= ENABLE;
            qryBusy_o <= devBusy_i;
            qryDataLoad_o <= devDataLoad_i;

            locate(
                addr_i => qryAddr_i,
                lidValid_o => lidValid,
                gid_o => gid,
                lid_o => lid,
                oid_o => oid
            );
            if (
                caching_i = YES and
                qryWrite_i = NO and -- Always write through
                lidValid = YES and -- Cache line hit
                cacheArr(gid)(lid).data(oid).valid = YES -- Cache cell hit
            ) then
                devEnable_o <= DISABLE;
                qryBusy_o <= PIPELINE_NONSTOP;
                qryDataLoad_o <= cacheArr(gid)(lid).data(oid).data;
            end if;
        end if;
    end process;

    updBitSelect <= (
        31 downto 24 => updByteSelect_i(3),
        23 downto 16 => updByteSelect_i(2),
        15 downto 8 => updByteSelect_i(1),
        7 downto 0 => updByteSelect_i(0)
    );

    process (clk)
        variable newCached: std_logic_vector(DataWidth);
        variable lidValid: std_logic;
        variable gid, lid, oid: integer;
    begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                for i in 0 to CACHE_GROUP_NUM - 1 loop
                    for j in 0 to CACHE_WAY_NUM - 1 loop
                        cacheArr(i)(j).valid <= NO;
                        cacheArr(i)(j).tag <= (others => '0');
                        for k in 0 to CACHE_LINE_SIZE - 1 loop
                            cacheArr(i)(j).data(k).valid <= NO;
                            cacheArr(i)(j).data(k).data <= 32ux"0";
                        end loop;
                    end loop;
                end loop;
                random <= (others => '0');
            else
                if (updEnable_i = ENABLE and updBusy_i = PIPELINE_NONSTOP) then
                    newCached := (others => 'X');
                    if (updWrite_i = YES) then
                        newCached := updDataSave_i;
                    else
                        newCached := updDataLoad_i;
                    end if;

                    locate(
                        addr_i => updAddr_i,
                        lidValid_o => lidValid,
                        gid_o => gid,
                        lid_o => lid,
                        oid_o => oid
                    );
                    if (lidValid = YES) then
                        cacheArr(gid)(lid).data(oid).valid <= YES;
                        cacheArr(gid)(lid).data(oid).data <=
                            (cacheArr(gid)(lid).data(oid).data and not updBitSelect) or
                            (newCached and updBitSelect);
                    else
                        cacheArr(gid)(conv_integer(random)).valid <= YES;
                        cacheArr(gid)(conv_integer(random)).tag <= updAddr_i(CacheTagWidth);
                        for k in 0 to CACHE_LINE_SIZE - 1 loop
                            cacheArr(gid)(conv_integer(random)).data(k).valid <= NO;
                        end loop;
                        cacheArr(gid)(conv_integer(random)).data(oid).valid <= YES;
                        cacheArr(gid)(conv_integer(random)).data(oid).data <= newCached;
                    end if;
                end if;
                random <= random + 1;
            end if;
        end if;
    end process;
end bhv;

