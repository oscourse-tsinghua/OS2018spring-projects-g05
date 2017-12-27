library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

entity eth_ctrl is
    port (
        clk, rst: in std_logic;
        enable_i, readEnable_i: in std_logic; -- read enable means write disable
        addr_i: in std_logic_vector(AddrWidth);
        writeBusy_o: out std_logic;
        int_o: out std_logic;
        triStateWrite_o: out std_logic;

        ethInt_i: in std_logic;
        ethCmd_o, ethWE_o, ethRD_o, ethCS_o, ethRst_o: out std_logic
    );
end eth_ctrl;

architecture bhv of eth_ctrl is
    type StateType is (READ, WRITE);
    signal state: StateType;
begin
    triStateWrite_o <= '1' when state = WRITE else '0';

    int_o <= ethInt_i;
    ethCmd_o <= addr_i(2);
    ethWE_o <= '0' when state = WRITE and clk = '1' else '1';
    ethRD_o <= not readEnable_i;
    ethCS_o <= not enable_i;
    ethRst_o <= not rst;

    writeBusy_o <= PIPELINE_STOP when state = READ and readEnable_i = DISABLE else PIPELINE_NONSTOP;

    process (clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_DISABLE and state = READ and readEnable_i = DISABLE) then
                state <= WRITE;
            else
                state <= READ;
            end if;
        end if;
    end process;

end bhv;
