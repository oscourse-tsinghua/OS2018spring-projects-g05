library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.flash_const.all;

entity flash_ctrl is
    port (
        clk, rst: in std_logic;
        cyc_i, stb_i: in std_logic;
        addr_i: in std_logic_vector(FlashCtrlAddrWidth);
        writeEnable_i: in std_logic;
        writeData_i: in std_logic_vector(DataWidth);
        byteSelect_i: in std_logic_vector(3 downto 0);
        readEnable_i: in std_logic;
        readData_o: out std_logic_vector(DataWidth);
        ack_o: out std_logic;

        flRst_o, flOE_o, flCE_o, flWE_o: out std_logic;
        flAddr_o: out std_logic_vector(FlashAddrWidth);
        flData_i: in std_logic_vector(FlashDataWidth);
        flByte_o, flVpen_o: out std_logic
    );
end flash_ctrl;

architecture bhv of flash_ctrl is
    signal devEnable: std_logic;
    signal data: std_logic_vector(DataWidth);
begin

    devEnable <= cyc_i and stb_i;
    flRst_o <= not rst;
    flCE_o <= not devEnable;
    flOE_o <= not (devEnable and readEnable_i);
    flWE_o <= '1';
    flByte_o <= '1';
    flVpen_o <= '0';

    process(clk)
        variable state: integer := 0;
    begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE or devEnable = DISABLE) then
                data <= (others => '0');
                ack_o <= '0';
                readData_o <= (others => '0');
                state := 0;
            else
                case (state) is
                    when 0 =>
                        flAddr_o <= addr_i & "00";
                    when CLKS_TO_GET_DATA =>
                        data(FlashDataHiWidth) <= flData_i;
                        flAddr_o <= addr_i & "10";
                    when CLKS_TO_GET_DATA * 2 =>
                        data(FlashDataLoWidth) <= flData_i;
                        readData_o <= data;
                        ack_o <= '1';
                    when others =>
                end case;
                if (state = CLKS_TO_GET_DATA * 2) then
                    state := 0;
                else
                    state := state + 1;
                end if;
            end if;
        end if;
    end process;

end bhv;