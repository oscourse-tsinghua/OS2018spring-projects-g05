library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package alu_const is

    -- where is the operand type --
    type AluType is (
        INVALID,
        ALU_OR, ALU_AND, ALU_XOR, ALU_NOR, ALU_SLL, ALU_SRL, ALU_SRA, ALU_LUI,
        ALU_MOVN, ALU_MOVZ, ALU_MFHI, ALU_MFLO, ALU_MTHI, ALU_MTLO, ALU_MFH,
        ALU_LOAD, ALU_STORE,
        ALU_ADD, ALU_ADDU, ALU_SUB, ALU_SUBU, ALU_SLT, ALU_SLTU, ALU_CLO, ALU_CLZ,
        ALU_MUL, ALU_MULT, ALU_MULTU, ALU_MADD, ALU_MADDU, ALU_MSUB, ALU_MSUBU, ALU_DIV, ALU_DIVU,
        ALU_JBAL,
        ALU_MFC0, ALU_MTC0, ALU_TLBWI, ALU_TLBWR, ALU_TLBP, ALU_TLBR, ALU_TLBINVF
    );

    -- floating point operand type --
    type FPAluType is (
        INVALID,
        FPALU_ABS, FPALU_NEG
    );

    -- where is the operand from --
    type OprSrcType is (
        INVALID,
        REG, IMM, SGN_IMM, SA, REGID
    );

    -- Extra operand invented for offset (memory) --
    type XOprSrcType is (
        INVALID,
        IMM
    );

    -- Floating point operands --
    type FOprSrcType is  (
        INVALID,
        SINGLE, PAIRED
    );

    type FloatExceptType is (
        NO,
        UNIMPL, INVALID, DIV_BY_ZERO, OVERFLOW, UNDERFLOW, INEXACT
    );

    --
    -- Constants for Bit Operation
    --
    subtype RegBitOpIdx    is integer range  4 downto  0;
    subtype RegBitOpWidth  is integer range  4 downto  0;

end alu_const;
