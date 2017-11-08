library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package cp0_const is
    --
    -- ids of special usage registers.
    --
    constant INDEX_REG: std_logic_vector(CP0RegAddrWidth) := 5ud"0";
    constant RANDOM_REG: std_logic_vector(CP0RegAddrWidth) := 5ud"1";
    constant ENTRY_LO0_REG: std_logic_vector(CP0RegAddrWidth) := 5ud"2";
    constant ENTRY_LO1_REG: std_logic_vector(CP0RegAddrWidth) := 5ud"3";
    constant BAD_V_ADDR_REG: std_logic_vector(CP0RegAddrWidth) := 5ud"8";
    constant COUNT_REG: std_logic_vector(CP0RegAddrWidth) := 5ud"9";
    constant ENTRY_HI: std_logic_vector(CP0RegAddrWidth) := 5ud"10";
    constant COMPARE_REG: std_logic_vector(CP0RegAddrWidth) := 5ud"11";
    constant STATUS_REG: std_logic_vector(CP0RegAddrWidth) := 5ud"12";
    constant CAUSE_REG: std_logic_vector(CP0RegAddrWidth) := 5ud"13";
    constant EPC_REG: std_logic_vector(CP0RegAddrWidth) := 5ud"14";
    constant PRID_REG: std_logic_vector(CP0RegAddrWidth) := 5ud"15";
    constant CONFIG_REG: std_logic_vector(CP0RegAddrWidth) := 5ud"16";

    --
    -- Bits of EntryHi register
    --
    subtype EntryHiVPN2Bits is integer range 31 downto 13; -- Virtual Page Address
    subtype EntryHiASIDBits is integer range 7 downto 0; -- Address Space ID

    --
    -- Bits of EntryLo0~1 registers
    --
    subtype EntryLoPFNBits is integer range 25 downto 6; -- Page Frame Number (We only use its lower 20 bits)
    constant ENTRY_LO_D_BIT: integer := 2; -- Dirty flag (0 for dirty)
    constant ENTRY_LO_V_BIT: integer := 1; -- Valid flag
    constant ENTRY_LO_G_BIT: integer := 0; -- Global flag

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
