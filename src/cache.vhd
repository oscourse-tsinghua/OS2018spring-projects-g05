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
        enable_i, write_i, caching_i: in std_logic;
        busy_o: out std_logic;
        dataSave_i: in std_logic_vector(DataWidth);
        dataLoad_o: out std_logic_vector(DataWidth);
        addr_i: in std_logic_vector(AddrWidth);

        -- To device
        enable_o: out std_logic;
        busy_i: in std_logic;
        dataLoad_i: in std_logic_vector(DataWidth)
    );
end cache;

architecture bhv of cache is
    signal cacheArr: CacheArrType;

    signal tagPart: std_logic_vector(CacheTagWidth);
    signal groupPart: std_logic_vector(CacheGroupWidth);
    signal offsetPart: std_logic_vector(CacheOffsetWidth);

    signal gid, lid, oid: integer;
    signal lidValid: std_logic;

    signal useDev: std_logic;

    signal random: std_logic_vector(CACHE_WAY_BITS - 1 downto 0);
begin
    tagPart <= addr_i(CacheTagWidth);
    groupPart <= addr_i(CacheGroupWidth);
    offsetPart <= addr_i(CacheOffsetWidth);

    gid <= conv_integer(groupPart);
    oid <= conv_integer(offsetPart);
    process(enable_i, cacheArr, gid, oid, tagPart) begin -- Here's issue #6 again!
        lidValid <= NO;
        lid <= 0;
        if (enable_i = ENABLE) then -- Otherwise gid/oid may be out of range in simulation
            for i in 0 to CACHE_WAY_NUM - 1 loop
                if (cacheArr(gid)(i).valid = YES and cacheArr(gid)(i).tag = tagPart) then
                    lid <= i;
                    lidValid <= YES;
                end if;
            end loop;
        end if;
    end process;

    process (enable_i, caching_i, write_i, lidValid, cacheArr, gid, lid, oid) begin
        useDev <= NO;
        if (enable_i = ENABLE) then
            useDev <= YES;
            if (
                caching_i = YES and
                write_i = NO and -- Always write through
                lidValid = YES and -- Cache line hit
                cacheArr(gid)(lid).data(oid).valid = YES -- Cache cell hit
            ) then
                useDev <= NO;
            end if;
        end if;
    end process;

    process (enable_i, useDev, busy_i, dataLoad_i, cacheArr, gid, lid, oid) begin
        enable_o <= DISABLE;
        busy_o <= PIPELINE_NONSTOP;
        dataLoad_o <= 32ux"0";
        if (enable_i = ENABLE) then
            if (useDev = YES) then
                enable_o <= ENABLE;
                busy_o <= busy_i;
                dataLoad_o <= dataLoad_i;
            else
                enable_o <= DISABLE;
                busy_o <= PIPELINE_NONSTOP;
                dataLoad_o <= cacheArr(gid)(lid).data(oid).data;
            end if;
        end if;
    end process;

    process (clk)
        variable newCached: std_logic_vector(DataWidth);
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
                if (enable_i = ENABLE and (
                    write_i = YES or -- Writing
                    (useDev = YES and busy_i = PIPELINE_NONSTOP) -- Read finished
                )) then
                    newCached := (others => 'X');
                    if (write_i = YES) then
                        newCached := dataSave_i;
                    else
                        newCached := dataLoad_i;
                    end if;

                    if (lidValid = YES) then
                        cacheArr(gid)(lid).data(oid).valid <= YES;
                        cacheArr(gid)(lid).data(oid).data <= newCached;
                    else
                        cacheArr(gid)(conv_integer(random)).valid <= YES;
                        cacheArr(gid)(conv_integer(random)).tag <= tagPart;
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

