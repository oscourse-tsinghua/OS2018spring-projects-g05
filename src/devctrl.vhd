library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.global_const.all;
use work.bus_const.all;

entity devctrl is
    port (
        clk, rst: in std_logic;

        cpu1Inst_io, cpu1Data_io: inout BusInterface;
        ddr3_io, flash_io, serial_io, boot_io, eth_io, led_io, num_io: inout BusInterface;

        -- for sync --
        sync_i: in std_logic_vector(2 downto 0);
        scCorrect_o: out std_logic
    );
end devctrl;

architecture bhv of devctrl is
    procedure connect(
        constant lo, hi: in std_logic_vector(AddrWidth); -- Inclusive
        signal cpu, dev: inout BusInterface
    ) is begin
        dev.addr_c2d <= cpu.addr_c2d;
        dev.byteSelect_c2d <= cpu.byteSelect_c2d;
        dev.dataSave_c2d <= cpu.dataSave_c2d;
        if (cpu.enable_c2d = ENABLE and cpu.addr_c2d >= lo and cpu.addr_c2d <= hi) then
            dev.enable_c2d <= ENABLE;
            dev.write_c2d <= cpu.write_c2d;
            cpu.dataLoad_d2c <= dev.dataLoad_d2c;
            cpu.busy_d2c <= dev.busy_d2c;
        else
            dev.enable_c2d <= DISABLE;
            dev.write_c2d <= NO;
        end if;
    end procedure connect;

    signal conn: BusInterface;
    signal llBit: std_logic;
    signal llLoc: std_logic_vector(AddrWidth);
begin
    process (all) begin
        cpu1Data_io.busy_d2c <= PIPELINE_NONSTOP;
        cpu1Data_io.dataLoad_d2c <= (others => 'X');
        cpu1Inst_io.busy_d2c <= PIPELINE_NONSTOP;
        cpu1Inst_io.dataLoad_d2c <= (others => 'X');
        if (cpu1Data_io.enable_c2d = ENABLE) then
            cpu1Inst_io.busy_d2c <= PIPELINE_STOP;
            connect(x"00000000", x"ffffffff", cpu1Data_io, conn);
        else
            connect(x"00000000", x"ffffffff", cpu1Inst_io, conn);
        end if;
    end process;

    process (all) begin
        conn.busy_d2c <= PIPELINE_NONSTOP;
        conn.dataLoad_d2c <= (others => 'X');
        connect(x"00000000", x"07ffffff", conn, ddr3_io);
        connect(x"1e000000", x"1effffff", conn, flash_io);
        connect(x"1fc00000", x"1fc00fff", conn, boot_io);
        connect(x"1fd003f8", x"1fd003fc", conn, serial_io);
        connect(x"1fd0f000", x"1fd0f000", conn, led_io);
        connect(x"1fd0f010", x"1fd0f010", conn, num_io);
        connect(x"1c030000", x"1c03ffff", conn, eth_io);
    end process;

    scCorrect_o <= llBit when conn.addr_c2d = llLoc else '0';

    process(clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                llBit <= '0';
                llLoc <= (others => 'X');
            else
                -- see page 347 in document MD00086(Volume II-A revision 6.06)
                if (conn.busy_d2c = PIPELINE_NONSTOP) then
                    if (sync_i(0) = '1') then -- LL
                        llBit <= '1';
                        llLoc <= conn.addr_c2d;
                    elsif (sync_i(1) = '1') then -- SC
                        llBit <= '0';
                    elsif (conn.addr_c2d = llLoc) then -- Others
                        llBit <= '0';
                    end if;
                end if;
                if (sync_i(2) = '1') then -- Flush
                    llBit <= '0';
                end if;
            end if;
        end if;
    end process;
end bhv;
