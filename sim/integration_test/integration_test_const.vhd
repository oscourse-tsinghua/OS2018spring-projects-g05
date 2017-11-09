library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package integration_test_const is
    constant CLK_PERIOD: time := 20 ns;
    constant JUDGE_CLK_PERIOD: time := 0.6 us;
    constant INST_ENTRANCE_ADDR: std_logic_vector(AddrWidth) := 32ux"80000000";
    subtype RamAddrWidth is integer range 17 downto 0;
    subtype RamAddrSliceWidth is integer range 19 downto 2;
end integration_test_const;