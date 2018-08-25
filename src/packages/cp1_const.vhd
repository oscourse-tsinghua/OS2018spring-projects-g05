library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package cp1_const is

    --
    -- ids of special usage registers.
    --
    -- See page 87 of document MD00082 Revision 6.01 for supported registers.
    -- Besides, some of the below registers is optional for Linux,
    -- so be careful if you want further implementation.
    constant FIR_REG:         integer := 0;
    -- Floating Point Implementation Register --
    constant FCSR_REG:        integer := 31;
    -- Floating Point Control and Status Register --
    constant FEXR_REG:     	  integer := 26;
    -- Floating Point Exception Register --
    constant FENR_REG:        integer := 28;
    -- Floating Point Enable Register --
    constant FCCR_REG:        integer := 25;
    -- Floating Point Condition Codes Register --

    --
    -- Bits of FCSR register
    --
    subtype FCSRFCCBits is integer range 31 downto 25;
    constant FCSR_FS_BIT: integer := 24;
    constant FCSR_FCC1_BIT: integer := 23;
    subtype FCSR2008Bits is integer range 19 downto 18; -- readonly 1, follow IEEE 752-2008
    subtype FCSRCauseBits is integer range 17 downto 12;
    subtype FCSREnablesBits is integer range 11 downto 7;
    subtype FCSRFlagsBits is integer range 6 downto 2;
    constant FCSR_E_BIT_OFFSET: integer := 5;
    constant FCSR_V_BIT_OFFSET: integer := 4;
    constant FCSR_Z_BIT_OFFSET: integer := 3;
    constant FCSR_O_BIT_OFFSET: integer := 2;
    constant FCSR_U_BIT_OFFSET: integer := 1;
    constant FCSR_I_BIT_OFFSET: integer := 0;
    subtype FCSRRMBits is integer range 1 downto 0;
    constant ROUND_TO_NEAREST: std_logic_vector(1 downto 0) := "00";
    constant ROUND_TO_ZERO: std_logic_vector(1 downto 0) := "01";
    constant ROUND_TO_PLUS: std_logic_vector(1 downto 0) := "10";
    constant ROUND_TO_MINUS: std_logic_vector(1 downto 0) := "11";

    --
    -- Bits of FCCR, FEXR, FENR register
    -- Note: though not required by Linux, write to these bits should force related bits in FCSR to change
    --
    subtype FCCRFCCBits is integer range 7 downto 0;
    subtype FEXRCauseBits is integer range 17 downto 12;
    subtype FEXRFlasgBits is integer range 6 downto 2;
    subtype FENREnablesBits is integer range 11 downto 7;
    constant FENR_FS_BIT: integer := 2;
    subtype FENRRMBits is integer range 1 downto 0;
end cp1_const;