library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package mem_const is
    type MemType is (
        INVALID, MEM_LB, MEM_LBU, MEM_LH, MEM_LHU, MEM_LW,
        MEM_SB, MEM_SH, MEM_SW
    );
end mem_const;
