library ieee;
use ieee.std_logic_1164.all;

entity ddr3_sim_test_top is
end ddr3_sim_test_top;

architecture bhv of ddr3_sim_test_top is

    component ddr3_high_throughput_test_top
        port (
            clk_in, rst_n: in std_logic;

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
    end component;

    component ddr3_model
        port (
            rst_n, ck, ck_n, cke, cs_n, ras_n, cas_n, we_n: in std_logic;
            dm_tdqs: inout std_logic_vector(1 downto 0);
            ba: in std_logic_vector(2 downto 0);
            addr: in std_logic_vector(12 downto 0);
            dq: inout std_logic_vector(15 downto 0);
            dqs, dqs_n: inout std_logic_vector(1 downto 0);
            tdqs_n: out std_logic_vector(1 downto 0);
            odt: in std_logic
        );
    end component;

    signal clk, rst: std_logic;
    signal ddr3_rst_n, ddr3_ck, ddr3_ck_n, ddr3_cke, ddr3_ras_n, ddr3_cas_n, ddr3_we_n: std_logic;
    signal ddr3_dm_tdqs: std_logic_vector(1 downto 0);
    signal ddr3_ba: std_logic_vector(2 downto 0);
    signal ddr3_addr: std_logic_vector(12 downto 0);
    signal ddr3_dq: std_logic_vector(15 downto 0);
    signal ddr3_dqs, ddr3_dqs_n: std_logic_vector(1 downto 0);
    signal ddr3_tdqs_n: std_logic_vector(1 downto 0);
    signal ddr3_odt: std_logic;

begin

    process begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process;

    process begin
        rst <= '0';
        wait for 100 ns;
        rst <= '1';
        wait;
    end process;

    top_ist: entity work.ddr3_high_throughput_test_top
        port map (
            clk_in => clk, rst_n => rst,

            ddr3_dq => ddr3_dq,
            ddr3_addr => ddr3_addr,
            ddr3_ba => ddr3_ba,
            ddr3_ras_n => ddr3_ras_n,
            ddr3_cas_n => ddr3_cas_n,
            ddr3_we_n => ddr3_we_n,
            ddr3_odt => ddr3_odt,
            ddr3_reset_n => ddr3_rst_n,
            ddr3_cke => ddr3_cke,
            ddr3_dm => ddr3_dm_tdqs,
            ddr3_dqs_p => ddr3_dqs,
            ddr3_dqs_n => ddr3_dqs_n,
            ddr3_ck_p => ddr3_ck,
            ddr3_ck_n => ddr3_ck_n
        );

    model_ist: ddr3_model
        port map (
            rst_n => ddr3_rst_n,
            ck => ddr3_ck,
            ck_n => ddr3_ck_n,
            cke => ddr3_cke,
            cs_n => '0',
            ras_n => ddr3_ras_n,
            cas_n => ddr3_cas_n,
            we_n => ddr3_we_n,
            dm_tdqs => ddr3_dm_tdqs,
            ba => ddr3_ba,
            addr => ddr3_addr,
            dq => ddr3_dq,
            dqs => ddr3_dqs,
            dqs_n => ddr3_dqs_n,
            odt => ddr3_odt,
            tdqs_n => ddr3_tdqs_n
        );

end bhv;