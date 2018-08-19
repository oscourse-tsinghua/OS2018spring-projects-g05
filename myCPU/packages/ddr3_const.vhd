library ieee;
use ieee.std_logic_1164.all;

package ddr3_const is

    constant DATA_INDEX_WIDTH: integer := 6;
	constant INST_LINE_WIDTH: integer := 4;
	constant DATA_LINE_WIDTH: integer := 4;
	-- dont know if it useful to use different line width for inst and data cache
	constant OFFSET_WIDTH: integer := 2;
	constant TAG_WIDTH: integer := 32 - OFFSET_WIDTH - DATA_INDEX_WIDTH - DATA_LINE_WIDTH;
	subtype RequestIdIndex is integer range (INST_LINE_WIDTH + OFFSET_WIDTH + 3) downto (INST_LINE_WIDTH + OFFSET_WIDTH);

end ddr3_const;
