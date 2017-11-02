library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package cp0_const is

    --
    -- consts for cp0
    --
    subtype ExternalInterruptAssertIdx      is integer range 15 downto 10;
    subtype CP0IP10Idx                      is integer range  9 downto  8;
    subtype CP0IVIdx                        is integer range 23 downto 23;
    subtype CP0WPIdx                        is integer range 22 downto 22;
    
    subtype CP0Assert                       is std_logic;
    subtype CP0IP10Width                    is integer range  1 downto  0;
    
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
    -- assert constant
    --
    constant INTERRUPT_ASSERT: CP0Assert := '1';
    constant INTERRUPT_NOT_ASSERT: CP0Assert := '0';

end cp0_const;
