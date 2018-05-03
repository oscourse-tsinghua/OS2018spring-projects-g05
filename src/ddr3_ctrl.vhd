library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ddr3_ctrl is
    port (
        clk_100, clk_25, rst_100, rst_25: in std_logic;

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

    signal enable_req, readEnable_req, busy_res: std_logic;
    signal addr_req, writeData_req, readData_res: std_logic_vector(31 downto 0);
    signal byteSelect_req: std_logic_vector(3 downto 0);
    type State is (INIT, PROC, WAIT1, WAIT2);
    signal stat100, stat25: State;

begin

    process (clk_100) begin
        if (rising_edge(clk_100)) then
            if (rst_100 = '0') then
                enable_o <= '0';
                readEnable_o <= '1';
                addr_o <= (others => '0');
                writeData_o <= (others => '0');
                byteSelect_o <= (others => '0');
                busy_res <= '1';
                readData_res <= (others => '0');
                stat100 <= INIT;
            else
                if (stat100 = INIT and enable_req = '1') then
                    enable_o <= '1';
                    readEnable_o <= readEnable_req;
                    addr_o <= addr_req;
                    writeData_o <= writeData_req;
                    byteSelect_o <= byteSelect_req;
                    stat100 <= PROC;
                elsif (stat100 = PROC and busy_i = '0') then
                    enable_o <= '0';
                    readData_res <= readData_i;
                    busy_res <= '0';
                    stat100 <= WAIT1;
                elsif (stat100 = WAIT1 and enable_req = '0') then
                    busy_res <= '1';
                    readData_res <= (others => '0');
                    stat100 <= INIT;
                end if;
            end if;
        end if;
    end process;

    process(clk_25) begin
        if (rising_edge(clk_25)) then
            if (rst_25 = '0') then
                busy_o <= '1';
                readData_o <= (others => '0');
                enable_req <= '0';
                readEnable_req <= '1';
                addr_req <= (others => '0');
                writeData_req <= (others => '0');
                byteSelect_req <= (others => '0');
                stat25 <= INIT;
            else
                if (stat25 = INIT and enable_i = '1') then
                    enable_req <= '1';
                    readEnable_req <= readEnable_i;
                    addr_req <= addr_i;
                    writeData_req <= writeData_i;
                    byteSelect_req <= byteSelect_i;
                    stat25 <= PROC;
                elsif (stat25 = PROC and busy_res = '0') then
                    stat25 <= WAIT1; -- We use 2 period WAIT to meet the timing requirement
                elsif (stat25 = WAIT1) then
                    readData_o <= readData_res;
                    enable_req <= '0';
                    busy_o <= '0';
                    stat25 <= WAIT2;
                elsif (stat25 = WAIT2) then
                    busy_o <= '1';
                    readData_o <= (others => '0');
                    stat25 <= INIT;
                end if;
            end if;
        end if;
    end process;

end bhv;
