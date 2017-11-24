library ieee;
use ieee.std_logic_1164.all;
use work.global.all;

entity usb_ctrl is
    port (
        clk, rst: std_logic;

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
    signal weLatch, rdLatch: std_logic;
    signal readData: std_logic_vector(7 downto 0);
begin

    usbA0_o <= addr_i(2);
    usbRst_o <= not rst;
    usbCS_o <= not devEnable_i;
    usbWE_o <= (not devEnable_i) and (not writeEnable_i) and weLatch;
    usbRD_o <= (not devEnable_i) and (not readEnable_i) and rdLatch;
    usbData_io <= writeData_i(7 downto 0);
    int_o <= usbInt_i;
    usbDACK_o <= '1';

    readData_o <= 24ux"0" & readData;

    process (clk)
        variable state: integer := 0;
    begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE or devEnable_i = DISABLE) then
                state := 0;
                busy_o <= '0';
                readData <= (others => '0');
            else
                if (state = 4) then
                    state := 0;
                    busy_o <= '0';
                    if (readEnable_i = ENABLE) then
                        readData <= usbData_io;
                    end if;
                else
                    if (state = 0) then
                        busy_o <= '1';
                    end if;
                    state := state + 1;
                end if;
            end if;
        end if;
    end process;

    process (clk)
        variable state: integer := 0;
    begin
        if (falling_edge(clk)) then
            if (rst = RST_ENABLE or devEnable_i = DISABLE) then
                state := 0;
                weLatch <= '0';
                rdLatch <= '0';
            else
                state := state + 1;
                if (state = 1) then
                    weLatch <= '1';
                    rdLatch <= '1';
                elsif (state = 4) then
                    weLatch <= '0';
                end if;
            end if;
        end if;
    end process;

end bhv;