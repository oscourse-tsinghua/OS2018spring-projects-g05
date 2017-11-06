library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.integration_test_const.all;

entity integration_test is
end integration_test;

architecture bhv of integration_test is

    component cpu
        generic (
            instEntranceAddr: std_logic_vector(AddrWidth);
            instConvEndian: boolean
        );
        port (
            rst, clk: in std_logic;

            instEnable_o: out std_logic;
            instData_i: in std_logic_vector(DataWidth);
            instAddr_o: out std_logic_vector(AddrWidth);

            dataEnable_o: out std_logic;
            dataWrite_o: out std_logic;
            dataData_i: in std_logic_vector(DataWidth);
            dataData_o: out std_logic_vector(DataWidth);
            dataAddr_o: out std_logic_vector(AddrWidth);
            dataByteSelect_o: out std_logic_vector(3 downto 0);

            int_i: in std_logic_vector(intWidth);
            timerInt_o: out std_logic
        );
    end component;

    component fake_ram
        port (
            rst: in std_logic;
            writeEnable_i, readEnable1_i, readEnable2_i: in std_logic;
            writeAddr_i: in std_logic_vector(AddrWidth);
            writeData_i: in std_logic_vector(DataWidth);
            byteSelect_i: in std_logic_vector(3 downto 0);
            readAddr1_i: in std_logic_vector(AddrWidth);
            readAddr2_i: in std_logic_vector(AddrWidth);
            readData1_o: out std_logic_vector(DataWidth);
            readData2_o: out std_logic_vector(DataWidth)
        );
    end component;

    signal rst: std_logic := '1';
    signal clk: std_logic := '0';

    signal instEnable: std_logic;
    signal instData: std_logic_vector(DataWidth);
    signal instAddr: std_logic_vector(AddrWidth);

    signal dataEnable: std_logic;
    signal dataWrite: std_logic;
    signal dataDataSave: std_logic_vector(DataWidth);
    signal dataDataLoad: std_logic_vector(DataWidth);
    signal dataAddr: std_logic_vector(AddrWidth);
    signal dataByteSelect: std_logic_vector(3 downto 0);

    signal int: std_logic_vector(IntWidth);
    signal timerInt: std_logic;

begin

    process begin
        wait for CLK_PERIOD / 2;
        clk <= not clk;
    end process;

    process begin
        -- begin reset
        wait for CLK_PERIOD;
        rst <= '0';
        wait;
    end process;

    ram_ist: fake_ram
        port map (
            rst => rst,
            writeEnable_i => dataWrite,
            readEnable1_i => instEnable,
            readEnable2_i => dataEnable,
            writeAddr_i => dataAddr,
            writeData_i => dataDataSave,
            byteSelect_i => dataByteSelect,
            readAddr1_i => instAddr,
            readAddr2_i => dataAddr,
            readData1_o => instData,
            readData2_o => dataDataLoad
        );

    cpu_ist: cpu
        generic map (
            instEntranceAddr => INST_ENTRANCE_ADDR,
            instConvEndian => false
        )
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

end bhv;