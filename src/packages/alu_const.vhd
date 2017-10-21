library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package alu_const is

    -- where is the operand type --
    type AluType is (
        INVALID,
        ALU_OR, ALU_AND, ALU_XOR, ALU_NOR, ALU_SLL, ALU_SRL, ALU_SRA,
        ALU_MOVN, ALU_MOVZ, ALU_MFHI, ALU_MFLO, ALU_MTHI, ALU_MTLO,
        ALU_ADD, ALU_ADDU, ALU_SUB, ALU_SUBU, ALU_SLT, ALU_SLTU, ALU_CLO, ALU_CLZ
    );

    -- where is the operand from --
    type OprSrcType is (
        INVALID,
        REG, IMM, SGN_IMM, SA
    );
    
    --
    -- Constants for Bit Operation
    --
    subtype RegBitOpIdx    is integer range  4 downto  0;
    subtype RegBitOpWidth  is integer range  4 downto  0;

end alu_const;