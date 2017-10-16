library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

entity id_ex is
    port (
        rst, clk: in std_logic;
        aluSel_i: in std_logic_vector(AluSelWidth);
        aluOp_i: in std_logic_vector(AluOpWidth);
        operand1_i: in std_logic_vector(DataWidth);
        operand2_i: in std_logic_vector(DataWidth);
        toWriteReg_i: in std_logic;
        writeRegAddr_i: in std_logic_vector(RegAddrWidth);

        aluSel_o: out std_logic_vector(AluSelWidth);
        aluOp_o: out std_logic_vector(AluOpWidth);
        operand1_o: out std_logic_vector(DataWidth);
        operand2_o: out std_logic_vector(DataWidth);
        toWriteReg_o: out std_logic;
        writeRegAddr_o: out std_logic_vector(RegAddrWidth)
    );
end id_ex;

architecture bhv of id_ex is
begin
    process(clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                aluSel_o <= (others => '0');
                aluOp_o <= (others => '0');
                operand1_o <= (others => '0');
                operand2_o <= (others => '0');
                toWriteReg_o <= NO;
                writeRegAddr_o <= (others => '0');
            else
                aluSel_o <= aluSel_i;
                aluOp_o <= aluOp_i;
                operand1_o <= operand1_i;
                operand2_o <= operand2_i;
                toWriteReg_o <= toWriteReg_i;
                writeRegAddr_o <= writeRegAddr_i;
            end if;
        end if;
    end process;
end bhv;