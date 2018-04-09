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
        enable_i, write_i: in std_logic;
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
                if (cacheArr(gid)(i).valid(oid) = YES and cacheArr(gid)(i).tag = tagPart) then
                    lid <= i;
                    lidValid <= YES;
                end if;
            end loop;
        end if;
    end process;

    process (all) begin
        enable_o <= DISABLE;
        busy_o <= 'X';
        dataLoad_o <= (others => 'X');
        if (enable_i = ENABLE) then
            enable_o <= ENABLE;
            busy_o <= busy_i;
            dataLoad_o <= dataLoad_i;
            if (
                (addr_i < 32x"A0000000" or addr_i > 32x"C0000000") and -- Cached
                write_i = NO and -- Always write through
                lidValid = YES -- Cache hit
            ) then
                enable_o <= DISABLE;
                busy_o <= PIPELINE_NONSTOP;
                dataLoad_o <= cacheArr(gid)(lid).data(oid);
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
                        cacheArr(i)(j).valid <= (others => NO);
                    end loop;
                end loop;
                random <= (others => '0');
            else
                if (enable_i = ENABLE and (write_i = YES or busy_i = PIPELINE_NONSTOP)) then
                    newCached := (others => 'X');
                    if (write_i = YES) then
                        newCached := dataSave_i;
                    else
                        newCached := dataLoad_i;
                    end if;

                    if (lidValid = YES) then
                        cacheArr(gid)(lid).data(oid) <= newCached;
                    else
                        cacheArr(gid)(conv_integer(random)).valid <= (others => NO);
                        cacheArr(gid)(conv_integer(random)).valid(oid) <= YES;
                        cacheArr(gid)(conv_integer(random)).tag <= tagPart;
                        cacheArr(gid)(conv_integer(random)).data(oid) <= newCached;
                    end if;
                end if;
                random <= random + 1;
            end if;
        end if;
    end process;
end bhv;

