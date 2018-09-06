library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.bus_const.all;

entity int_ctrl_encap is
    port (
        clk_100, clk_25, rst: in std_logic;

        cpu_i: in BusC2D;
        cpu_o: out BusD2C;

        int_i: in std_logic;
        int_o: out std_logic
    );
end int_ctrl_encap;

architecture bhv of int_ctrl_encap is

    component axi_intc_0 is
        port (
            s_axi_aclk: in std_logic;
            s_axi_aresetn: in std_logic;
            s_axi_awaddr: in std_logic_vector(8 downto 0);
            s_axi_awvalid: in std_logic;
            s_axi_awready: out std_logic;
            s_axi_wdata: in std_logic_vector(31 downto 0);
            s_axi_wstrb: in std_logic_vector(3 downto 0);
            s_axi_wvalid: in std_logic;
            s_axi_wready: out std_logic;
            s_axi_bresp: out std_logic_vector(1 downto 0);
            s_axi_bvalid: out std_logic;
            s_axi_bready: in std_logic;
            s_axi_araddr: in std_logic_vector(8 downto 0);
            s_axi_arvalid: in std_logic;
            s_axi_arready: out std_logic;
            s_axi_rdata: out std_logic_vector(31 downto 0);
            s_axi_rresp: out std_logic_vector(1 downto 0);
            s_axi_rvalid: out std_logic;
            s_axi_rready: in std_logic;
            intr: in std_logic_vector(0 downto 0);
            irq: out std_logic
        );
    end component;

    signal axi_awaddr, axi_araddr: std_logic_vector(8 downto 0);
    signal axi_wdata, axi_rdata: std_logic_vector(31 downto 0);
    signal axi_wstrb: std_logic_vector(3 downto 0);
    signal axi_bresp, axi_rresp: std_logic_vector(1 downto 0);
    signal axi_wlast, axi_rlast: std_logic;
    signal axi_awvalid, axi_wvalid, axi_bvalid, axi_arvalid, axi_rvalid: std_logic;
    signal axi_awready, axi_wready, axi_bready, axi_arready, axi_rready: std_logic;
    signal aresetn: std_logic;

    signal enable_100_i, readEnable_100_i: std_logic;
    signal addr_100_i: std_logic_vector(31 downto 0);
    signal writeData_100_i: std_logic_vector(31 downto 0);
    signal readData_100_o: std_logic_vector(31 downto 0);
    signal byteSelect_100_i: std_logic_vector(3 downto 0);
    signal busy_100_o: std_logic;

begin

    aresetn <= not rst;
    intc_ist: axi_intc_0
        port map (
            s_axi_aclk => clk_100,
            s_axi_aresetn => aresetn,

            s_axi_awaddr => axi_awaddr,
            s_axi_awvalid => axi_awvalid,
            s_axi_awready => axi_awready,

            s_axi_wdata => axi_wdata,
            s_axi_wstrb => axi_wstrb,
            s_axi_wvalid => axi_wvalid,
            s_axi_wready => axi_wready,

            s_axi_bresp => axi_bresp,
            s_axi_bvalid => axi_bvalid,
            s_axi_bready => axi_bready,

            s_axi_araddr => axi_araddr,
            s_axi_arvalid => axi_arvalid,
            s_axi_arready => axi_arready,

            s_axi_rdata => axi_rdata,
            s_axi_rresp => axi_rresp,
            s_axi_rvalid => axi_rvalid,
            s_axi_rready => axi_rready,

            intr(0) => int_i,
            irq => int_o
        );

    int_ctrl_ist: entity work.eth_ctrl
        port map (
            clk_100 => clk_100,
            clk_25 => clk_25,
            rst_100 => rst,
            rst_25 => rst,

            enable_i => cpu_i.enable,
            readEnable_i => not cpu_i.write,
            addr_i => cpu_i.addr,
            writeData_i => cpu_i.dataSave,
            readData_o => cpu_o.dataLoad,
            byteSelect_i => cpu_i.byteSelect,
            busy_o => cpu_o.busy,

            enable_o => enable_100_i,
            readEnable_o => readEnable_100_i,
            addr_o => addr_100_i,
            writeData_o => writeData_100_i,
            readData_i => readData_100_o,
            byteSelect_o => byteSelect_100_i,
            busy_i => busy_100_o
        );

    int_ctrl_100_ist: entity work.int_ctrl_100
        port map (
            clk => clk_100,
            rst => rst,

            enable_i => enable_100_i,
            readEnable_i => readEnable_100_i,
            addr_i => addr_100_i,
            writeData_i => writeData_100_i,
            readData_o => readData_100_o,
            byteSelect_i => byteSelect_100_i,
            busy_o => busy_100_o,

            axi_awaddr_o => axi_awaddr,
            axi_awvalid_o => axi_awvalid,
            axi_awready_i => axi_awready,

            axi_wdata_o => axi_wdata,
            axi_wstrb_o => axi_wstrb,
            axi_wvalid_o => axi_wvalid,
            axi_wready_i => axi_wready,

            axi_bresp_i => axi_bresp,
            axi_bvalid_i => axi_bvalid,
            axi_bready_o => axi_bready,

            axi_araddr_o => axi_araddr,
            axi_arvalid_o => axi_arvalid,
            axi_arready_i => axi_arready,

            axi_rdata_i => axi_rdata,
            axi_rresp_i => axi_rresp,
            axi_rvalid_i => axi_rvalid,
            axi_rready_o => axi_rready
        );

end bhv;
