library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package integration_test_const is
    constant CLK_PERIOD: time := 20 ns;
    constant INST_ENTRANCE_ADDR: std_logic_vector(AddrWidth) := 32ux"80000000";
end integration_test_const;