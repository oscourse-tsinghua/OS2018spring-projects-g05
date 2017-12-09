library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

entity lattice_ram_ctrl is
    port (
        clk, rst: in std_logic;

        devEnable_i, readEnable_i: in std_logic;
        addr_i: in std_logic_vector(AddrWidth);
        readData_o: out std_logic_vector(DataWidth);
        busy_o: out std_logic
    );
end lattice_ram_ctrl;

architecture bhv of lattice_ram_ctrl is

    component lattice_ram
        port (
            clka, ena: in std_logic;
            wea: in std_logic_vector(0 downto 0);
            addra: in std_logic_vector(8 downto 0);
            dina: in std_logic_vector(DataWidth);
            douta: out std_logic_vector(DataWidth)
        );
    end component;

    type StateType is (INIT, GET);
    signal state: StateType;

begin

    lattice_ram_ist: lattice_ram
        port map (
            clka => clk,
            ena => devEnable_i,
            wea(0) => '0',
            dina => (others => '0'),
            douta => readData_o,
            addra => addr_i(10 downto 2)
        );

    busy_o <= PIPELINE_NONSTOP when state = GET else PIPELINE_STOP;

    process (clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE or devEnable_i = DISABLE or readEnable_i = DISABLE) then
                state <= INIT;
            else
                case (state) is
                    when INIT =>
                        state <= GET;
                    when GET =>
                        state <= INIT;
                    when others =>
                end case;
            end if;
        end if;
    end process;

end bhv;