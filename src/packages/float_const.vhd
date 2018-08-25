library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package float_const is 
    subtype FloatFmtWidth			is integer range  4 downto  0;
    constant SingleType: std_logic_vector(FloatFmtWidth) := "10000";
    -- constant DoubleType: std_logic_vector(FloatFmtWidth) := "10001";
    -- constant WordType: std_logic_vector(FloatFmtWidth) := "10100";
    -- constant LongWordType: std_logic_vector(FloatFmtWidth) := "10101";
    constant PairedType: std_logic_vector(FloatFmtWidth) := "10110";
end float_const;