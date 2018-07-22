library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.global_const.all;
use work.bus_const.all;

entity devctrl is
    port (
        clk, rst: in std_logic;

        cpu1Inst_i, cpu1Data_i, cpu2Inst_i, cpu2Data_i: in BusC2D;
        cpu1Inst_o, cpu1Data_o, cpu2Inst_o, cpu2Data_o: out BusD2C;
        ddr3_i, flash_i, serial_i, boot_i, eth_i, led_i, num_i, ipi_i: in BusD2C;
        ddr3_o, flash_o, serial_o, boot_o, eth_o, led_o, num_o, ipi_o: out BusC2D;

        -- Bus monitoring
        busMon_o: out BusC2D;
        llBit_o: out std_logic;
        llLoc_o: out std_logic_vector(AddrWidth);

        -- for sync --
        sync1_i, sync2_i: in std_logic_vector(2 downto 0);
        scCorrect1_o, scCorrect2_o: out std_logic
    );
end devctrl;

architecture bhv of devctrl is
    signal cpu1_c2d, cpu2_c2d, conn_c2d: BusC2D;
    signal cpu1_d2c, cpu2_d2c, conn_d2c: BusD2C;
    signal priority, curCPU: std_logic;
    signal sync: std_logic_vector(2 downto 0);
    signal scCorrect: std_logic;
    signal llBit, llCPU: std_logic;
    signal llLoc: std_logic_vector(AddrWidth);

    procedure connectRange(
        constant lo, hi: in std_logic_vector(AddrWidth); -- Inclusive
        signal cpu_i: in BusC2D;
        signal cpu_o: out BusD2C;
        signal dev_i: in BusD2C;
        signal dev_o: out BusC2D
    ) is begin
        dev_o.addr <= cpu_i.addr;
        dev_o.byteSelect <= cpu_i.byteSelect;
        dev_o.dataSave <= cpu_i.dataSave;
        if (cpu_i.enable = ENABLE and cpu_i.addr >= lo and cpu_i.addr <= hi) then
            dev_o.enable <= ENABLE;
            dev_o.write <= cpu_i.write;
            cpu_o.dataLoad <= dev_i.dataLoad;
            cpu_o.busy <= dev_i.busy;
        else
            dev_o.enable <= DISABLE;
            dev_o.write <= NO;
        end if;
    end procedure connectRange;

    procedure connect(
        signal cpu_i: in BusC2D;
        signal cpu_o: out BusD2C;
        signal dev_i: in BusD2C;
        signal dev_o: out BusC2D
    ) is begin
        dev_o.addr <= cpu_i.addr;
        dev_o.byteSelect <= cpu_i.byteSelect;
        dev_o.dataSave <= cpu_i.dataSave;
        dev_o.enable <= cpu_i.enable;
        dev_o.write <= cpu_i.write;
        cpu_o.dataLoad <= dev_i.dataLoad;
        cpu_o.busy <= dev_i.busy;
    end procedure connect;

    procedure emptyCPU(signal cpu_o: out BusD2C) is begin
        cpu_o.dataLoad <= (others => 'X');
        cpu_o.busy <= PIPELINE_NONSTOP;
    end procedure emptyCPU;

    procedure disableDev(signal dev_o: out BusC2D) is begin
        dev_o.enable <= DISABLE;
        dev_o.write <= NO;
        dev_o.addr <= (others => 'X');
        dev_o.byteSelect <= (others => 'X');
        dev_o.dataSave <= (others => 'X');
    end procedure disableDev;

    procedure mergeIfMem(
        signal inst_i, data_i: in BusC2D;
        signal inst_o, data_o: out BusD2C;
        signal cpu_i: in BusD2C;
        signal cpu_o: out BusC2D
    ) is begin
        data_o.busy <= PIPELINE_NONSTOP;
        data_o.dataLoad <= (others => 'X');
        inst_o.busy <= PIPELINE_NONSTOP;
        inst_o.dataLoad <= (others => 'X');
        if (data_i.enable = ENABLE) then
            inst_o.busy <= PIPELINE_STOP;
            connect(data_i, data_o, cpu_i, cpu_o);
        else
            connect(inst_i, inst_o, cpu_i, cpu_o);
        end if;
    end procedure mergeIfMem;
begin
    process (clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                priority <= CPU1_ID;
            else
                if (conn_c2d.enable = ENABLE and conn_d2c.busy = PIPELINE_STOP) then
                    priority <= curCPU;
                else
                    priority <= not priority;
                end if;
            end if;
        end if;
    end process;

    process (all) begin
        mergeIfMem(cpu1Inst_i, cpu1Data_i, cpu1Inst_o, cpu1Data_o, cpu1_d2c, cpu1_c2d);
    end process;

    process (all) begin
        mergeIfMem(cpu2Inst_i, cpu2Data_i, cpu2Inst_o, cpu2Data_o, cpu2_d2c, cpu2_c2d);
    end process;

    process (all) begin
        cpu1_d2c.busy <= cpu1_c2d.enable;
        cpu2_d2c.busy <= cpu2_c2d.enable;
        cpu1_d2c.dataLoad <= (others => 'X');
        cpu2_d2c.dataLoad <= (others => 'X');
        scCorrect1_o <= '0';
        scCorrect2_o <= '0';
        disableDev(conn_c2d);
        if (cpu1_c2d.enable = ENABLE and (cpu2_c2d.enable = DISABLE or priority = CPU1_ID)) then
            curCPU <= CPU1_ID;
            if (sync1_i(1) = '0' or scCorrect = '1') then
                connect(cpu1_c2d, cpu1_d2c, conn_d2c, conn_c2d);
            else
                emptyCPU(cpu1_d2c);
            end if;
            sync <= sync1_i;
            scCorrect1_o <= scCorrect;
        else
            curCPU <= CPU2_ID;
            if (sync2_i(1) = '0' or scCorrect = '1') then
                connect(cpu2_c2d, cpu2_d2c, conn_d2c, conn_c2d);
            else
                emptyCPU(cpu2_d2c);
            end if;
            sync <= sync2_i;
            scCorrect2_o <= scCorrect;
        end if;
    end process;
    busMon_o <= conn_c2d;

    process (all) begin
        conn_d2c.busy <= PIPELINE_NONSTOP;
        conn_d2c.dataLoad <= (others => 'X');
        connectRange(x"00000000", x"07ffffff", conn_c2d, conn_d2c, ddr3_i, ddr3_o);
        connectRange(x"1e000000", x"1effffff", conn_c2d, conn_d2c, flash_i, flash_o);
        connectRange(x"1fc00000", x"1fc00fff", conn_c2d, conn_d2c, boot_i, boot_o);
        connectRange(x"1fd003f8", x"1fd003fc", conn_c2d, conn_d2c, serial_i, serial_o);
        connectRange(x"1fd0f000", x"1fd0f000", conn_c2d, conn_d2c, led_i, led_o);
        connectRange(x"1fd0f010", x"1fd0f010", conn_c2d, conn_d2c, num_i, num_o);
        connectRange(x"1c030000", x"1c03ffff", conn_c2d, conn_d2c, eth_i, eth_o);
        connectRange(x"1ff01000", x"1ff0103f", conn_c2d, conn_d2c, ipi_i, ipi_o);
    end process;

    scCorrect <= llBit when conn_c2d.addr = llLoc and curCPU = llCPU else '0';

    process(clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                llBit <= '0';
                llLoc <= (others => 'X');
            else
                -- see page 347 in document MD00086(Volume II-A revision 6.06)
                if (conn_d2c.busy = PIPELINE_NONSTOP) then
                    if (sync(0) = '1') then -- LL
                        llBit <= '1';
                        llLoc <= conn_c2d.addr;
                        llCPU <= curCPU;
                    elsif (sync(1) = '1') then -- SC
                        llBit <= '0';
                    elsif (conn_c2d.addr = llLoc) then -- Others
                        llBit <= '0';
                    end if;
                end if;
                if (sync(2) = '1') then -- Flush
                    llBit <= '0';
                end if;
            end if;
        end if;
    end process;
    llBit_o <= llBit;
    llLoc_o <= llLoc;
end bhv;
