library ieee;
use ieee.std_logic_1164.all;

package inst_const is
    
    --
    -- Format of instructions, classified into R type, I type and J type
    --
    subtype InstOpIdx      is integer range 31 downto 26;
    subtype InstRsIdx      is integer range 25 downto 21;
    subtype InstRtIdx      is integer range 20 downto 16;
    subtype InstRdIdx      is integer range 15 downto 11;
    subtype InstSaIdx      is integer range 10 downto  6;
    subtype InstFuncIdx    is integer range  5 downto  0;
    subtype InstImmIdx     is integer range 15 downto  0;
    subtype InstAddrIdx    is integer range 25 downto  0;
    
    subtype InstOpWidth    is integer range  5 downto  0;
    subtype InstRsWidth    is integer range  4 downto  0;
    subtype InstRtWidth    is integer range  4 downto  0;
    subtype InstRdWidth    is integer range  4 downto  0;
    subtype InstSaWidth    is integer range  4 downto  0;
    subtype InstFuncWidth  is integer range  5 downto  0;
    subtype InstImmWidth   is integer range 15 downto  0;
    subtype InstAddrWidth  is integer range 25 downto  0;

    --
    -- Opcodes
    --
    constant OP_ORI: std_logic_vector(InstOpWidth) := "001101";

end inst_const;