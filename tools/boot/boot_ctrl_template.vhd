library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.bus_const.all;

entity boot_ctrl is
    port (
        cpu_i: in BusC2D;
        cpu_o: out BusD2C
    );
end boot_ctrl;

architecture bhv of boot_ctrl is
    signal addr: std_logic_vector(6 downto 0);
begin
    addr <= cpu_i.addr(8 downto 2);

    cpu_o.busy <= PIPELINE_NONSTOP;
    with addr select cpu_o.dataLoad <=
{% for sa, sd in table.items() %}       "{{ sd }}" when "{{ sa }}",
{% endfor %}       "00000000000000000000000000000000" when others;
end bhv;
