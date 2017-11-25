library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.global_const.all;

entity devctrl is
    port (
        -- Signals connecting to mmu --
        devEnable_i, devWrite_i: in std_logic;
        devBusy_o: out std_logic;
        devDataSave_i: in std_logic_vector(DataWidth);
        devDataLoad_o: out std_logic_vector(DataWidth);
        devPhysicalAddr_i: in std_logic_vector(AddrWidth);

        -- Signals connecting to sram_ctrl --
        ramEnable_o: out std_logic;
        ramReadEnable_o: out std_logic;
        ramDataSave_o: out std_logic_vector(DataWidth);
        ramDataLoad_i: in std_logic_vector(DataWidth);
        ramWriteBusy_i: in std_logic;

        -- Signals connecting to flash_ctrl --
        flashEnable_o: out std_logic;
        flashReadEnable_o: out std_logic;
        flashDataLoad_i: in std_logic_vector(DataWidth);
        flashBusy_i: in std_logic;

        -- Signals connecting to vga_ctrl --
        vgaEnable_o: out std_logic;
        vgaWriteEnable_o: out std_logic;
        vgaWriteData_o: out std_logic_vector(DataWidth);

        -- Signals connecting to serial_ctrl --
        comEnable_o: out std_logic;
        comReadEnable_o: out std_logic;
        comDataSave_o: out std_logic_vector(DataWidth);
        comDataLoad_i: in std_logic_vector(DataWidth)
    );
end devctrl;

architecture bhv of devctrl is
begin
    process (all) begin
        devBusy_o <= PIPELINE_NONSTOP;
        devDataLoad_o <= (others => '0');
        ramEnable_o <= DISABLE;
        ramReadEnable_o <= ENABLE;
        ramDataSave_o <= (others => '0');
        flashEnable_o <= DISABLE;
        flashReadEnable_o <= ENABLE;
        vgaEnable_o <= ENABLE;
        vgaWriteEnable_o <= DISABLE;
        vgaWriteData_o <= (others => '0');

        if (devEnable_i = ENABLE) then
            if (devPhysicalAddr_i <= 32ux"fffff") then
                -- RAM --
                ramEnable_o <= ENABLE;
                ramReadEnable_o <= not devWrite_i;
                ramDataSave_o <= devDataSave_i;
                devDataLoad_o <= ramDataLoad_i;
                devBusy_o <= ramWriteBusy_i;
            elsif (devPhysicalAddr_i = 32ux"f000000") then
                -- keyboard --
            elsif (devPhysicalAddr_i >= 32ux"1e000000" and devPhysicalAddr_i <= 32ux"1effffff") then
                -- flash --
                flashEnable_o <= ENABLE;
                flashReadEnable_o <= not devWrite_i;
                devDataLoad_o <= flashDataLoad_i;
                devBusy_o <= flashBusy_i;
            elsif (devPhysicalAddr_i >= 32ux"1fc00000" and devPhysicalAddr_i <= 32ux"1fc00fff") then
                -- ROM --
            elsif (devPhysicalAddr_i >= 32ux"1fd003f8" and devPhysicalAddr_i <= 32ux"1fd003fc") then
                -- COM --
                comEnable_o <= ENABLE;
                comReadEnable_o <= not devWrite_i;
                comDataSave_o <= devDataSave_i;
                devDataLoad_o <= comDataLoad_i;
            elsif (devPhysicalAddr_i >= 32ux"1fe00000" and devPhysicalAddr_i <= 32ux"1fe4afff") then
                -- VGA --
                -- designated by myself, software needed to support --
                vgaWriteEnable_o <= ENABLE;
                vgaWriteData_o <= devDataSave_i;
            end if;
        end if;
    end process;
end bhv;
