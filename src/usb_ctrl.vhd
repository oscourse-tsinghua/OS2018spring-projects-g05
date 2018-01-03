library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.global_const.all;

entity usb_ctrl is
    port (
        clk, rst: in std_logic;

        devEnable_i: in std_logic;
        addr_i: in std_logic_vector(AddrWidth);
        readEnable_i: in std_logic;
        readData_o: out std_logic_vector(DataWidth);
        writeEnable_i: in std_logic;
        writeData_i: in std_logic_vector(DataWidth);
        busy_o: out std_logic;
        int_o: out std_logic;

        usbA0_o, usbWE_o, usbRD_o, usbCS_o, usbRst_o, usbDACK_o: out std_logic;
        usbInt_i: in std_logic;
        usbData_io: inout std_logic_vector(7 downto 0)
    );
end usb_ctrl;

architecture bhv of usb_ctrl is
    signal state: integer;
    signal writeState: std_logic;
    signal readData: std_logic_vector(7 downto 0);
begin

    usbA0_o <= addr_i(2);
    usbRst_o <= not rst;
    usbCS_o <= not devEnable_i;
    writeState <= '1' when (state /= 1) and (state /= 5) else '0';
    usbWE_o <= not (devEnable_i and writeEnable_i and writeState);
    usbRD_o <= not (devEnable_i and readEnable_i);
    usbData_io <= writeData_i(7 downto 0);
    int_o <= usbInt_i;
    usbDACK_o <= '1';

    readData_o <= 24ux"0" & readData;
    busy_o <= PIPELINE_STOP when state /= 5 and devEnable_i = ENABLE else PIPELINE_NONSTOP;

    process(clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE or devEnable_i = DISABLE) then
                state <= 1;
            else
                state <= state + 1;
            end if;
        end if;
    end process;

end bhv;