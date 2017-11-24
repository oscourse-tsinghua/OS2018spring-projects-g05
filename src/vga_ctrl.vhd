library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.global_const.all;

entity vga_ctrl is
    port (
        clk, rst: in std_logic;
        devEnable_i: in std_logic;
        addr_i: in std_logic_vector(AddrWidth);
        writeEnable_i: in std_logic;
        writeData_i: in std_logic_vector(DataWidth);
        writeByteSelect_i: in std_logic_vector(3 downto 0);

        -- Signals connecting to vga --
        de_o: out std_logic;
        rgb_o: out std_logic_vector(7 downto 0);
        hs_o, vs_o: out std_logic
    );
end vga_ctrl;

architecture bhv of vga_ctrl is
    signal dout: std_logic_vector(7 downto 0);
    signal writeByte: std_logic_vector(7 downto 0);
    signal pixelAddr, nextPixelAddr: std_logic_vector(18 downto 0);
    signal x, nx: std_logic_vector(9 downto 0);
    signal y, ny: std_logic_vector(8 downto 0);
begin

    process (writeData_i, writeByteSelect_i) begin
        if (writeByteSelect_i(3) = '1') then
            writeByte <= writeData_i(31 downto 24);
        elsif (writeByteSelect_i(2) = '1') then
            writeByte <= writeData_i(23 downto 16);
        elsif (writeByteSelect_i(1) = '1') then
            writeByte <= writeData_i(15 downto 8);
        elsif (writeByteSelect_i(0) = '1') then
            writeByte <= writeData_i(7 downto 0);
        else
            writeByte <= (others => '0');
        end if;
    end process;

    vga_ram_ist: entity work.vga_ram
        port map(
            clka => clk,
            ena => devEnable_i and writeEnable_i,
            wea(0) => writeEnable_i,
            dina => writeByte,
            addra => addr_i(18 downto 0),
            clkb => clk,
            enb => devEnable_i,
            doutb => dout,
            addrb => nextPixelAddr
        );

    process (clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                x <= (others => '0');
                y <= (others => '0');
                nx <= (0 => '1', others => '0');
                ny <= (others => '0');
                pixelAddr <= (others => '0');
                nextPixelAddr <= (0 => '1', others => '0');
            else
                x <= nx;
                y <= ny;
                pixelAddr <= nextPixelAddr;

                if (nx < 640 and ny < 480) then
                    if (nextPixelAddr = 307199) then
                        nextPixelAddr <= (others => '0');
                    else
                        nextPixelAddr <= nextPixelAddr + 1;
                    end if;
                end if;

                if (nx = 799) then
                    nx <= (others => '0');
                    if (ny = 524) then
                        ny <= (others => '0');
                    else
                        ny <= ny + 1;
                    end if;
                else
                    nx <= nx + 1;
                end if;
            end if;
        end if;
    end process;

    process (x, y, dout) begin
        if (x >= 640 or y >= 480) then
            rgb_o <= (others => '0');
            de_o <= '0';
        else
            rgb_o <= dout;
            de_o <= '1';
        end if;

        if (x >= 656 and x < 752) then
            hs_o <= '0';
        else
            hs_o <= '1';
        end if;

        if (y >= 490 and y < 492) then
            vs_o <= '0';
        else
            vs_o <= '1';
        end if;
    end process;

end bhv;