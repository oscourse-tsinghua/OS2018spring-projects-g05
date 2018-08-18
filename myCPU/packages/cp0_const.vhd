library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package cp0_const is
    --
    -- ids of special usage registers.
    --
    constant INDEX_REG:         integer := 0;
    constant WIRED_REG:         integer := 6;
    constant BAD_V_ADDR_REG:    integer := 8;
    constant COUNT_REG:         integer := 9;
    constant COMPARE_REG:       integer := 11;
    constant STATUS_REG:        integer := 12;
    constant CAUSE_REG:         integer := 13;
    constant EPC_REG:           integer := 14;
    constant PRID_OR_EBASE_REG: integer := 15;
    -- Max implemented ID of CP0 registers
    constant CP0_MAX_ID: integer := 15;

    --
    -- Bits of status register
    --
    constant STATUS_CP0_BIT: integer := 28; -- CP0 available flag
    constant STATUS_BEV_BIT: integer := 22; -- Bootstrap flag
    subtype StatusImBits is integer range 15 downto 8; -- Interruption mask
    constant STATUS_UM_BIT: integer := 4; -- User mode flag
    constant STATUS_ERL_BIT: integer := 2; -- Error level flag
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

    --
    -- Bits of ebase register
    --
    subtype EbaseAddrBits is integer range 29 downto 12; -- Formal name is EbaseExceptionBaseBits

    --
    -- Bits of prId register
    --
    constant PRID_CONSTANT: std_logic_vector(31 downto 0) := 32ux"00018000";

end cp0_const;
