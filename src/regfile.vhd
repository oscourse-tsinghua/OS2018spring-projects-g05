library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.global_const.all;

entity regfile is
    port (
        rst, clk: in std_logic;
        writeEnable_i: in std_logic;
        writeAddr_i: in std_logic_vector(RegAddrWidth);
        writeData_i: in std_logic_vector(DataWidth);
        readAddr1_i: in std_logic_vector(RegAddrWidth);
        readData1_o: out std_logic_vector(DataWidth);
        readAddr2_i: in std_logic_vector(RegAddrWidth);
        readData2_o: out std_logic_vector(DataWidth)
    );
end regfile;

architecture bhv of regfile is
    signal regArray: RegArrayType := (others => (others => '0'));
begin
    process(clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                regArray <= (others => (others => '0'));
            else
                if (writeEnable_i = ENABLE and writeAddr_i /= "00000") then
                    regArray(conv_integer(writeAddr_i)) <= writeData_i;
                end if;
            end if;
        end if;
    end process;

    process(all) begin
        readData1_o <= regArray(conv_integer(readAddr1_i));
        if (readAddr1_i = writeAddr_i and writeEnable_i = ENABLE) then
            readData1_o <= writeData_i;
        end if;
        if (readAddr1_i = "00000") then
            readData1_o <= (others => '0');
        end if;
    end process;

    process(all) begin
        readData2_o <= regArray(conv_integer(readAddr2_i));
        if (readAddr2_i = writeAddr_i and writeEnable_i = ENABLE) then
            readData2_o <= writeData_i;
        end if;
        if (readAddr2_i = "00000") then
            readData2_o <= (others => '0');
        end if;
    end process;

end bhv;
