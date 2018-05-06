library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.global_const.all;

entity ddr3_ctrl_encap is
    port (
        clk_100, clk_200, clk_25, rst: in std_logic;

        enable_i, readEnable_i: in std_logic;
        addr_i: in std_logic_vector(AddrWidth);
        writeData_i: in std_logic_vector(DataWidth);
        readData_o: out std_logic_vector(DataWidth);
        byteSelect_i: in std_logic_vector(3 downto 0);
        busy_o: out std_logic;

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
end ddr3_ctrl_encap;

architecture bhv of ddr3_ctrl_encap is

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

    signal ui_clk, ui_clk_sync_rst, rst_n, aresetn: std_logic;

    signal enable_100_i, readEnable_100_i: std_logic;
    signal addr_100_i: std_logic_vector(31 downto 0);
    signal writeData_100_i: std_logic_vector(31 downto 0);
    signal readData_100_o: std_logic_vector(31 downto 0);
    signal byteSelect_100_i: std_logic_vector(3 downto 0);
    signal busy_100_o: std_logic;

begin

    axi_awlock <= "0";
    axi_awcache <= "0000";
    axi_awprot <= "000";
    axi_awqos <= "0000";
    axi_arlock <= "0";
    axi_arcache <= "0000";
    axi_arprot <= "000";
    axi_arqos <= "0000";

    rst_n <= not rst;
    mig_ddr3_ist: mig_ddr3
        port map (
            sys_clk_i => clk_100,
            clk_ref_i => clk_200,
            sys_rst =>  rst_n,
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
            clk_25 => clk_25,
            rst_100 => ui_clk_sync_rst,
            rst_25 => rst,

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
            rst => ui_clk_sync_rst,

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

end bhv;
