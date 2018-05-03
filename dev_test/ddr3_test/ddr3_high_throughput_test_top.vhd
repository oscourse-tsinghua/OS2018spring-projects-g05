library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ddr3_high_throughput_test_top is
    port (
        clk_in, rst_n: in std_logic;

        led_n: out std_logic_vector(15 downto 0);
        led_rg0: out std_logic_vector(0 to 1);
        num_cs_n: out std_logic_vector(7 downto 0);
        num_a_g: out std_logic_vector(6 downto 0);

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
end ddr3_high_throughput_test_top;

architecture bhv of ddr3_high_throughput_test_top is

    component clk_wiz
        port (
            clk_in1: in std_logic;
            clk_out1: out std_logic;
            clk_out2: out std_logic
        );
    end component;

    component clk_wiz_25
        port (
            clk_in1: in std_logic;
            clk_out1: out std_logic
        );
    end component;

    component mig_ddr3
        port (
            sys_clk_i, clk_ref_i, sys_rst: in std_logic;

            ddr3_dq: inout std_logic_vector(15 downto 0);
            ddr3_dqs_n, ddr3_dqs_p: inout std_logic_vector(1 downto 0);
            ddr3_addr: out std_logic_vector(12 downto 0);
            ddr3_ba: out std_logic_vector(2 downto 0);
            ddr3_ras_n, ddr3_cas_n, ddr3_we_n, ddr3_reset_n: out std_logic;
            ddr3_ck_p, ddr3_ck_n, ddr3_cke: out std_logic_vector(0 downto 0);
            ddr3_dm: out std_logic_vector(1 downto 0);
            ddr3_odt: out std_logic_vector(0 downto 0);

            s_axi_awid, s_axi_arid: in std_logic_vector(7 downto 0);
            s_axi_bid, s_axi_rid: out std_logic_vector(7 downto 0);
            s_axi_awaddr, s_axi_araddr: in std_logic_vector(26 downto 0);
            s_axi_awlen, s_axi_arlen: in std_logic_vector(7 downto 0);
            s_axi_awsize, s_axi_arsize: in std_logic_vector(2 downto 0);
            s_axi_awburst, s_axi_arburst: in std_logic_vector(1 downto 0);
            s_axi_wdata: in std_logic_vector(31 downto 0);
            s_axi_rdata: out std_logic_vector(31 downto 0);
            s_axi_wstrb: in std_logic_vector(3 downto 0);
            s_axi_bresp, s_axi_rresp: out std_logic_vector(1 downto 0);
            s_axi_wlast, s_axi_awvalid, s_axi_wvalid, s_axi_arvalid, s_axi_bready, s_axi_rready: in std_logic;
            s_axi_rlast, s_axi_bvalid, s_axi_rvalid, s_axi_awready, s_axi_wready, s_axi_arready: out std_logic;
            s_axi_awlock: in std_logic_vector(0 downto 0);
            s_axi_awcache: in std_logic_vector(3 downto 0);
            s_axi_awprot: in std_logic_vector(2 downto 0);
            s_axi_awqos: in std_logic_vector(3 downto 0);
            s_axi_arlock: in std_logic_vector(0 downto 0);
            s_axi_arcache: in std_logic_vector(3 downto 0);
            s_axi_arprot: in std_logic_vector(2 downto 0);
            s_axi_arqos: in std_logic_vector(3 downto 0);

            ui_clk, ui_clk_sync_rst: out std_logic;
            aresetn, app_sr_req, app_ref_req, app_zq_req: in std_logic
        );
    end component;

    function addr2Data1(addr: std_logic_vector(26 downto 0)) return std_logic_vector is
    begin
        return addr(26 downto 2) & addr(10 downto 4);
    end addr2Data1;

    function addr2Data2(addr: std_logic_vector(26 downto 0)) return std_logic_vector is
    begin
        return addr(20 downto 11) & addr(18 downto 3) & addr(26 downto 21);
    end addr2Data2;

    --function addr2Data1(addr: std_logic_vector(26 downto 0)) return std_logic_vector is
    --begin
        --return 7ub"0" & addr(26 downto 2);
    --end addr2Data1;

    --function addr2Data2(addr: std_logic_vector(26 downto 0)) return std_logic_vector is
    --begin
        --return 7ub"0" & addr(26 downto 3) & (not addr(2));
    --end addr2Data2;

    signal enable_i, readEnable_i: std_logic;
    signal addr_i: std_logic_vector(31 downto 0);
    signal writeData_i: std_logic_vector(31 downto 0);
    signal readData_o: std_logic_vector(31 downto 0);
    signal byteSelect_i: std_logic_vector(3 downto 0);
    signal busy_o: std_logic;

    signal axi_awid, axi_bid, axi_arid, axi_rid: std_logic_vector(7 downto 0);
    signal axi_awaddr, axi_araddr: std_logic_vector(26 downto 0);
    signal axi_awlen, axi_arlen: std_logic_vector(7 downto 0);
    signal axi_awsize, axi_arsize: std_logic_vector(2 downto 0);
    signal axi_awburst, axi_arburst: std_logic_vector(1 downto 0);
    signal axi_wdata, axi_rdata: std_logic_vector(31 downto 0);
    signal axi_wstrb: std_logic_vector(3 downto 0);
    signal axi_bresp, axi_rresp: std_logic_vector(1 downto 0);
    signal axi_wlast, axi_rlast: std_logic;
    signal axi_awvalid, axi_wvalid, axi_bvalid, axi_arvalid, axi_rvalid: std_logic;
    signal axi_awready, axi_wready, axi_bready, axi_arready, axi_rready: std_logic;
    signal axi_awlock: std_logic_vector(0 downto 0);
    signal axi_awcache: std_logic_vector(3 downto 0);
    signal axi_awprot: std_logic_vector(2 downto 0);
    signal axi_awqos: std_logic_vector(3 downto 0);
    signal axi_arlock: std_logic_vector(0 downto 0);
    signal axi_arcache: std_logic_vector(3 downto 0);
    signal axi_arprot: std_logic_vector(2 downto 0);
    signal axi_arqos: std_logic_vector(3 downto 0);

    signal clk_ref, clk_in_25, ui_clk, ui_clk_sync_rst, aresetn: std_logic;

    signal enable_100_i, readEnable_100_i: std_logic;
    signal addr_100_i: std_logic_vector(31 downto 0);
    signal writeData_100_i: std_logic_vector(31 downto 0);
    signal readData_100_o: std_logic_vector(31 downto 0);
    signal byteSelect_100_i: std_logic_vector(3 downto 0);
    signal busy_100_o: std_logic;

    type State is (INIT, WRITING, READING, FINISHED, DEAD);
    signal stat: State;

    signal phase: std_logic_vector(1 downto 0);
    signal curAddr: std_logic_vector(26 downto 0);

begin

    axi_awlock <= "0";
    axi_awcache <= "0000";
    axi_awprot <= "000";
    axi_awqos <= "0000";
    axi_arlock <= "0";
    axi_arcache <= "0000";
    axi_arprot <= "000";
    axi_arqos <= "0000";

    clk_wiz_ist: clk_wiz
        port map (
            clk_in1 => clk_in,
            clk_out1 => clk_ref,
            clk_out2 => clk_in_25
        );

    mig_ddr3_ist: mig_ddr3
        port map (
            sys_clk_i => clk_in,
            clk_ref_i => clk_ref,
            sys_rst => rst_n,
            -- device_tmp =>

            ddr3_dq => ddr3_dq,
            ddr3_dqs_n => ddr3_dqs_n,
            ddr3_dqs_p => ddr3_dqs_p,
            ddr3_addr => ddr3_addr,
            ddr3_ba => ddr3_ba,
            ddr3_ras_n => ddr3_ras_n,
            ddr3_cas_n => ddr3_cas_n,
            ddr3_we_n => ddr3_we_n,
            ddr3_reset_n => ddr3_reset_n,
            ddr3_ck_p(0) => ddr3_ck_p,
            ddr3_ck_n(0) => ddr3_ck_n,
            ddr3_cke(0) => ddr3_cke,
            ddr3_dm => ddr3_dm,
            ddr3_odt(0) => ddr3_odt,
            -- init_calib_complete =>

            s_axi_awid => axi_awid,
            s_axi_awaddr => axi_awaddr,
            s_axi_awlen => axi_awlen,
            s_axi_awsize => axi_awsize,
            s_axi_awburst => axi_awburst,
            s_axi_awlock => axi_awlock,
            s_axi_awcache => axi_awcache,
            s_axi_awprot => axi_awprot,
            s_axi_awqos => axi_awqos,
            s_axi_awvalid => axi_awvalid,
            s_axi_awready => axi_awready,

            s_axi_wdata => axi_wdata,
            s_axi_wstrb => axi_wstrb,
            s_axi_wlast => axi_wlast,
            s_axi_wvalid => axi_wvalid,
            s_axi_wready => axi_wready,

            s_axi_bid => axi_bid,
            s_axi_bresp => axi_bresp,
            s_axi_bvalid => axi_bvalid,
            s_axi_bready => axi_bready,

            s_axi_arid => axi_arid,
            s_axi_araddr => axi_araddr,
            s_axi_arlen => axi_arlen,
            s_axi_arsize => axi_arsize,
            s_axi_arburst => axi_arburst,
            s_axi_arlock => axi_arlock,
            s_axi_arcache => axi_arcache,
            s_axi_arprot => axi_arprot,
            s_axi_arqos => axi_arqos,
            s_axi_arvalid => axi_arvalid,
            s_axi_arready => axi_arready,

            s_axi_rid => axi_rid,
            s_axi_rdata => axi_rdata,
            s_axi_rresp => axi_rresp,
            s_axi_rlast => axi_rlast,
            s_axi_rvalid => axi_rvalid,
            s_axi_rready => axi_rready,

            ui_clk => ui_clk,
            ui_clk_sync_rst => ui_clk_sync_rst,
            -- mmcm_locked =>
            aresetn => aresetn,
            app_sr_req => '0',
            app_ref_req => '0',
            app_zq_req => '0'
            -- app_sr_active =>
            -- app_ref_ack =>
            -- app_zq_ack =>
        );

    ddr3_ctrl_ist: entity work.ddr3_ctrl
        port map (
            clk_100 => ui_clk,
            clk_25 => clk_in_25,
            rst_100 => not ui_clk_sync_rst,
            rst_25 => rst_n,

            enable_i => enable_i,
            readEnable_i => readEnable_i,
            addr_i => addr_i,
            writeData_i => writeData_i,
            readData_o => readData_o,
            byteSelect_i => byteSelect_i,
            busy_o => busy_o,

            enable_o => enable_100_i,
            readEnable_o => readEnable_100_i,
            addr_o => addr_100_i,
            writeData_o => writeData_100_i,
            readData_i => readData_100_o,
            byteSelect_o => byteSelect_100_i,
            busy_i => busy_100_o
        );

    ddr3_ctrl_100_ist: entity work.ddr3_ctrl_100
        port map (
            clk => ui_clk,
            rst => not ui_clk_sync_rst,

            enable_i => enable_100_i,
            readEnable_i => readEnable_100_i,
            addr_i => addr_100_i,
            writeData_i => writeData_100_i,
            readData_o => readData_100_o,
            byteSelect_i => byteSelect_100_i,
            busy_o => busy_100_o,

            axi_awid_o => axi_awid,
            axi_awaddr_o => axi_awaddr,
            axi_awlen_o => axi_awlen,
            axi_awsize_o => axi_awsize,
            axi_awburst_o => axi_awburst,
            axi_awvalid_o => axi_awvalid,
            axi_awready_i => axi_awready,

            axi_wdata_o => axi_wdata,
            axi_wstrb_o => axi_wstrb,
            axi_wlast_o => axi_wlast,
            axi_wvalid_o => axi_wvalid,
            axi_wready_i => axi_wready,

            axi_bid_i => axi_bid,
            axi_bresp_i => axi_bresp,
            axi_bvalid_i => axi_bvalid,
            axi_bready_o => axi_bready,

            axi_arid_o => axi_arid,
            axi_araddr_o => axi_araddr,
            axi_arlen_o => axi_arlen,
            axi_arsize_o => axi_arsize,
            axi_arburst_o => axi_arburst,
            axi_arvalid_o => axi_arvalid,
            axi_arready_i => axi_arready,

            axi_rid_i => axi_rid,
            axi_rdata_i => axi_rdata,
            axi_rresp_i => axi_rresp,
            axi_rlast_i => axi_rlast,
            axi_rvalid_i => axi_rvalid,
            axi_rready_o => axi_rready
        );

    process (ui_clk) begin
        aresetn <= not ui_clk_sync_rst;
    end process;


    ---------------------------------------------------------------


    addr_i(26 downto 0) <= curAddr;
    byteSelect_i <= "1111";
    writeData_i <= addr2Data1(curAddr) when phase = 0 else addr2Data2(curAddr);
    led_n <= curAddr(22 downto 7);
    --led_n <= readData_o(15 downto 0);
    led_rg0 <= "10" when stat = FINISHED else "01" when stat = DEAD else "00";
    num_cs_n <= "11111110";
    num_a_g <= "1111110" when phase = 0 else
               "0110000" when phase = 1 else
               "1101101" when phase = 2 else
               "1111001" when phase = 3 else 7ub"0";

    process (clk_in_25) begin
        if (rising_edge(clk_in_25)) then
            if (rst_n = '0') then
                curAddr <= 27ub"0";
                stat <= INIT;
                enable_i <= '0';
                phase <= "00";
            else
                if (phase = 0) then

                    if (stat = INIT) then
                        enable_i <= '1';
                        readEnable_i <= '0';
                        stat <= WRITING;
                    elsif (stat = WRITING and busy_o = '0') then
                        readEnable_i <= '1';
                        stat <= READING;
                    elsif (stat = READING and busy_o = '0') then
                        if (readData_o = writeData_i) then
                            if (curAddr = 27ux"7fffffc") then
                                curAddr <= 27ub"0";
                                stat <= INIT;
                                enable_i <= '0';
                                phase <= "01";
                            else
                                curAddr <= curAddr + 4;
                                readEnable_i <= '0';
                                stat <= WRITING;
                            end if;
                        else
                            stat <= DEAD;
                        end if;
                    end if;

                elsif (phase = 1) then

                    if (stat = INIT) then
                        enable_i <= '1';
                        readEnable_i <= '1';
                        stat <= READING;
                    elsif (stat = READING and busy_o = '0') then
                        if (readData_o = addr2Data1(curAddr)) then
                            if (curAddr = 27ux"7fffffc") then
                                curAddr <= 27ub"0";
                                stat <= INIT;
                                enable_i <= '0';
                                phase <= "10";
                            else
                                curAddr <= curAddr + 4;
                            end if;
                        else
                            stat <= DEAD;
                        end if;
                    end if;

                elsif (phase = 2) then

                    if (stat = INIT) then
                        enable_i <= '1';
                        readEnable_i <= '0';
                        stat <= WRITING;
                    elsif (stat = WRITING and busy_o = '0') then
                        if (curAddr = 27ux"7fffffc") then
                            curAddr <= 27ub"0";
                            stat <= INIT;
                            enable_i <= '0';
                            phase <= "11";
                        else
                            curAddr <= curAddr + 4;
                        end if;
                    end if;

                elsif (phase = 3) then

                    if (stat = INIT) then
                        enable_i <= '1';
                        readEnable_i <= '1';
                        stat <= READING;
                    elsif (stat = READING and busy_o = '0') then
                        if (readData_o = addr2Data2(curAddr)) then
                            if (curAddr = 27ux"7fffffc") then
                                stat <= FINISHED;
                            else
                                curAddr <= curAddr + 4;
                            end if;
                        else
                            stat <= DEAD;
                        end if;
                    end if;

                end if;
            end if;
        end if;
    end process;

end bhv;
