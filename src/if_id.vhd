library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

entity if_id is
    port (
        rst, clk: in std_logic;
        pc_i: in std_logic_vector(AddrWidth);
        inst_i: in std_logic_vector(InstWidth);
        pc_o: out std_logic_vector(AddrWidth);
        inst_o: out std_logic_vector(InstWidth)
    );
end if_id;

architecture bhv of if_id is
begin
    process(clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                pc_o <= (others => '0');
                inst_o <= (others => '0');
            else
                pc_o <= pc_i;
                inst_o <= inst_i;
            end if;
        end if;
    end process;
end bhv;