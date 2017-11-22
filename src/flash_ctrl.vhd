library ieee;
use ieee.std_logic_1164.all;
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
begin

    flRst_o <= not rst;
    flCE_o <= not devEnable_i;
    flOE_o <= not (devEnable_i and readEnable_i);
    flWE_o <= '1';
    flByte_o <= '1';
    flVpen_o <= '1';

    process(clk)
        variable state: integer := 0;
    begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE or devEnable_i = DISABLE) then
                readData_o <= (others => '0');
                busy_o <= '0';
                state := 0;
            else
                case (state) is
                    when 0 =>
                        flAddr_o <= addr_i(FlashAddrSliceWidth) & '0';
                        busy_o <= '1';
                    when CLKS_TO_GET_DATA =>
                        readData_o <= ZEROS16 & flData_i;
                        busy_o <= '0';
                    when others =>
                end case;
                if (state = CLKS_TO_GET_DATA) then
                    state := 0;
                else
                    state := state + 1;
                end if;
            end if;
        end if;
    end process;

end bhv;