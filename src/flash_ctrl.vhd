library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.global_const.all;

entity flash_ctrl is
    port (
        clk, rst: in std_logic;
        devEnable_i: in std_logic;
        addr_i: in std_logic_vector(AddrWidth);
        readData_o: out std_logic_vector(DataWidth);
        busy_o: out std_logic;

        clk_o, cs_n_o, di_o: out std_logic;
        do_i: in std_logic
    );
end flash_ctrl;

architecture bhv of flash_ctrl is
    constant CMD_READ: std_logic_vector(7 downto 0) := x"03";
    signal chipEnable: std_logic;
    signal txd, txdHold, rxd: std_logic_vector(DataWidth);
    signal txdStart: std_logic;
    signal state: std_logic_vector(6 downto 0);
begin

    chipEnable <= DISABLE when
        rst = RST_ENABLE or
        devEnable_i = DISABLE or
        state = "0000000" or -- Not started yet
        state = "1000001" -- Done
        else ENABLE;
    cs_n_o <= not chipEnable;
    clk_o <= clk or not chipEnable; -- Pull up clock when disable, which guarentees
                                    -- the first rising edge comes after enabling
    busy_o <= PIPELINE_NONSTOP when state = "1000001" else PIPELINE_STOP;

    process (clk) begin -- Transmitter
        if (falling_edge(clk)) then
            if (txdStart = YES) then
                txd <= txdHold;
            else
                txd <= txd(30 downto 0) & '0';
            end if;
        end if;
    end process;
    di_o <= txd(31);

    process (clk) begin -- Receiver
        if (rising_edge(clk)) then
            rxd <= rxd(30 downto 0) & do_i;
        end if;
    end process;
    readData_o <= rxd(7 downto 0) & rxd(15 downto 8) & rxd(23 downto 16) & rxd(31 downto 24);

    process (clk) begin -- Controller
        if (rising_edge(clk)) then
            txdHold <= (others => '0');
            txdStart <= NO;
            state <= "0000000";
            if (rst = RST_DISABLE and devEnable_i = ENABLE) then
                if (state = "0000000") then
                    txdHold <= CMD_READ & addr_i(23 downto 0);
                    txdStart <= YES;
                end if;
                if (state = "1000001") then
                    state <= "0000000";
                else
                    state <= state + 1;
                end if;
            end if;
        end if;
    end process;

end bhv;
