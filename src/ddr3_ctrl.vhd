library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.global_const.all;
use work.ddr3_const.all;

entity ddr3_ctrl is
    port (
        clk_100, clk_25, rst_100, rst_25: in std_logic;

        enable_i, readEnable_i: in std_logic;
        addr_i: in std_logic_vector(AddrWidth);
        writeData_i: in std_logic_vector(DataWidth);
        readDataBurst_o: out BurstDataType;
        byteSelect_i: in std_logic_vector(3 downto 0);
        busy_o: out std_logic;

        enable_o, readEnable_o: out std_logic;
        addr_o: out std_logic_vector(AddrWidth);
        writeData_o: out std_logic_vector(DataWidth);
        readDataBurst_i: in BurstDataType;
        byteSelect_o: out std_logic_vector(3 downto 0);
        busy_i: in std_logic
    );
end ddr3_ctrl;

architecture bhv of ddr3_ctrl is

    signal enable_req, readEnable_req, busy_res: std_logic;
    signal addr_req: std_logic_vector(AddrWidth);
    signal writeData_req: std_logic_vector(DataWidth);
    signal readDataBurst_res: BurstDataType;
    signal byteSelect_req: std_logic_vector(3 downto 0);
    type State is (INIT, PROC, WAIT1, WAIT2);
    signal stat100, stat25: State;

begin

    process (clk_100) begin
        if (rising_edge(clk_100)) then
            if (rst_100 = RST_ENABLE) then
                enable_o <= DISABLE;
                readEnable_o <= ENABLE;
                addr_o <= (others => '0');
                writeData_o <= (others => '0');
                byteSelect_o <= (others => '0');
                busy_res <= PIPELINE_STOP;
                readDataBurst_res <= (others => (others => '0'));
                stat100 <= INIT;
            else
                if (stat100 = INIT and enable_req = ENABLE) then
                    enable_o <= ENABLE;
                    readEnable_o <= readEnable_req;
                    addr_o <= addr_req;
                    writeData_o <= writeData_req;
                    byteSelect_o <= byteSelect_req;
                    stat100 <= PROC;
                elsif (stat100 = PROC and busy_i = PIPELINE_NONSTOP) then
                    enable_o <= DISABLE;
                    readDataBurst_res <= readDataBurst_i;
                    busy_res <= PIPELINE_NONSTOP;
                    stat100 <= WAIT1;
                elsif (stat100 = WAIT1 and enable_req = DISABLE) then
                    busy_res <= PIPELINE_STOP;
                    readDataBurst_res <= (others => (others => '0'));
                    stat100 <= INIT;
                end if;
            end if;
        end if;
    end process;

    process(clk_25) begin
        if (rising_edge(clk_25)) then
            if (rst_25 = RST_ENABLE) then
                busy_o <= PIPELINE_STOP;
                readDataBurst_o <= (others => (others => '0'));
                enable_req <= DISABLE;
                readEnable_req <= ENABLE;
                addr_req <= (others => '0');
                writeData_req <= (others => '0');
                byteSelect_req <= (others => '0');
                stat25 <= INIT;
            else
                if (stat25 = INIT and enable_i = ENABLE) then
                    enable_req <= ENABLE;
                    readEnable_req <= readEnable_i;
                    addr_req <= addr_i;
                    writeData_req <= writeData_i;
                    byteSelect_req <= byteSelect_i;
                    stat25 <= PROC;
                elsif (stat25 = PROC and busy_res = PIPELINE_NONSTOP) then
                    stat25 <= WAIT1; -- We use 2 period WAIT to meet the timing requirement
                elsif (stat25 = WAIT1) then
                    enable_req <= DISABLE;
                    if (enable_i = enable_req and readEnable_i = readEnable_req and addr_i = addr_req and (readEnable_i = ENABLE or writeData_i = writeData_req)) then
                        readDataBurst_o <= readDataBurst_res;
                        busy_o <= DISABLE;
                        stat25 <= WAIT2;
                    else
                        stat25 <= INIT;
                    end if;
                elsif (stat25 = WAIT2) then
                    busy_o <= PIPELINE_STOP;
                    readDataBurst_o <= (others => (others => '0'));
                    stat25 <= INIT;
                end if;
            end if;
        end if;
    end process;

end bhv;
