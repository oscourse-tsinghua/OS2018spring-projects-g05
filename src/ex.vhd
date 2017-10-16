library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.alu_const.all;

entity ex is
    port (
        rst: in std_logic;
        aluSel_i: in std_logic_vector(AluSelWidth);
        aluOp_i: in std_logic_vector(AluOpWidth);
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
    process(rst, aluSel_i, aluOp_i, operand1_i, operand2_i,
            toWriteReg_i, writeRegAddr_i) begin
        if (rst = RST_ENABLE) then
            toWriteReg_o <= NO;
            writeRegAddr_o <= (others => '0');
            writeRegData_o <= (others => '0');
        else
            toWriteReg_o <= toWriteReg_i;
            writeRegAddr_o <= writeRegAddr_i;

            case aluSel_i is

                -- Logical operation --
                when ALUSEL_LOGIC =>
                    case aluOp_i is
                        when ALUOP_OR => writeRegData_o <= operand1_i or operand2_i;
                        when ALUOP_AND => writeRegData_o <= operand1_i and operand2_i;
                        when others => writeRegData_o <= (others => '0');
                    end case;

                -- Others --
                when others => writeRegData_o <= (others => '0');

            end case;
        end if;
    end process;

end bhv;