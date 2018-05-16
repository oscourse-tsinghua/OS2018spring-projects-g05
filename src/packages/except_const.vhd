library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package except_const is
    subtype ExceptionCauseWidth is integer range 4 downto 0;

    constant INTERRUPT_ASSERT: std_logic := '1';
    constant INTERRUPT_NOT_ASSERT: std_logic := '0';
    constant TRAP_ASSERT: std_logic := '1';
    constant TRAP_NOT_ASSERT: std_logic := '0';

    --
    -- 6~2 bits in cause register
    --
    constant NO_CAUSE: std_logic_vector(ExceptionCauseWidth) := (others => '1');
    -- NOTE: Because 0x0 if for interruption, we use 0x1F for none
    constant EXTERNAL_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ux"0";
    constant TLB_LOAD_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ux"2";
    constant TLB_STORE_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ux"3";
    constant ADDR_ERR_LOAD_OR_IF_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ux"4";
    constant ADDR_ERR_STORE_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ux"5";
    constant SYSCALL_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ux"8";
    constant BREAKPOINT_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ux"9";
    constant INVALID_INST_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ux"a";
    constant OVERFLOW_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ux"c";
    constant TRAP_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ux"d";
    constant ERET_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ux"e";
    -- Cause of eret is not in standard. We do this because 14~22 is reserved
end except_const;
