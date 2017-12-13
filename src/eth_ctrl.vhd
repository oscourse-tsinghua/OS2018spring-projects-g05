library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

entity eth_ctrl is
    port (
        clk, rst: in std_logic;
        enable_i, readEnable_i: in std_logic; -- read enable means write disable
        writeData_i: in std_logic_vector(DataWidth);
        readData_o: out std_logic_vector(DataWidth);
        addr_i: in std_logic_vector(AddrWidth);
        byteSelect_i: in std_logic_vector(3 downto 0);
        writeBusy_o: out std_logic;
        int_o: out std_logic;

        ethInt_i: in std_logic;
        ethCmd_o, ethWE_o, ethRD_o, ethCS_o, ethRst_o: out std_logic;
        ethData_io: inout std_logic_vector(15 downto 0)
    );
end eth_ctrl;

architecture bhv of eth_ctrl is
    type StateType is (INIT, GET);
    signal state: StateType;
    signal latch: std_logic;
begin
    int_o <= ethInt_i;
    ethWE_o <= not (enable_i and (not readEnable_i) and latch);
    ethRD_o <= not (enable_i and readEnable_i);
    ethCS_o <= not enable_i;
    ethRst_o <= not rst;

    readData_o <= ethData_io when enable_i and readEnable_i else (others => '0');
    ethData_io <= writeData_i;

    writeBusy_o <= '0' when state = GET else '1';

    process (clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE or enable_i = DISABLE or readEnable_i = ENABLE) then
                state <= INIT;
            else
                if (state = INIT) then
                    state <= GET;
                else
                    state <= INIT;
                end if;
            end if;
        end if;
    end process;

    process(clk) begin
        if (falling_edge(clk)) then
            if (state = GET) then
                latch <= '1';
            else
                latch <= '0';
            end if;
        end if;
    end process;

end bhv;