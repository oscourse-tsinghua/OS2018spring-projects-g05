library ieee;
use ieee.std_logic_1164.all;

package global_const is

    subtype InstWidth is integer range 31 downto 0;
    subtype AddrWidth is integer range 31 downto 0;
    subtype DataWidth is integer range 31 downto 0;
    subtype DoubleDataWidth is integer range 63 downto 0;
    subtype HiDataWidth is integer range 63 downto 32;
    subtype LoDataWidth is integer range 31 downto 0;
    subtype IntWidth is integer range 5 downto 0;
    subtype RegAddrWidth is integer range 4 downto 0;
    subtype RegNum is integer range 0 to 31;
    subtype CntWidth is integer range 1 downto 0;
    subtype CP0RegAddrWidth is integer range 4 downto 0;
    subtype ExceptionWidth is integer range 31 downto 0;

    type RegArrayType is array (RegNum) of std_logic_vector(DataWidth);

    subtype StallWidth is integer range 0 to 5;
    constant  PC_STOP_IDX: integer := 0;
    constant  IF_STOP_IDX: integer := 1;
    constant  ID_STOP_IDX: integer := 2;
    constant  EX_STOP_IDX: integer := 3;
    constant MEM_STOP_IDX: integer := 4;
    constant  WB_STOP_IDX: integer := 5;

    constant ENABLE: std_logic := '1';
    constant DISABLE: std_logic := '0';

    constant RST_ENABLE: std_logic := '1';
    constant RST_DISABLE: std_logic := '0';

    constant PIPELINE_STOP: std_logic := '1';
    constant PIPELINE_NONSTOP: std_logic := '0';

    constant YES: std_logic := '1';
    constant NO: std_logic := '0';

    constant ZEROS_32: std_logic_vector(31 downto 0) := (others => '0');
    constant ZEROS_31: std_logic_vector(30 downto 0) := (others => '0');
    
        
    --
    -- For Branch instuctions
    --
    constant BRANCH_FLAG: std_logic := '1';
    constant NOT_BRANCH_FLAG: std_logic := '0';
    constant BRANCH_ZERO_WORD: std_logic_vector(AddrWidth) := "00000000000000000000000000000000";
    constant IN_DELAY_SLOT_FLAG: std_logic := '1';
    constant NOT_IN_DELAY_SLOT_FLAG: std_logic := '0';
    
    --
    -- For cp0 coprecessors
    --
    constant CP0_ZERO_WORD: std_logic_vector(DataWidth) := "00000000000000000000000000000000";

    --
    -- For Exceptions
    --
    constant INSTVALID: std_logic := '0';
    constant INSTINVALID: std_logic := '1';
    constant INTERRUPT_ASSERT: std_logic := '1';
    constant INTERRUPT_NOT_ASSERT: std_logic := '0';
    constant TRAP_ASSERT: std_logic := '1';
    constant TRAP_NOT_ASSERT: std_logic := '0';
    constant EXCEPTION_ZERO_WORD: std_logic_vector(DataWidth) := "00000000000000000000000000000000";
    constant EXTERNALEXCEPTION: std_logic_vector(ExceptionWidth) := "00000000000000000000000000000001";
    constant SYSCALLEXCEPTION: std_logic_vector(ExceptionWidth) := "00000000000000000000000000000100";
    constant INVALIDINSTEXCEPTION: std_logic_vector(ExceptionWidth) := "00000000000000000000000000001010";
    constant OVERFLOWEXCEPTION: std_logic_vector(ExceptionWidth) := "00000000000000000000000000001101";
    constant ERETEXCEPTION: std_logic_vector(ExceptionWidth) := "00000000000000000000000000001110";

end global_const;
