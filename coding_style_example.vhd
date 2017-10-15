library ieee;
use ieee.std_logic_1164.all;

entity entity_name is
    port (
        rst, clk: in std_logic;
        anInputSignal_i: in std_logic;
        anOutputSignal_o: out std_logic
        -- Please avoid using `buffer`
    );
end entity_name;

architecture bhv of entity_name is
    component sub_component
        generic (
        );
        port (
        );
    end component;
    type ATypeName is (
        ENUM1, ENUM2
    );
    signal anOutputSignal: std_logic;
    constant A_CONST: integer := 0;
begin
    process
        variable aLocalVar: std_logic;
    begin
    end process;

    process (clk) begin
        if (rising_edge(clk)) then
            anOutputSignal <= not anOutputSignal;
        end if;
    end process;

    anOutputSignal_o <= anOutputSignal;

    sub_component_inst1: sub_component
        generic map (
        )
        port map (
        );

    gen_something: for i in 0 to 19 generate
    end generate;

end bhv;
