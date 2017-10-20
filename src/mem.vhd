library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

entity mem is
    port (
        rst: in std_logic;
        toWriteReg_i: in std_logic;
        writeRegAddr_i: in std_logic_vector(RegAddrWidth);
        writeRegData_i: in std_logic_vector(DataWidth);
        toWriteReg_o: out std_logic;
        writeRegAddr_o: out std_logic_vector(RegAddrWidth);
        writeRegData_o: out std_logic_vector(DataWidth)
    );
end mem;

architecture bhv of mem is
begin
    process(rst, toWriteReg_i, writeRegAddr_i, writeRegData_i) begin
        if (rst = RST_ENABLE) then
            toWriteReg_o <= NO;
            writeRegAddr_o <= (others => '0');
            writeRegData_o <= (others => '0');
        else
            toWriteReg_o <= toWriteReg_i;
            writeRegAddr_o <= writeRegAddr_i;
            writeRegData_o <= writeRegData_i;
        end if;
    end process;
end bhv;