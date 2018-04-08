library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package cache_const is
    constant CACHE_OFFSET_BITS: integer := 4; -- DDR3 burst = 16 * 8 = 128 bits = 16 bytes
    constant CACHE_GROUP_BITS: integer := 10;
    constant CACHE_WAY_BITS: integer := 2;

    constant CACHE_WAY_NUM: integer := 2 ** CACHE_WAY_BITS;
    constant CACHE_GROUP_NUM: integer := 2 ** CACHE_GROUP_BITS;
    constant CACHE_LINE_SIZE: integer := 2 ** (CACHE_OFFSET_BITS - 2);

    subtype CacheOffsetWidth is integer range CACHE_OFFSET_BITS - 1 downto 2;
    subtype CacheGroupWidth is integer range CACHE_OFFSET_BITS + CACHE_GROUP_BITS - 1 downto CACHE_OFFSET_BITS;
    subtype CacheTagWidth is integer range 31 downto CACHE_OFFSET_BITS + CACHE_GROUP_BITS;

    type CacheLineDataType is array(0 to CACHE_LINE_SIZE - 1) of std_logic_vector(DataWidth);
    type CacheLineType is record
        valid: std_logic;
        tag: std_logic_vector(CacheTagWidth);
        data: CacheLineDataType;
    end record;
    type CacheGroupType is array(0 to CACHE_WAY_NUM - 1) of CacheLineType;
    type CacheArrType is array(0 to CACHE_GROUP_NUM - 1) of CacheGroupType;
end cache_const;
