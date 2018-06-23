library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.except_const.all;

entity memctrl is
    port (
        -- Connect to instruction interface of CPU
        instData_o: out std_logic_vector(InstWidth);
        instAddr_i: in std_logic_vector(AddrWidth);
        instEnable_i: in std_logic;
        instStall_o: out std_logic;
        instExcept_o: out std_logic_vector(ExceptionCauseWidth);
        instTlbRefill_o: out std_logic;

        -- Connect to data interface of CPU
        dataEnable_i: in std_logic;
        dataWrite_i: in std_logic;
        dataData_o: out std_logic_vector(DataWidth);
        dataData_i: in std_logic_vector(DataWidth);
        dataAddr_i: in std_logic_vector(AddrWidth);
        dataByteSelect_i: in std_logic_vector(3 downto 0);
        dataStall_o: out std_logic;
        dataExcept_o: out std_logic_vector(ExceptionCauseWidth);
        dataTlbRefill_o: out std_logic;

        -- Connect to external device (MMU)
        devEnable_o: out std_logic;
        devWrite_o: out std_logic;
        devData_i: in std_logic_vector(DataWidth);
        devData_o: out std_logic_vector(DataWidth);
        devAddr_o: out std_logic_vector(AddrWidth);
        devByteSelect_o: out std_logic_vector(3 downto 0);
        devBusy_i: in std_logic;
        devExcept_i: in std_logic_vector(ExceptionCauseWidth);
        devTlbRefill_i: in std_logic
    );
end memctrl;

architecture bhv of memctrl is begin
    process (all) begin
        devEnable_o <= DISABLE;
        devWrite_o <= NO;
        devData_o <= (others => '0');
        devAddr_o <= (others => '0');
        devByteSelect_o <= "0000";
        instData_o <= (others => '0');
        dataData_o <= (others => '0');
        instStall_o <= PIPELINE_NONSTOP;
        dataStall_o <= PIPELINE_NONSTOP;
        instExcept_o <= NO_CAUSE;
        dataExcept_o <= NO_CAUSE;
        instTlbRefill_o <= '0';
        dataTlbRefill_o <= '0';
        if (dataEnable_i = ENABLE) then
            devEnable_o <= ENABLE;
            devWrite_o <= dataWrite_i;
            devData_o <= dataData_i;
            devAddr_o <= dataAddr_i;
            devByteSelect_o <= dataByteSelect_i;
            dataData_o <= devData_i;
            dataStall_o <= devBusy_i;
            dataExcept_o <= devExcept_i;
            dataTlbRefill_o <= devTlbRefill_i;
            instStall_o <= PIPELINE_STOP;
        elsif (instEnable_i = ENABLE) then
            devEnable_o <= ENABLE;
            devWrite_o <= NO;
            devAddr_o <= instAddr_i;
            devByteSelect_o <= "1111";
            instData_o <= devData_i;
            instStall_o <= devBusy_i;
            instExcept_o <= devExcept_i;
            instTlbRefill_o <= devTlbRefill_i;
        end if;
    end process;
end bhv;
