library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

entity sram_ctrl is
    port (
        clk, rst: in std_logic;

        enable_i, readEnable_i: in std_logic; -- read enable means write disable
        addr_i: in std_logic_vector(AddrWidth);
        byteSelect_i: in std_logic_vector(3 downto 0);
        dataSave_i: in std_logic_vector(DataWidth);
        dataLoad_o: out std_logic_vector(DataWidth);
        busy_o: out std_logic;

        data_io: inout std_logic_vector(DataWidth);
        addr_o: out std_logic_vector(19 downto 0);
        be_n_o: out std_logic_vector(3 downto 0);
        ce_n_o, oe_n_o, we_n_o: out std_logic
    );
end sram_ctrl;

architecture bhv of sram_ctrl is
    type State is (READ, WRITE);
    signal stat: State;
begin
    data_io <= dataSave_i when stat = WRITE else (others => 'Z');
    addr_o <= addr_i(19 downto 0);
    be_n_o <= not byteSelect_i;
    ce_n_o <= not enable_i;
    oe_n_o <= '0'; -- WE will disable OE
    we_n_o <= '0' when stat = WRITE and clk = '1' else '1';

    dataLoad_o <= data_io; -- When it's not reading, returning whatever is OK
    busy_o <= YES when stat = READ and readEnable_i = DISABLE else NO;

    process (clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_DISABLE and stat = READ and readEnable_i = DISABLE) then
                stat <= WRITE;
            else
                stat <= READ;
            end if;
        end if;
    end process;
end bhv;
