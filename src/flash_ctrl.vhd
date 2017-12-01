library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.global_const.all;
use work.flash_const.all;

entity flash_ctrl is
    port (
        clk, rst: in std_logic;
        devEnable_i: in std_logic;
        addr_i: in std_logic_vector(AddrWidth);
        readEnable_i: in std_logic;
        readData_o: out std_logic_vector(DataWidth);
        busy_o: out std_logic;

        flRst_o, flOE_o, flCE_o, flWE_o: out std_logic;
        flAddr_o: out std_logic_vector(FlashAddrWidth);
        flData_i: in std_logic_vector(FlashDataWidth);
        flByte_o, flVpen_o: out std_logic
    );
end flash_ctrl;

architecture bhv of flash_ctrl is
    signal state: std_logic_vector(2 downto 0);
begin

    flRst_o <= not rst;
    flCE_o <= not devEnable_i;
    flOE_o <= not (devEnable_i and readEnable_i);
    flWE_o <= '1';
    flByte_o <= '1';
    flVpen_o <= '1';
    busy_o <= '0' when state = CLKS_TO_GET_DATA else '1';
    readData_o <= 16ux"0" & flData_i;
    flAddr_o <= addr_i(FlashAddrSliceWidth) & '0';

    process(clk)
    begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE or devEnable_i = DISABLE) then
                state <= (others => '0');
            else
                if (conv_integer(state) = CLKS_TO_GET_DATA) then
                    state <= (others => '0');
                else
                    state <= state + 1;
                end if;
            end if;
        end if;
    end process;

end bhv;
