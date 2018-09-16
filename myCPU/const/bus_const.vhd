library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

package bus_const is
    -- We use `C2D` for signals flows from CPU to devices,
    -- and `D2C` for signals flows from devices to CPU
    type BusC2D is record
        enable, write: std_logic;
        addr: std_logic_vector(AddrWidth);
        byteSelect: std_logic_vector(3 downto 0);
        dataSave: std_logic_vector(DataWidth);
    end record;

    type BusD2C is record
        dataLoad: std_logic_vector(DataWidth);
        busy: std_logic;
    end record;
end bus_const;

