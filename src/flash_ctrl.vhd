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
    signal state: std_logic_vector(5 downto 0);
    signal cmdAndAddr: std_logic_vector(0 to 31); -- Output from high to low
    signal data: std_logic_vector(0 to 31); -- Input from high to low
begin

    clk_o <= clk;
    cs_n_o <= not devEnable_i;
    busy_o <= '0' when state = "111111" else '1';
    readData_o <= data;
    cmdAndAddr <= CMD_READ & addr_i(23 downto 0);

    process (clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE or devEnable_i = DISABLE) then
                state <= (others => '0');
                data <= (others => '0');
            else
                if (state(5) = '0') then
                    di_o <= cmdAndAddr(conv_integer(state));
                else
                    data(conv_integer(state)) <= do_i;
                end if;
                state <= state + 1;
            end if;
        end if;
    end process;

end bhv;
