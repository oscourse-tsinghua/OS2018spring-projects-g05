library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

entity boot_ctrl is
    port (
        addr_i: in std_logic_vector(AddrWidth);
        readData_o: out std_logic_vector(DataWidth)
    );
end boot_ctrl;

architecture bhv of boot_ctrl is
    signal addr: std_logic_vector(6 downto 0);
begin
    addr <= addr_i(8 downto 2);

    with addr select readData_o <=
{% for sa, sd in table.items() %}       "{{ sd }}" when "{{ sa }}",
{% endfor %}       "00000000000000000000000000000000" when others;
end bhv;
