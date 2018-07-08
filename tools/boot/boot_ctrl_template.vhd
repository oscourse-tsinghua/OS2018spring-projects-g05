library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.bus_const.all;

entity boot_ctrl is
    port (
        cpu_io: inout BusInterface
    );
end boot_ctrl;

architecture bhv of boot_ctrl is
    signal addr: std_logic_vector(6 downto 0);
begin
    addr <= cpu_io.addr_c2d(8 downto 2);

    cpu_io.busy_d2c <= PIPELINE_NONSTOP;
    with addr select cpu_io.dataLoad_d2c <=
{% for sa, sd in table.items() %}       "{{ sd }}" when "{{ sa }}",
{% endfor %}       "00000000000000000000000000000000" when others;
end bhv;
