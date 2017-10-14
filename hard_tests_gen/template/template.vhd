library ieee;
use ieee.std_logic_1164.all;

use work.test_const.all;

entity {{{TEST_NAME}}} is
end {{{TEST_NAME}}};

architecture bhv of {{{TEST_NAME}}} is
    component cpu
        port (
            rst, clk: in std_logic;

            instEnable_o: out std_logic;
            instData_i: in std_logic_vector(RamDataWidth);
            instAddr_o: out std_logic_vector(RamAddrWidth);

            dataEnable_o: out std_logic;
            dataWrite_o: out std_logic;
            dataData_i: in std_logic_vector(RamDataWidth);
            dataData_o: out std_logic_vector(RamDataWidth);
            dataAddr_o: out std_logic_vector(RamAddrWidth);
            dataByteSelect_o: out std_logic_vector(3 downto 0);

            int_i: in std_logic_vector(intWidth);
            timerInt_o: out std_logic
        );
    end component;

    component fake_ram is
        port (
            enable_i, write_i, clk: in std_logic;
            data_i: in std_logic_vector(RamDataWidth);
            addr_i: in std_logic_vector(RamAddrWidth);
            byteSelect_i: in std_logic_vector(3 downto 0);
            data_o: out std_logic_vector(RamDataWidth)
        );
    end component;

    signal rst: std_logic := '1';
    signal clk: std_logic := '0';

    signal instEnable: std_logic;
    signal instData: std_logic_vector(RamDataWidth);
    signal instAddr: std_logic_vector(RamAddrWidth);

    signal dataEnable: std_logic;
    signal dataWrite: std_logic;
    signal dataDataSave: std_logic_vector(RamDataWidth);
    signal dataDataLoad: std_logic_vector(RamDataWidth);
    signal dataAddr: std_logic_vector(RamAddrWidth);
    signal dataByteSelect: std_logic_vector(3 downto 0);

    signal int: std_logic_vector(intWidth);
    signal timerInt: std_logic;
begin
    inst_ram: fake_ram
        port map (
            enable_i => instEnable,
            write_i => '0',
            clk => clk,
            data_i => 32b"0",
            addr_i => instAddr,
            byteSelect_i => "1111",
            data_o => instData
        );

    data_ram: fake_ram
        port map (
            enable_i =>dataEnable,
            write_i => dataWrite,
            clk => clk,
            data_i => dataDataSave,
            addr_i => dataAddr,
            byteSelect_i => dataByteSelect,
            data_o => dataDataLoad
        );

    cpu_inst: cpu
        port map (
            rst => rst,
            clk => clk,
            instEnable_o => instEnable,
            instData_i => instData,
            instAddr_o => instAddr,
            dataEnable_o => dataEnable,
            dataWrite_o => dataWrite,
            dataData_i => dataDataLoad,
            dataData_o => dataDataSave,
            dataAddr_o => dataAddr,
            dataByteSelect_o => dataByteSelect,
            int_i => int,
            timerInt_o => timerInt
        );

    int <= (0 => timerInt, others => '0');

    process begin
        wait for CLK_PERIOD / 2;
        clk <= not clk;
    end process;

    process begin
        -- begin reset
        wait for CLK_PERIOD;
        rst <= '0';

        -- insert test logic here

        wait;
    end process;
end bhv;
