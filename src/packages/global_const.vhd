library ieee;
use ieee.std_logic_1164.all;

package global_const is

    subtype InstWidth is integer range 31 downto 0;
    subtype AddrWidth is integer range 31 downto 0;
    subtype DataWidth is integer range 31 downto 0;
    subtype intWidth is integer range 5 downto 0;
    subtype RegAddrWidth is integer range 4 downto 0;
    subtype RegNum is integer range 0 to 31;

    subtype AluOpWidth is integer range 7 downto 0;
    subtype AluSelWidth is integer range 2 downto 0;

    type RegArrayType is array (RegNum) of std_logic_vector(DataWidth);

    constant ENABLE: std_logic := '1';
    constant DISABLE: std_logic := '0';
    
    constant RST_ENABLE: std_logic := '1';
    constant RST_DISABLE: std_logic := '0';

    constant YES: std_logic := '1';
    constant NO: std_logic := '0';

end global_const;