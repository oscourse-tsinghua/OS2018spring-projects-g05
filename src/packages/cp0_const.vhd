library ieee;
use ieee.std_logic_1164.all;

package cp0_const is

    --
    -- consts for cp0
    --
    subtype ExternalInterruptAssertIdx      is integer range 15 downto 10;
    
    subtype CP0ProcessorIdWidth             is integer range  4 downto  0;
    subtype CP0Assert                       is std_logic;
    
    --
    -- ids of special usage processors.
    --
    
    constant COUNT_PROCESSOR: std_logic_vector(CP0ProcessorIdWidth) := "01001";
    constant COMPARE_PROCESSOR: std_logic_vector(CP0ProcessorIdWidth) := "01011";
    constant STATUS_PROCESSOR: std_logic_vector(CP0ProcessorIdWidth) := "01100";
    constant CAUSE_PROCESSOR: std_logic_vector(CP0ProcessorIdWidth) := "01101";
    constant EPC_PROCESSOR: std_logic_vector(CP0ProcessorIdWidth) := "01110";
    constant PRID_PROCESSOR: std_logic_vector(CP0ProcessorIdWidth) := "01111";
    constant CONFIG_PROCESSOR: std_logic_vector(CP0ProcessorIdWidth) := "10000";
    
    --
    -- assert constant
    --
    constant INTERRUPT_ASSERT: CP0Assert := '1';
    constant INTERRUPT_NOT_ASSERT: CP0Assert := '0';
end cp0_const;
