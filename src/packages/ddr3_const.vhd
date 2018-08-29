library ieee;
use ieee.std_logic_1164.all;

package ddr3_const is

    -- Used in direct control
    constant BURST_LEN_WIDTH: integer := 3;
    constant BURST_LEN: integer := 2 ** BURST_LEN_WIDTH;

    subtype BurstLenWidth is integer range BURST_LEN_WIDTH - 1 downto 0;
    type BurstDataType is array(0 to (BURST_LEN - 1)) of std_logic_vector(31 downto 0);

    -- Used in NSCSCC interface
    constant DATA_INDEX_WIDTH: integer := 6;
    constant INST_LINE_WIDTH: integer := 4;
    constant DATA_LINE_WIDTH: integer := 4;
    -- dont know if it useful to use different line width for inst and data cache
    constant OFFSET_WIDTH: integer := 2;
    constant TAG_WIDTH: integer := 32 - OFFSET_WIDTH - DATA_INDEX_WIDTH - DATA_LINE_WIDTH;
    subtype RequestIdIndex is integer range (INST_LINE_WIDTH + OFFSET_WIDTH + 3) downto (INST_LINE_WIDTH + OFFSET_WIDTH);

end ddr3_const;
