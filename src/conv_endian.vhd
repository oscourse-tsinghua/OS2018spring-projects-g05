library ieee;
use ieee.std_logic_1164.all;

entity conv_endian is
    generic (
        enable: boolean
    );
    port (
        input: in std_logic_vector(31 downto 0);
        output: out std_logic_vector(31 downto 0)
    );
end conv_endian;

architecture bhv of conv_endian is
begin
    process (all) begin
        if (enable) then
            output <= input(7 downto 0) & input(15 downto 8) & input(23 downto 16) & input(31 downto 24);
        else
            output <= input;
        end if;
    end process;
end bhv;
