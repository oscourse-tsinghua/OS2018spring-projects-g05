library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.global_const.all;

entity devctrl is
    port (
        rst: in std_logic;

        -- Signals connecting to mmu --
        devEnable_i, devWrite_i: in std_logic;
        devBusy_o: out std_logic;
        devDataSave_i: in std_logic_vector(DataWidth);
        devDataLoad_o: out std_logic_vector(DataWidth);
        devPhysicalAddr_i: in std_logic_vector(AddrWidth);
        devByteSelect_i: in std_logic_vector(3 downto 0);

        int_o: out std_logic_vector(IntWidth);
        timerInt_i: in std_logic

        -- Signals connecting to devices --
        addr_o: out std_logic_vector(AddrWidth);
        int_i: in std_logic_vector(IntWidth);
        timerInt_o: out std_logic;

        -- Signals connecting to ram_ctrl --
        ramEnable_o: out std_logic;
        ramReadEnable_o: out std_logic;
        ramDataSave_o: out std_logic_vector(DataWidth);
        ramDataLoad_i: in std_logic_vector(DataWidth);
        ramByteSelect_o: out std_logic(3 downto 0);
        ramWriteBusy_i: in std_logic;

        -- Signals connecting to flash_ctrl --
        flashEnable_o: out std_logic;
        flashReadEnable_o: out std_logic;
        flashDataLoad_i: in std_logic_vector(DataWidth);
        flashBusy_i: in std_logic
    );
end devctrl;

architecture bhv of devctrl is
begin

    devBusy_o <= flashBusy_i or ramWriteBusy_i;

    process (flashBusy_i) begin
        if (falling_edge(flashBusy_i)) then
           devDataLoad_o <= flashDataLoad_i; 
        end if;
    end process;

    process (all) begin
        if (rst = RST_ENABLE or devEnable_i = DISABLE) then
            devBusy_o <= PIPELINE_NONSTOP;
            devDataLoad_o <= (others => '0');
        else
            ramEnable_o <= DISABLE;
            flashEnable_o <= DISABLE;

            if (devPhysicalAddr_i <= 32ux"fffff") then
                -- RAM --
                ramEnable_o <= ENABLE;
                ramReadEnable_o <= not devWrite_i;
                addr_o <= devPhysicalAddr_i;
            elsif (devPhysicalAddr_i = 32ux"f000000") then
                -- keyboard --
            elsif (devPhysicalAddr_i >= 32ux"1e000000" and devPhysicalAddr_i <= 32ux"1effffff") then
                -- flash --
                flashEnable_o <= ENABLE;
                if (devWrite_i <= NO) then
                    flashReadEnable_o <= ENABLE;
                    addr_o <= devPhysicalAddr_i;
                end if;
            elsif (devPhysicalAddr_i >= 32ux"1fc00000" and devPhysicalAddr_i <= 32ux"1fc00fff") then
                -- ROM --
            elsif (devPhysicalAddr_i >= 32ux"1fd003f8" and devPhysicalAddr_i <= 32ux"1fd003fc") then
                -- COM --
            end if;
        end if;
    end process;

end bhv;