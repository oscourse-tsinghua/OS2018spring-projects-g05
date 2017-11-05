library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package cp0_const is
    --
    -- ids of special usage processors.
    --
    constant COUNT_PROCESSOR: std_logic_vector(CP0RegAddrWidth) := "01001";
    constant COMPARE_PROCESSOR: std_logic_vector(CP0RegAddrWidth) := "01011";
    constant STATUS_PROCESSOR: std_logic_vector(CP0RegAddrWidth) := "01100";
    constant CAUSE_PROCESSOR: std_logic_vector(CP0RegAddrWidth) := "01101";
    constant EPC_PROCESSOR: std_logic_vector(CP0RegAddrWidth) := "01110";
    constant PRID_PROCESSOR: std_logic_vector(CP0RegAddrWidth) := "01111";
    constant CONFIG_PROCESSOR: std_logic_vector(CP0RegAddrWidth) := "10000";

    --
    -- Bits of status register
    --
    constant STATUS_EXL_BIT: integer := 1; -- Exception level flag
    constant STATUS_IE_BIT: integer := 0; -- Interrupt enable flag

    --
    -- Bits of cause register
    --
    constant CAUSE_BD_BIT: integer := 31; -- Delay branch flag
    constant CAUSE_IV_BIT: integer := 23; -- Interrupt vector
    constant CAUSE_WP_BIT: integer := 22; -- Watch pending
    subtype CauseIpBits is integer range 15 downto 8;
    subtype CauseIpHardBits is integer range 15 downto 10;
    subtype CauseIpSoftBits is integer range  9 downto  8;
    subtype CauseExcCodeBits is integer range 6 downto 2;

end cp0_const;
