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

    signal enable_i1, enable, ok, getOk: std_logic;
    signal data: std_logic_vector(31 downto 0);
    type State is (INIT, PROC, WAITING1, WAITING2);
    signal stat, stat25: State;

    attribute mark_debug: string;
    attribute mark_debug of enable_i: signal is "true";
    attribute mark_debug of readEnable_i: signal is "true";
    attribute mark_debug of addr_i: signal is "true";
    attribute mark_debug of writeData_i: signal is "true";
    attribute mark_debug of readData_o: signal is "true";
    attribute mark_debug of busy_o: signal is "true";
    attribute mark_debug of enable_o: signal is "true";
    attribute mark_debug of readEnable_o: signal is "true";
    attribute mark_debug of addr_o: signal is "true";
    attribute mark_debug of writeData_o: signal is "true";
    attribute mark_debug of readData_i: signal is "true";
    attribute mark_debug of busy_i: signal is "true";

    attribute mark_debug of enable_i1, enable: signal is "true";

begin

    enable_o <= enable;
    addr_o <= addr_i;
    writeData_o <= writeData_i;
    byteSelect_o <= byteSelect_i;

    process (clk_100) begin
        if (rising_edge(clk_100)) then
            if (rst = '0') then
                enable <= '0';
                ok <= '0';
                stat <= INIT;
            else
                if (enable_i1 = '0') then
                    enable <= '0';
                end if;
                if (stat = INIT and enable_i1 = '1') then
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

--    process(clk_25) begin
--        if (rising_edge(clk_25)) then
--            if (ok = '1') then
--                busy_o <= '0';
--                readData_o <= data;
--                getOk <= '1';
--            else
--                busy_o <= '1';
--                getOk <= '0';
--            end if;
--        end if;
--    end process;
    
--    enable_i1 <= enable_i;

    process(clk_25) begin
        if (rising_edge(clk_25)) then
            if (rst = '0') then
                enable_i1 <= '0';
                stat25 <= INIT;
                busy_o <= '1';
            else
                if (stat25 = INIT and enable_i = '1') then
                    enable_i1 <= '1';
                    stat25 <= PROC;
                elsif (stat25 = PROC and ok = '1') then
                    enable_i1 <= '0';
                    busy_o <= '0';
                    readData_o <= data;
                    getOk <= '1';
                    stat25 <= WAITING1;
                elsif (stat25 = WAITING1 and ok = '0') then
                    busy_o <= '1';
                    getOk <= '0';
                    stat25 <= INIT;
                end if;
            end if;
        end if;
    end process;

end bhv;