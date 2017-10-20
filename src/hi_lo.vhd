library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

entity hi_lo is
    port (
        rst, clk: in std_logic;
        writeEnable_i: in std_logic;
        writeHiData_i, writeLoData_i: in std_logic_vector(DataWidth);
        readHiData_o, readLoData_o: out std_logic_vector(DataWidth)
    );
end hi_lo;

architecture bhv of hi_lo is
    signal hiData, loData: std_logic_vector(DataWidth) := (others => '0');
begin

    process(clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                hiData <= (others => '0');
                loData <= (others => '0');
            else
                if (writeEnable_i = ENABLE) then
                    hiData <= writeHiData_i;
                    loData <= writeLoData_i;
                end if;
            end if;
        end if;
    end process;

    process(rst, hiData, loData) begin
        if (rst = RST_ENABLE) then
            readHiData_o <= (others => '0');
            readLoData_o <= (others => '0');
        else
            readHiData_o <= hiData;
            readLoData_o <= loData;
        end if;
    end process;
 
end bhv;