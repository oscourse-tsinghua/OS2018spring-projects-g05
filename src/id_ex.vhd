library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.alu_const.all;
use work.mem_const.all;

entity id_ex is
    port (
        rst, clk: in std_logic;
        alut_i: in AluType;
        memt_i: in MemType;
        operand1_i: in std_logic_vector(DataWidth);
        operand2_i: in std_logic_vector(DataWidth);
        operandX_i: in std_logic_vector(DataWidth);
        toWriteReg_i: in std_logic;
        writeRegAddr_i: in std_logic_vector(RegAddrWidth);

        alut_o: out AluType;
        memt_o: out MemType;
        operand1_o: out std_logic_vector(DataWidth);
        operand2_o: out std_logic_vector(DataWidth);
        operandX_o: out std_logic_vector(DataWidth);
        toWriteReg_o: out std_logic;
        writeRegAddr_o: out std_logic_vector(RegAddrWidth)
    );
end id_ex;

architecture bhv of id_ex is
begin
    process(clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                alut_o <= INVALID;
                memt_o <= INVALID;
                operand1_o <= (others => '0');
                operand2_o <= (others => '0');
                operandX_o <= (others => '0');
                toWriteReg_o <= NO;
                writeRegAddr_o <= (others => '0');
            else
                alut_o <= alut_i;
                memt_o <= memt_i;
                operand1_o <= operand1_i;
                operand2_o <= operand2_i;
                operandX_o <= operandX_i;
                toWriteReg_o <= toWriteReg_i;
                writeRegAddr_o <= writeRegAddr_i;
            end if;
        end if;
    end process;
end bhv;
