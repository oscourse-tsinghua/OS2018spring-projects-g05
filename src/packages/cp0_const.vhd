library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package cp0_const is
    type CP0Special is ( -- Special CP0 Operation Type
        INVALID, CP0SP_TLBWI, CP0SP_TLBWR, CP0SP_TLBP, CP0SP_TLBR,
        CP0SP_TLBINVF
    );

    --
    -- ids of special usage registers.
    --
    constant INDEX_REG:         integer := 0;
    constant RANDOM_REG:        integer := 1;
    constant ENTRY_LO0_REG:     integer := 2;
    constant ENTRY_LO1_REG:     integer := 3;
    constant CONTEXT_REG:       integer := 4;
    constant PAGEMASK_REG:      integer := 5;
    constant WIRED_REG:         integer := 6;
    constant BAD_V_ADDR_REG:    integer := 8;
    constant COUNT_REG:         integer := 9;
    constant ENTRY_HI_REG:      integer := 10;
    constant COMPARE_REG:       integer := 11;
    constant STATUS_REG:        integer := 12;
    constant CAUSE_REG:         integer := 13;
    constant EPC_REG:           integer := 14;
    constant PRID_OR_EBASE_REG: integer := 15;
    constant CONFIG_REG:        integer := 16;
    constant WATCHLO_REG:       integer := 18;
    constant WATCHHI_REG:       integer := 19;
    constant DEPC_REG:          integer := 24;
    -- Max implemented ID of CP0 registers
    constant CP0_MAX_ID: integer := 24;
    

    --
    -- Bits of EntryHi register
    --
    subtype EntryHiVPN2Bits is integer range 31 downto 13; -- Virtual Page Address
    subtype EntryHiASIDBits is integer range 7 downto 0; -- Address Space ID

    --
    -- Bits of EntryLo0~1 registers
    --
    subtype EntryLoRWBits is integer range 29 downto 0;
    subtype EntryLoPFNBits is integer range 25 downto 6; -- Page Frame Number (We only use its lower 20 bits)
    constant ENTRY_LO_D_BIT: integer := 2; -- Dirty flag
    constant ENTRY_LO_V_BIT: integer := 1; -- Valid flag
    constant ENTRY_LO_G_BIT: integer := 0; -- Global flag

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
    -- Bits of config register
    --
    subtype Config0K0Bits is integer range 2 downto 0;

    --
    -- Bits of prId register
    --
    constant PRID_CONSTANT: std_logic_vector(31 downto 0) := 32ux"00018000";

    --
    -- Bits of context register
    --
    subtype ContextPTEBaseBits is integer range 31 downto 23;
    subtype ContextBadVPNBits is integer range 22 downto 4;

    --
    -- Bits of PageMask register
    --
    subtype PageMaskMaskBits is integer range 28 downto 13; -- not a typo

    --
    -- Bits of WatchHi register
    --
    constant WATCHHI_G_BIT: integer := 30;
    subtype WatchHiASIDBits is integer range 23 downto 16;
    subtype WatchHiMaskBits is integer range 11 downto 3;
    subtype WatchHiW1CBits is integer range 2 downto 0; -- write 1 to clear
    constant WATCHHI_I_BIT: integer := 2; -- though WATCH_I_BIT is enough, write this to keep the name consistent
    constant WATCHHI_R_BIT: integer := 1;
    constant WATCHHI_W_BIT: integer := 0;

    --
    -- Bits of WatchLo register
    --
    subtype WatchLoVAddrBits is integer range 31 downto 3;
    constant WATCHLO_I_BIT: integer := 2;
    constant WATCHLO_R_BIT: integer := 1;
    constant WATCHLO_W_BIT: integer := 0;
end cp0_const;
