library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.global_const.all;
use work.except_const.all;
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

            instExcept_i, dataExcept_i: in std_logic_vector(ExceptionCauseWidth);
            ifToStall_i, memToStall_i: in std_logic;

            int_i: in std_logic_vector(intWidth);
            timerInt_o: out std_logic
        );
    end component;

    component memctrl
        port (
            -- Connect to instruction interface of CPU
            instData_o: out std_logic_vector(InstWidth);
            instAddr_i: in std_logic_vector(AddrWidth);
            instEnable_i: in std_logic;
            instStall_o: out std_logic;
            instExcept_o: out std_logic_vector(ExceptionCauseWidth);

            -- Connect to data interface of CPU
            dataEnable_i: in std_logic;
            dataWrite_i: in std_logic;
            dataData_o: out std_logic_vector(DataWidth);
            dataData_i: in std_logic_vector(DataWidth);
            dataAddr_i: in std_logic_vector(AddrWidth);
            dataByteSelect_i: in std_logic_vector(3 downto 0);
            dataStall_o: out std_logic;
            dataExcept_o: out std_logic_vector(ExceptionCauseWidth);

            -- Connect to external device (MMU)
            devEnable_o: out std_logic;
            devWrite_o: out std_logic;
            devData_i: in std_logic_vector(DataWidth);
            devData_o: out std_logic_vector(DataWidth);
            devAddr_o: out std_logic_vector(AddrWidth);
            devByteSelect_o: out std_logic_vector(3 downto 0);
            devBusy_i: in std_logic;
            devExcept_i: in std_logic_vector(ExceptionCauseWidth)
        );
    end component;

    component ram
        port (
            clka, ena: in std_logic;
            wea: in std_logic_vector(3 downto 0);
            dina: in std_logic_vector(31 downto 0);
            addra: in std_logic_vector(RamAddrWidth);
            douta: out std_logic_vector(31 downto 0)
        );
    end component;

    signal rst: std_logic := '1';
    signal clk: std_logic := '0';
    signal ramClk: std_logic := '0';
    signal judgeClk: std_logic := '0';

    signal instEnable: std_logic;
    signal instData: std_logic_vector(DataWidth);
    signal instAddr: std_logic_vector(AddrWidth);

    signal dataEnable: std_logic;
    signal dataWrite: std_logic;
    signal dataDataSave: std_logic_vector(DataWidth);
    signal dataDataLoad: std_logic_vector(DataWidth);
    signal dataAddr: std_logic_vector(AddrWidth);
    signal dataByteSelect: std_logic_vector(3 downto 0);

    signal devEnable, devWrite: std_logic;
    signal devDataSave, devDataLoad: std_logic_vector(DataWidth);
    signal devAddr: std_logic_vector(AddrWidth);
    signal devByteSelect: std_logic_vector(3 downto 0);

    signal instStall, dataStall: std_logic;
    signal instExcept, dataExcept: std_logic_vector(ExceptionCauseWidth);
    signal int: std_logic_vector(IntWidth);
    signal timerInt: std_logic;

    signal judgeRes: std_logic;

begin

    process begin
        wait for CLK_PERIOD / 2 - 0.1 ns;
        clk <= not clk;
        wait for 0.1 ns;
        ramClk <= not ramClk;
    end process;

    process begin
        -- begin reset
        wait for CLK_PERIOD;
        rst <= '0';
        wait;
    end process;

    ram_ist: ram
        port map (
            clka => ramClk,
            ena => devEnable,
            wea => devByteSelect and (devWrite & devWrite & devWrite & devWrite),
            dina => devDataSave,
            addra => devAddr(RamAddrSliceWidth),
            douta => devDataLoad
        );

    memctrl_ist: memctrl
        port map (
            -- Connect to instruction interface of CPU
            instData_o => instData,
            instAddr_i => instAddr,
            instEnable_i => instEnable,
            instStall_o => instStall,
            instExcept_o => instExcept,

            -- Connect to data interface of CPU
            dataEnable_i => dataEnable,
            dataWrite_i => dataWrite,
            dataData_o => dataDataLoad,
            dataData_i => dataDataSave,
            dataAddr_i => dataAddr,
            dataByteSelect_i => dataByteSelect,
            dataStall_o => dataStall,
            dataExcept_o => dataExcept,

            -- Connect to external device (MMU)
            devEnable_o => devEnable,
            devWrite_o => devWrite,
            devData_i => devDataLoad,
            devData_o => devDataSave,
            devAddr_o => devAddr,
            devByteSelect_o => devByteSelect,
            devBusy_i => PIPELINE_NONSTOP,
            devExcept_i => NO_CAUSE
        );

    cpu_ist: cpu
        generic map (
            instConvEndian => false,
            instEntranceAddr => INST_ENTRANCE_ADDR
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
            instExcept_i => instExcept,
            dataExcept_i => dataExcept,
            ifToStall_i => instStall,
            memToStall_i => dataStall,
            int_i => int,
            timerInt_o => timerInt
        );

    int <= (0 => timerInt, others => '0');

    process begin
        wait for JUDGE_Clk_PERIOD / 2;
        judgeClk <= not judgeClk;
    end process;

    process(judgeClk)
        variable testCnt, correctCnt: integer := 0;
        variable tmpTestCnt, nowTestCnt, nowCorrectCnt: integer;
        variable nowDelta :integer := 0;
        alias reg is <<signal cpu_ist.regfile_ist.regArray: RegArrayType>>;
    begin
        if (rising_edge(judgeClk)) then
            tmpTestCnt := conv_integer(reg(23));
            if (tmpTestCnt > testCnt) then
                nowTestCnt := tmpTestCnt;
                nowCorrectCnt := conv_integer(reg(19));
                if (nowTestCnt - nowCorrectCnt > nowDelta) then
                    judgeRes <= '0';
                    report "test " & integer'image(nowTestCnt) & " failed";
                else
                    judgeRes <= '1';
                    report "test " & integer'image(nowTestCnt) & " passed";
                end if;
                testCnt := nowTestCnt;
                correctCnt := nowCorrectCnt;
                nowDelta := nowTestCnt - nowCorrectCnt;
            end if;
        end if;
    end process;

end bhv;