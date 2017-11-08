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
    constant EXTERNAL_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ud"0";
    constant TLB_LOAD_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ud"2";
    constant TLB_STORE_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ud"3";
    constant ADDR_ERR_LOAD_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ud"4";
    constant ADDR_ERR_STORE_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ud"5";
    constant SYSCALL_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ud"8";
    constant INVALID_INST_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ud"10";
    constant OVERFLOW_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ud"12";
    constant ERET_CAUSE: std_logic_vector(ExceptionCauseWidth) := 5ud"14";
    -- Cause of eret is not in standard. We do this because 14~22 is reserved

    --
    -- Branch Target Address when Exception happens, needs future implementation here.
    --
    constant EXTERNAL_INTERRUPT_BRANCH_ADDR: std_logic_vector(AddrWidth) := 32ux"20";
    constant SYSCALL_EXCEPTION_BRANCH_ADDR: std_logic_vector(AddrWidth) := 32ux"40";
    constant INVALID_INST_EXCEPTION_BRANCH_ADDR: std_logic_vector(AddrWidth) := 32ux"40";
    constant OVERFLOW_EXCEPTION_BRANCH_ADDR: std_logic_vector(AddrWidth) := 32ux"40";
end except_const;
