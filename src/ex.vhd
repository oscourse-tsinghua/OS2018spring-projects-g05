library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
-- NOTE: std_logic_unsigned cannot be used at the same time with std_logic_unsigned
--       Use numeric_std if signed number is needed (different API)
use work.global_const.all;
use work.alu_const.all;
use work.mem_const.all;

entity ex is
    port (
        rst: in std_logic;
        alut_i: in AluType;
        memt_i: in MemType;
        operand1_i: in std_logic_vector(DataWidth);
        operand2_i: in std_logic_vector(DataWidth);
        operandX_i: in std_logic_vector(DataWidth);
        toWriteReg_i: in std_logic;
        writeRegAddr_i: in std_logic_vector(RegAddrWidth);

        toWriteReg_o: out std_logic;
        writeRegAddr_o: out std_logic_vector(RegAddrWidth);
        writeRegData_o: out std_logic_vector(DataWidth);

        -- Hi Lo --
        hi_i, lo_i: in std_logic_vector(DataWidth);
        memToWriteHi_i, memToWriteLo_i: in std_logic;
        memWriteHiData_i, memWriteLoData_i: in std_logic_vector(DataWidth);
        wbToWriteHi_i, wbToWriteLo_i: in std_logic;
        wbWriteHiData_i, wbWriteLoData_i: in std_logic_vector(DataWidth);
        toWriteHi_o, toWriteLo_o: out std_logic;
        writeHiData_o, writeLoData_o: out std_logic_vector(DataWidth);

        -- Memory --
        memt_o: out MemType;
        memAddr_o: out std_logic_vector(AddrWidth);
        memData_o: out std_logic_vector(DataWidth)
    );
end ex;

architecture bhv of ex is
    signal realHiData, realLoData: std_logic_vector(DataWidth) := (others => '0');
begin

    memt_o <= memt_i;

    process(all) begin
        if (rst = RST_ENABLE) then
            realHiData <= (others => '0');
            realLoData <= (others => '0');
        else
            realHiData <= hi_i;
            realLoData <= lo_i;
            if (wbToWriteHi_i = YES) then
                realHiData <= wbWriteHiData_i;
            end if;
            if (memToWriteHi_i = YES) then
                realHiData <= memWriteHiData_i;
            end if;
            if (wbToWriteLo_i = YES) then
                realLoData <= wbWriteLoData_i;
            end if;
            if (memToWriteLo_i = YES) then
                realLoData <= memWriteLoData_i;
            end if;
        end if;
    end process;

    process(all) begin
        toWriteHi_o <= NO;
        toWriteLo_o <= NO;
        toWriteReg_o <= toWriteReg_i;
        memAddr_o <= (others => '0');
        memData_o <= (others => '0');
        writeRegAddr_o <= (others => '0');
        writeRegData_o <= (others => '0');
        if (rst = RST_DISABLE) then
            writeRegAddr_o <= writeRegAddr_i;
            writeRegData_o <= (others => '0');

            case alut_i is
                when ALU_OR => writeRegData_o <= operand1_i or operand2_i;
                when ALU_AND => writeRegData_o <= operand1_i and operand2_i;
                when ALU_XOR => writeRegData_o <= operand1_i xor operand2_i;
                when ALU_NOR => writeRegData_o <= operand1_i nor operand2_i;
                when ALU_SLL => writeRegData_o <= operand2_i sll to_integer(unsigned(operand1_i));
                when ALU_SRL => writeRegData_o <= operand2_i srl to_integer(unsigned(operand1_i));
                when ALU_SRA => writeRegData_o <= to_stdlogicvector(to_bitvector(operand2_i) sra to_integer(unsigned(operand1_i)));

                when ALU_MOVN =>
                    if (operand2_i /= ZEROS_32) then
                        writeRegData_o <= operand1_i;
                    else
                        toWriteReg_o <= NO;
                        writeRegData_o <= (others => '0');
                    end if;
                when ALU_MOVZ =>
                    if (operand2_i = ZEROS_32) then
                        writeRegData_o <= operand1_i;
                    else
                        toWriteReg_o <= NO;
                        writeRegData_o <= (others => '0');
                    end if;
                when ALU_MFHI => writeRegData_o <= realHiData;
                when ALU_MFLO => writeRegData_o <= realLoData;
                when ALU_MTHI =>
                    toWriteHi_o <= YES;
                    writeHiData_o <= operand1_i;
                when ALU_MTLO =>
                    toWriteLo_o <= YES;
                    writeLoData_o <= operand1_i;

                when ALU_LOAD =>
                    memAddr_o <= operand1_i + operandX_i;

                when ALU_STORE =>
                    memAddr_o <= operand1_i + operandX_i;
                    memData_o <= operand2_i;

                when others =>
                    null;
            end case;

        end if;
    end process;

end bhv;
