library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.global_const.all;
use work.alu_const.all;

entity ex is
    port (
        rst: in std_logic;
        alut_i: in AluType;
        operand1_i: in std_logic_vector(DataWidth);
        operand2_i: in std_logic_vector(DataWidth);
        toWriteReg_i: in std_logic;
        writeRegAddr_i: in std_logic_vector(RegAddrWidth);

        toWriteReg_o: out std_logic;
        writeRegAddr_o: out std_logic_vector(RegAddrWidth);
        writeRegData_o: out std_logic_vector(DataWidth)
    );
end ex;

architecture bhv of ex is
begin
    process(rst, alut_i, operand1_i, operand2_i,
            toWriteReg_i, writeRegAddr_i) begin
        if (rst = RST_ENABLE) then
            writeRegAddr_o <= (others => '0');
            writeRegData_o <= (others => '0');
        else
            toWriteReg_o <= toWriteReg_i;
            writeRegAddr_o <= writeRegAddr_i;

            case alut_i is
                when ALU_OR => writeRegData_o <= operand1_i or operand2_i;
                when ALU_AND => writeRegData_o <= operand1_i and operand2_i;
                when ALU_XOR => writeRegData_o <= operand1_i xor operand2_i;
                when ALU_NOR => writeRegData_o <= operand1_i nor operand2_i;
                when ALU_SLL => writeRegData_o <= operand1_i sll to_integer(unsigned(operand2_i));
                when ALU_SRL => writeRegData_o <= operand1_i srl to_integer(unsigned(operand2_i));
                when ALU_SRA => writeRegData_o <= to_stdlogicvector(to_bitvector(operand1_i) sra to_integer(unsigned(operand2_i)));
                when others => writeRegData_o <= (others => '0');
            end case;

        end if;
    end process;

end bhv;