library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package integration_test_const is
    constant CLK_PERIOD: time := 20 ns;
    subtype RamAddrWidth is integer range 17 downto 0;
    subtype RamAddrSliceWidth is integer range 19 downto 2;
end integration_test_const;
