library ieee;
use ieee.std_logic_1164.all;

package ddr3_const is

    constant BURST_LEN: integer := 8;
    constant BURST_LEN_WIDTH: integer := 3;

    subtype BurstLenWidth is integer range BURST_LEN_WIDTH - 1 downto 0;
    type BurstDataType is array(0 to (BURST_LEN - 1)) of std_logic_vector(31 downto 0);

    constant OFFSET_WIDTH: integer := BURST_LEN_WIDTH;
    constant INDEX_WIDTH: integer := 4;
    constant TAG_WIDTH: integer := 25 - OFFSET_WIDTH - INDEX_WIDTH;

    constant INDEX_NUM: integer := 16;

    type CacheItemType is record
        present: std_logic;
        tag: std_logic_vector(TAG_WIDTH - 1 downto 0);
        data: BurstDataType;
    end record CacheItemType;

    type CacheTableType is array(0 to INDEX_NUM - 1) of CacheItemType;

end ddr3_const;
