library ieee;
use ieee.std_logic_1164.all;

package inst_const is
    
    --
    -- Format of instructions, classified into R type, I type and J type
    --
    subtype InstOpIdx      is integer range 31 downto 26;
    subtype InstRsIdx      is integer range 25 downto 21;
    subtype InstRtIdx      is integer range 20 downto 16;
    subtype InstRdIdx      is integer range 15 downto 11;
    subtype InstSaIdx      is integer range 10 downto  6;
    subtype InstFuncIdx    is integer range  5 downto  0;
    subtype InstImmIdx     is integer range 15 downto  0;
    subtype InstAddrIdx    is integer range 25 downto  0;
    
    subtype InstOpWidth    is integer range  5 downto  0;
    subtype InstRsWidth    is integer range  4 downto  0;
    subtype InstRtWidth    is integer range  4 downto  0;
    subtype InstRdWidth    is integer range  4 downto  0;
    subtype InstSaWidth    is integer range  4 downto  0;
    subtype InstFuncWidth  is integer range  5 downto  0;
    subtype InstImmWidth   is integer range 15 downto  0;
    subtype InstAddrWidth  is integer range 25 downto  0;

    --
    -- Logic Opcodes
    --
    constant OP_AND: std_logic_vector(InstFuncWidth) := "100100";
    constant OP_OR: std_logic_vector(InstFuncWidth) := "100101";
    constant OP_XOR: std_logic_vector(InstFuncWidth) := "100110";
    constant OP_NOR: std_logic_vector(InstFuncWidth) := "100111";
    constant OP_ANDI: std_logic_vector(InstOpWidth) := "001100";
    constant OP_ORI: std_logic_vector(InstOpWidth) := "001101";
    constant OP_XORI: std_logic_vector(InstOpWidth) := "001110";
    constant OP_LUI: std_logic_vector(InstOpWidth) := "001111";

    --
    -- Algebraic Opcodes
    --
    constant OP_SLL: std_logic_vector(InstFuncWidth) := "000000";
    constant OP_SLLV: std_logic_vector(InstFuncWidth) := "000100";
    constant OP_SRL: std_logic_vector(InstFuncWidth) := "000010";
    constant OP_SRLV: std_logic_vector(InstFuncWidth) := "000110";
    constant OP_SRA: std_logic_vector(InstFuncWidth) := "000011";
    constant OP_SRAV: std_logic_vector(InstFuncWidth) := "000111";

    --
    -- Move Opcodes
    --
    constant OP_MOVN: std_logic_vector(InstFuncWidth) := "001011";
    constant OP_MOVZ: std_logic_vector(InstFuncWidth) := "001010";
    constant OP_MFHI: std_logic_vector(InstFuncWidth) := "010000";
    constant OP_MFLO: std_logic_vector(InstFuncWidth) := "010010";
    constant OP_MTHI: std_logic_vector(InstFuncWidth) := "010001";
    constant OP_MTLO: std_logic_vector(InstFuncWidth) := "010011";
    
    --
    -- Special cases(logics 31-25 in this case)
    --
    constant OP_SPECIAL: std_logic_vector(InstOpWidth) := "000000";
    --constant OP_11SPECIAL: std_logic_vector(InstRsWidth) := "00000";
    --constant OP_SASPECIAL: std_logic_vector(InstSaWidth) := "00000";
end inst_const;