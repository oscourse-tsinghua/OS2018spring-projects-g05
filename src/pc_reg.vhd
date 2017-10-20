library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.global_const.all;
use work.inst_const.all;

entity pc_reg is
    port (
        rst, clk: in std_logic;
        pc_o: out std_logic_vector(AddrWidth);
        pcEnable_o: out std_logic
    );
end pc_reg;

architecture bhv of pc_reg is
    signal pc: std_logic_vector(AddrWidth);
begin
    process(clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                pcEnable_o <= DISABLE;
                pc <= (others => '0');
            else
                pcEnable_o <= ENABLE;
                pc <= pc + 4;
            end if;
        end if;
    end process;

    pc_o <= pc;
end bhv;