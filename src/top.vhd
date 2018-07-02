library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.bus_const.all;

entity top is
    generic (
        FUNC_TEST, MONITOR, USE_BOOTLOADER: integer -- Only integer is supported in top level
    );
    port (
        clk_in: in std_logic; -- 100MHz clock input
        rst_n: in std_logic; -- Reset

        led_n: out std_logic_vector(15 downto 0); -- Single color LED
        led_rg0, led_rg1: out std_logic_vector(1 downto 0); -- Dual color LED

        num_cs_n: out std_logic_vector(7 downto 0); -- 7-seg enable
        num_a_g: out std_logic_vector(6 downto 0); -- 7-seg data

        switch: in std_logic_vector(7 downto 0); -- Switches. Push up for 0 and pull down for 1
        btn_key_col, btn_key_row: in std_logic_vector(3 downto 0); -- Keypad
        btn_step: in std_logic_vector(1 downto 0); -- Pulse button

        -- SPI flash EN25F80
        spi_clk: out std_logic; -- clock
        spi_cs_n: out std_logic; -- enable
        spi_di: out std_logic; -- data CPU -> flash
        spi_do: in std_logic; -- data flash -> CPU

        -- Ethernet DM9161AEP
        eth_txclk: in std_logic; -- Transmit reference clock
        eth_rxclk: in std_logic; -- Receive reference clock
        eth_txen: out std_logic; -- Transmit enable
        eth_txd: out std_logic_vector(3 downto 0); -- Transmit data
        eth_txerr: out std_logic; -- Transmit error
        eth_rxdv: in std_logic; -- Receive valid
        eth_rxd: in std_logic_vector(3 downto 0); -- Receive data
        eth_rxerr: in std_logic; -- Receive error
        eth_coll: in std_logic; -- Collision
        eth_crs: in std_logic; -- Carrier sence detect
        eth_mdc: out std_logic; -- Management data clock
        eth_mdio: inout std_logic; -- Management data I/O
        eth_rst_n: out std_logic; -- Reset

        -- UART
        uart_rx: in std_logic; -- Receive
        uart_tx: out std_logic; -- Transmit

        -- DDR3
        ddr3_dq: inout std_logic_vector(15 downto 0);
        ddr3_addr: out std_logic_vector(12 downto 0);
        ddr3_ba: out std_logic_vector(2 downto 0);
        ddr3_ras_n: out std_logic;
        ddr3_cas_n: out std_logic;
        ddr3_we_n: out std_logic;
        ddr3_odt: out std_logic;
        ddr3_reset_n: out std_logic;
        ddr3_cke: out std_logic;
        ddr3_dm: out std_logic_vector(1 downto 0);
        ddr3_dqs_p: inout std_logic_vector(1 downto 0);
        ddr3_dqs_n: inout std_logic_vector(1 downto 0);
        ddr3_ck_p: out std_logic;
        ddr3_ck_n: out std_logic
    );
end top;

architecture bhv of top is
    function getExceptBootBaseAddr return std_logic_vector is begin
        if (FUNC_TEST = 1 or MONITOR = 1) then
            return 32ux"80000000";
        else
            return 32ux"bfc00200";
        end if;
    end getExceptBootBaseAddr;
    function getTlbRefillExl0Offset return std_logic_vector is begin
        if (FUNC_TEST = 1) then
            return 32ux"180";
        elsif (MONITOR = 1) then
            return 32ux"1000";
        else
            return 32ux"000";
        end if;
    end getTlbRefillExl0Offset;
    function getGeneralExceptOffset return std_logic_vector is begin
        if (MONITOR = 1) then
            return 32ux"1180";
        else
            return 32ux"180";
        end if;
    end getGeneralExceptOffset;
    function getInstEntranceAddr return std_logic_vector is begin
        if (USE_BOOTLOADER = 1) then
            return 32ux"bfc00000";
        else
            return 32ux"80000000";
        end if;
    end getInstEntranceAddr;

    -- Verilog entities must be declared
    component clk_wiz
        port (
            clk_in1: in std_logic;
            clk_out1, clk_out2, clk_out3: out std_logic
        );
    end component;
    component async_transmitter
        generic (
            ClkFrequency, Baud: integer
        );
        port (
            clk, TxD_start: in std_logic;
            TxD_data: in std_logic_vector(7 downto 0);
            TxD, TxD_busy: out std_logic
        );
    end component;
    component async_receiver
        generic (
            ClkFrequency, Baud: integer;
            Oversampling: integer := 8
        );
        port (
            clk, RxD: in std_logic;
            RxD_data_ready: out std_logic;
            RxD_data: out std_logic_vector(7 downto 0);
            RxD_idle, RxD_endofpacket: out std_logic
        );
    end component;

    signal rst: std_logic;

    signal clkMain: std_logic; -- 25MHz clock
    signal clk200, clk100: std_logic;

    signal cpuBus, ddr3Bus, flashBus, serialBus, bootBus, ethBus, ledBus, numBus: BusInterface;

    signal scCorrect: std_logic;
    signal sync: std_logic_vector(2 downto 0);
    signal irq: std_logic_vector(5 downto 0);
    signal timerInt, comInt, usbInt, ethInt: std_logic;

    -- Serial COM
    signal rxdReady, txdBusy, txdStart: std_logic;
    signal rxdData, txdData: std_logic_vector(7 downto 0);

    -- Ethernet
    signal eth_mdio_i, eth_mdio_o, eth_mdio_t: std_logic;

    -- LED
    signal ledHold: std_logic_vector(15 downto 0);
begin
    rst <= not rst_n;

    clk_wiz_ist: clk_wiz
        port map (
            clk_in1 => clk_in,
            clk_out1 => clk200,
            clk_out2 => clkMain,
            clk_out3 => clk100
        );

    uart_r: async_receiver
        generic map (
            ClkFrequency => 25000000,
            Baud => 9600
        )
        port map (
            clk => clkMain,
            RxD => uart_rx,
            RxD_data_ready => rxdReady,
            RxD_data => rxdData
        );
    uart_t: async_transmitter
        generic map (
            ClkFrequency => 25000000,
            Baud => 9600
        )
        port map (
            clk => clkMain,
            TxD => uart_tx,
            TxD_busy => txdBusy,
            TxD_start => txdStart,
            TxD_data => txdData
        );

    irq <= (5 => timerInt, 2 => comInt, others => '0');
    -- MIPS standard requires irq[5] = timer
    -- Monitor requires irq[2] = COM

    cpu_ist: entity work.cpu
        generic map (
            exceptBootBaseAddr => getExceptBootBaseAddr,
            tlbRefillExl0Offset => getTlbRefillExl0Offset,
            generalExceptOffset => getGeneralExceptOffset,
            instEntranceAddr => getInstEntranceAddr
        )
        port map (
            clk => clkMain,
            rst => rst,
            dev_io => cpuBus,
            sync_o => sync,
            scCorrect_i => scCorrect,
            int_i => irq,
            timerInt_o => timerInt
        );

    devctrl_ist: entity work.devctrl
        port map (
            clk => clkMain,
            rst => rst,

            cpu_io => cpuBus,
            ddr3_io => ddr3Bus,
            flash_io => flashBus,
            serial_io => serialBus,
            boot_io => bootBus,
            eth_io => ethBus,
            led_io => ledBus,
            num_io => numBus,

            sync_i => sync,
            scCorrect_o => scCorrect
    );

    -- Please don't pass tri-state ports into a sub-module

    flash_ctrl_ist: entity work.flash_ctrl
        port map (
            clk => clkMain,
            rst => rst,
            cpu_io => flashBus,
            clk_o => spi_clk,
            cs_n_o => spi_cs_n,
            di_o => spi_di,
            do_i => spi_do
        );

    ddr3_ctrl_encap_ist: entity work.ddr3_ctrl_encap
        port map (
            clk_100 => clk100,
            clk_200 => clk200,
            clk_25 => clkMain,
            rst => rst,

            cpu_io => ddr3Bus,

            ddr3_dq => ddr3_dq,
            ddr3_addr => ddr3_addr,
            ddr3_ba => ddr3_ba,
            ddr3_ras_n => ddr3_ras_n,
            ddr3_cas_n => ddr3_cas_n,
            ddr3_we_n => ddr3_we_n,
            ddr3_odt => ddr3_odt,
            ddr3_reset_n => ddr3_reset_n,
            ddr3_cke => ddr3_cke,
            ddr3_dm => ddr3_dm,
            ddr3_dqs_p => ddr3_dqs_p,
            ddr3_dqs_n => ddr3_dqs_n,
            ddr3_ck_p => ddr3_ck_p,
            ddr3_ck_n => ddr3_ck_n
        );

    serial_ctrl_ist: entity work.serial_ctrl
        port map (
            clk => clkMain,
            rst => rst,
            cpu_io => serialBus,
            int_o => comInt,
            rxdReady_i => rxdReady,
            rxdData_i => rxdData,
            txdBusy_i => txdBusy,
            txdStart_o => txdStart,
            txdData_o => txdData
        );

    boot_ctrl_ist: entity work.boot_ctrl
        port map (
            cpu_io => bootBus
        );

    eth_ctrl_encap_ist: entity work.eth_ctrl_encap
        port map (
            clk_100 => clk100,
            clk_25 => clkMain,
            rst => rst,

            cpu_io => ethBus,

            eth_rst_n => eth_rst_n,
            eth_txclk => eth_txclk,
            eth_rxclk => eth_rxclk,
            eth_txen => eth_txen,
            eth_rxdv => eth_rxdv,
            eth_txerr => eth_txerr,
            eth_rxerr => eth_rxerr,
            eth_txd => eth_txd,
            eth_rxd => eth_rxd,
            eth_coll => eth_coll,
            eth_crs => eth_crs,
            eth_mdio_i => eth_mdio_i,
            eth_mdio_o => eth_mdio_o,
            eth_mdio_t => eth_mdio_t,
            eth_mdc => eth_mdc
        );
    eth_mdio <= 'Z' when eth_mdio_t = '1' else eth_mdio_o;
    eth_mdio_i <= eth_mdio;

    seg7_ctrl_ist: entity work.seg7_ctrl
        port map (
            clk => clkMain,
            rst => rst,
            cpu_io => numBus,
            cs_n_o => num_cs_n,
            lights_o => num_a_g
        );

    ledBus.busy_d2c <= PIPELINE_NONSTOP;
    ledBus.dataLoad_d2c <= (others => 'X');
    led_n <= not ledHold;
    process (clkMain) begin
        if (rising_edge(clkMain)) then
            if (rst = '1') then
                ledHold <= (others => '0');
            elsif (ledBus.enable_c2d = '1') then
                ledHold <= ledBus.dataSave_c2d(15 downto 0);
            end if;
        end if;
    end process;
end bhv;
