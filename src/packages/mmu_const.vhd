library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package mmu_const is
    constant TLBEntryNum: integer := 16;
    subtype TLBIndexWidth is integer range 3 downto 0;

    type TLBEntry is record
        hi, lo0, lo1: std_logic_vector(DataWidth);
    end record;
end mmu_const;
