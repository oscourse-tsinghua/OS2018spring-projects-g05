library ieee;
use ieee.std_logic_1164.all;

package inst_const is

    --
    -- Format of instructions, classified into R type, I type and J type
    --
    subtype InstOpIdx               is integer range 31 downto 26;
    subtype InstRsIdx               is integer range 25 downto 21;
    subtype InstRtIdx               is integer range 20 downto 16;
    subtype InstRdIdx               is integer range 15 downto 11;
    subtype InstOpRsIdx             is integer range 31 downto 21;
    subtype InstSaIdx               is integer range 10 downto  6;
    subtype InstFuncIdx             is integer range  5 downto  0;
    subtype InstImmIdx              is integer range 15 downto  0;
    subtype InstUnsignedImmIdx      is integer range 14 downto  0;
    subtype InstImmSignIdx          is integer range 15 downto 15;
    subtype InstAddrIdx             is integer range 25 downto  0;
    subtype InstJmpUnchangeIdx      is integer range 31 downto 28;
    subtype InstImmAddrIdx          is integer range 25 downto  0;
    subtype InstSaFuncIdx           is integer range 10 downto  0;

    subtype InstOpWidth             is integer range  5 downto  0;
    subtype InstRsWidth             is integer range  4 downto  0;
    subtype InstRtWidth             is integer range  4 downto  0;
    subtype instOpRsWidth           is integer range 10 downto  0;
    subtype InstRdWidth             is integer range  4 downto  0;
    subtype InstSaWidth             is integer range  4 downto  0;
    subtype InstFuncWidth           is integer range  5 downto  0;
    subtype InstImmWidth            is integer range 15 downto  0;
    subtype InstUnsignedImmWidth    is integer range 14 downto  0;
    subtype InstImmSignWidth        is integer range 15 downto 15;
    subtype InstAddrWidth           is integer range 25 downto  0;
    subtype InstJmpUnchangeWidth    is integer range  3 downto  0;
    subtype InstImmAddrWidth        is integer range 25 downto  0;
    subtype InstOffsetImmWidth      is integer range 17 downto  0;
    subtype InstSaFuncWidth         is integer range 10 downto  0;

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
    -- Memory Opcodes
    --
    constant OP_LB: std_logic_vector(InstOpWidth) := "100000";
    constant OP_LBU: std_logic_vector(InstOpWidth) := "100100";
    constant OP_LW: std_logic_vector(InstOpWidth) := "100011";
    constant OP_SB: std_logic_vector(InstOpWidth) := "101000";
    constant OP_SW: std_logic_vector(InstOpWidth) := "101011";
    
    --
    -- Arith Opcodes
    --
    constant OP_ADD: std_logic_vector(InstFuncWidth) := "100000";
    constant OP_ADDU: std_logic_vector(InstFuncWidth) := "100001";
    constant OP_SUB: std_logic_vector(InstFuncWidth) := "100010";
    constant OP_SUBU: std_logic_vector(InstFuncWidth) := "100011";
    constant OP_SLT: std_logic_vector(InstFuncWidth) := "101010";
    constant OP_SLTU: std_logic_vector(InstFuncWidth) := "101011";
    constant OP_MULT: std_logic_vector(InstFuncWidth) := "011000";
    constant OP_MULTU: std_logic_vector(InstFuncWidth) := "011001";

    constant OP_ADDI: std_logic_vector(InstOpWidth) := "001000";
    constant OP_ADDIU: std_logic_vector(InstOpWidth) := "001001";
    constant OP_SLTI: std_logic_vector(InstOpWidth) := "001010";
    constant OP_SLTIU: std_logic_vector(InstOpWidth) := "001011";

    constant OP_CLO: std_logic_vector(InstFuncWidth) := "100001";
    constant OP_CLZ: std_logic_vector(InstFuncWidth) := "100000";
    constant OP_MUL: std_logic_vector(InstFuncWidth) := "000010";

    constant OP_MADD: std_logic_vector(InstFuncWidth) := "000000";
    constant OP_MADDU: std_logic_vector(InstFuncWidth) := "000001";
    constant OP_MSUB: std_logic_vector(InstFuncWidth) := "000100";
    constant OP_MSUBU: std_logic_vector(InstFuncWidth) := "000101";

    --
    -- Jump Opcodes
    --
    constant JMP_JALR: std_logic_vector(InstFuncWidth) := "001001";
    constant JMP_JR: std_logic_vector(InstFuncWidth):= "001000";
    
    constant JMP_BLTZ: std_logic_vector(InstRtWidth) := "00000";
    constant JMP_BGEZ: std_logic_vector(InstRtWidth) := "00001";
    
    constant JMP_BEQ: std_logic_vector(InstOpWidth) := "000100";
    constant JMP_BGTZ: std_logic_vector(InstOpWidth) := "000111";
    constant JMP_BLEZ: std_logic_vector(InstOpWidth) := "000110";
    constant JMP_J: std_logic_vector(InstOpWidth) := "000010";
    constant JMP_JAL: std_logic_vector(InstOpWidth) := "000011";
    constant JMP_BNE: std_logic_vector(InstOpWidth) := "000101";
    
    --
    -- Special cases(logics 31-25 in this case)
    --
    constant OP_SPECIAL: std_logic_vector(InstOpWidth) := "000000";
    constant OP_SPECIAL2: std_logic_vector(InstOpWidth) := "011100";
    constant OP_JMPSPECIAL: std_logic_vector(InstOpWidth) := "000001";
    
end inst_const;
