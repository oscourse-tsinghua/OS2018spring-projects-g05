library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package mem_const is
    type MemType is (
        INVALID, 
        MEM_LB, MEM_LBU, MEM_LH, MEM_LHU, MEM_LW,
        MEM_LWL, MEM_LWR, MEM_SB, MEM_SH, MEM_SW, MEM_SWL, MEM_SWR,
        MEM_LL, MEM_SC
    );
    type FPMemType is(
    	INVALID,
        FMEM_LW, FMEM_SW
   	);
end mem_const;
