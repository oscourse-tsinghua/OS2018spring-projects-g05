library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ddr3_ctrl is
    port (
        clk_100, clk_25, rst: in std_logic;

        enable_i, readEnable_i: in std_logic;
        addr_i: in std_logic_vector(31 downto 0);
        writeData_i: in std_logic_vector(31 downto 0);
        readData_o: out std_logic_vector(31 downto 0);
        byteSelect_i: in std_logic_vector(3 downto 0);
        busy_o: out std_logic;

        enable_o, readEnable_o: out std_logic;
        addr_o: out std_logic_vector(31 downto 0);
        writeData_o: out std_logic_vector(31 downto 0);
        readData_i: in std_logic_vector(31 downto 0);
        byteSelect_o: out std_logic_vector(3 downto 0);
        busy_i: in std_logic
    );
end ddr3_ctrl;

architecture bhv of ddr3_ctrl is

    signal enable, ok, getOk: std_logic;
    signal data: std_logic_vector(31 downto 0);
    type State is (INIT, PROC, WAITING1, WAITING2);
    signal stat: State;

begin

    enable_o <= enable;
    addr_o <= addr_i;
    writeData_o <= writeData_i;
    byteSelect_o <= byteSelect_i;

    process(clk_100) begin
        if (rising_edge(clk_100)) then
            if (rst = '0') then
                enable <= '0';
                ok <= '0';
                stat <= INIT;
            else
                if (enable_i = '0') then
                    enable <= '0';
                end if;
                if (stat = INIT and enable_i = '1') then
                    enable <= '1';
                    readEnable_o <= readEnable_i;
                    stat <= PROC;
                elsif (stat = PROC and busy_i = '0') then
                    enable <= '0';
                    data <= readData_i;
                    ok <= '1';
                    stat <= WAITING1;
                elsif (stat = WAITING1 and getOk = '1') then
                    ok <= '0';
                    stat <= WAITING2;
                elsif (stat = WAITING2 and getOk = '0') then
                    stat <= INIT;
                end if;
            end if;
        end if;
    end process;

    process(clk_25) begin
        if (rising_edge(clk_25)) then
            if (ok = '1') then
                busy_o <= '0';
                readData_o <= data;
                getOk <= '1';
            else
                busy_o <= '1';
                getOk <= '0';
            end if;
        end if;
    end process;

end bhv;