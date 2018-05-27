library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

entity serial_ctrl is
    port (
        clk, rst: in std_logic;

        enable_i, readEnable_i: in std_logic; -- read enable means write disable
        mode_i: in std_logic; -- 1 for status (0xBFD003FC), 0 for data (0xBFD003F8)
        dataSave_i: in std_logic_vector(DataWidth);
        dataLoad_o: out std_logic_vector(DataWidth);

        int_o: out std_logic; -- Interruption

        rxdReady_i: in std_logic;
        rxdData_i: in std_logic_vector(7 downto 0); -- rxdReady_i and rxdData_i only hold for 1 period
        txdBusy_i: in std_logic;
        txdStart_o: out std_logic;
        txdData_o: out std_logic_vector(7 downto 0)
    );
end serial_ctrl;

architecture bhv of serial_ctrl is
    signal recvAvail: std_logic;
    signal recvData: std_logic_vector(7 downto 0);
    signal txIRE, rxIRE: std_logic; -- Interrupt Enable
    constant TX_READY: integer := 0;
    constant RX_READY: integer := 1;
    constant TX_IRE: integer := 2;
    constant RX_IRE: integer := 3;
begin
    dataLoad_o <= (
            TX_READY => not txdBusy_i,
            RX_READY => rxdReady_i or recvAvail,
            TX_IRE => txIRE,
            RX_IRE => rxIRE,
            others => '0'
        ) when mode_i = '1' else
            24ux"0" & rxdData_i when rxdReady_i = '1' else 24ux"0" & recvData;
    -- When recvAvail = NO or chip disabled, outputting whatever is OK

    int_o <= ((rxdReady_i or recvAvail) and rxIRE) or (not txdBusy_i and txIRE);

    process (clk) begin
        if (rising_edge(clk)) then
            txdStart_o <= '0';
            txdData_o <= (others => '0');
            if (rst = RST_ENABLE) then
                recvAvail <= NO;
                recvData <= (others => '0');
                txIRE <= NO;
                rxIRE <= YES;
            else
                if (rxdReady_i = '1') then
                    recvAvail <= YES;
                    recvData <= rxdData_i;
                end if;
                if (enable_i = ENABLE and readEnable_i = ENABLE and mode_i = '0') then
                    recvAvail <= NO;
                    recvData <= (others => '0');
                end if;

                if (enable_i = ENABLE and readEnable_i = DISABLE) then
                    if (mode_i = '1') then
                        txIRE <= dataSave_i(TX_IRE);
                        rxIRE <= dataSave_i(RX_IRE);
                    elsif (txdBusy_i = '0') then -- mode_i = '0'
                        -- If busy, ignore it
                        txdStart_o <= '1';
                        txdData_o <= dataSave_i(7 downto 0);
                    end if;
                end if;
            end if;
        end if;
    end process;
end bhv;

