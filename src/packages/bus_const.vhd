library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package bus_const is
    type BusInterface is record
        -- We use `_c2d` for signals flows from CPU to devices,
        -- and `_d2c` for signals flows from devices to CPU
        enable_c2d, write_c2d: std_logic;
        addr_c2d: std_logic_vector(AddrWidth);
        byteSelect_c2d: std_logic_vector(3 downto 0);
        dataSave_c2d: std_logic_vector(DataWidth);
        dataLoad_d2c: std_logic_vector(DataWidth);
        busy_d2c: std_logic;
    end record;
end bus_const;

