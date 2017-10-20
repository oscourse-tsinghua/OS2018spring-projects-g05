library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package alu_const is

    type AluType is (
        INVALID,
        ALU_OR, ALU_AND, ALU_XOR
    );

    -- where is the operand from --
    type OprSrcType is (
        INVALID,
        REG, IMM
    );

end alu_const;