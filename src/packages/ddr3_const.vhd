library ieee;
use ieee.std_logic_1164.all;

package ddr3_const is

    constant BURST_LEN_WIDTH: integer := 3;
    constant BURST_LEN: integer := 2 ** BURST_LEN_WIDTH;

    subtype BurstLenWidth is integer range BURST_LEN_WIDTH - 1 downto 0;
    type BurstDataType is array(0 to (BURST_LEN - 1)) of std_logic_vector(31 downto 0);

end ddr3_const;
