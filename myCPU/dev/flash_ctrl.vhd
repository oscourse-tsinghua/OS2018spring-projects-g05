library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.global_const.all;
use work.bus_const.all;

entity flash_ctrl is
    port (
        clk, rst: in std_logic;

        cpu_i: in BusC2D;
        cpu_o: out BusD2C;

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
        cpu_i.enable = DISABLE or
        state = "0000000" or -- Not started yet
        state = "1000001" -- Done
        else ENABLE;
    cs_n_o <= not chipEnable;
    clk_o <= clk or not chipEnable; -- Pull up clock when disable, which guarentees
                                    -- the first rising edge comes after enabling
    cpu_o.busy <= PIPELINE_NONSTOP when state = "1000001" else PIPELINE_STOP;

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
    cpu_o.dataLoad <= rxd(7 downto 0) & rxd(15 downto 8) & rxd(23 downto 16) & rxd(31 downto 24);

    process (clk) begin -- Controller
        if (rising_edge(clk)) then
            txdHold <= (others => '0');
            txdStart <= NO;
            state <= "0000000";
            if (rst = RST_DISABLE and cpu_i.enable = ENABLE) then
                if (state = "0000000") then
                    txdHold <= CMD_READ & cpu_i.addr(23 downto 0);
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
