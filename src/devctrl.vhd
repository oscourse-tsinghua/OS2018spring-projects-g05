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

        -- Signals connecting to sram_ctrl (base) --
        ram0Enable_o: out std_logic;
        ram0ReadEnable_o: out std_logic;
        ram0DataSave_o: out std_logic_vector(DataWidth);
        ram0DataLoad_i: in std_logic_vector(DataWidth);
        ram0WriteBusy_i: in std_logic;

        -- Signals connecting to sram_ctrl (ext) --
        ram1Enable_o: out std_logic;
        ram1ReadEnable_o: out std_logic;
        ram1DataSave_o: out std_logic_vector(DataWidth);
        ram1DataLoad_i: in std_logic_vector(DataWidth);
        ram1WriteBusy_i: in std_logic;

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
        comDataLoad_i: in std_logic_vector(DataWidth);

        -- Signals connecting to usb_ctrl --
        usbEnable_o: out std_logic;
        usbReadEnable_o: out std_logic;
        usbReadData_i: in std_logic_vector(DataWidth);
        usbWriteEnable_o: out std_logic;
        usbWriteData_o: out std_logic_vector(DataWidth);
        usbBusy_i: in std_logic;

        -- Signals connecting to boot_ctrl --
        bootEnable_o, bootReadEnable_o: out std_logic;
        bootDataLoad_i: in std_logic_vector(DataWidth);
        bootBusy_i: in std_logic;

        ledEnable_o: out std_logic;
        ledData_o: out std_logic_vector(15 downto 0);
        numEnable_o: out std_logic;
        numData_o: out std_logic_vector(7 downto 0)
    );
end devctrl;

architecture bhv of devctrl is
begin
    process (all) begin
        devBusy_o <= PIPELINE_NONSTOP;
        devDataLoad_o <= (others => '0');
        ram0Enable_o <= DISABLE;
        ram0ReadEnable_o <= ENABLE;
        ram0DataSave_o <= (others => '0');
        ram1Enable_o <= DISABLE;
        ram1ReadEnable_o <= ENABLE;
        ram1DataSave_o <= (others => '0');
        flashEnable_o <= DISABLE;
        flashReadEnable_o <= ENABLE;

        vgaEnable_o <= ENABLE;
        vgaWriteEnable_o <= DISABLE;
        vgaWriteData_o <= (others => '0');
        bootEnable_o <= DISABLE;
        bootReadEnable_o <= ENABLE;
        ledEnable_o <= DISABLE;
        ledData_o <= (others => '0');
        numEnable_o <= DISABLE;
        numData_o <= (others => '0');

        if (devEnable_i = ENABLE) then
            if (devPhysicalAddr_i <= 32ux"3fffff") then
                -- RAM0 --
                ram0Enable_o <= ENABLE;
                ram0ReadEnable_o <= not devWrite_i;
                ram0DataSave_o <= devDataSave_i;
                devDataLoad_o <= ram0DataLoad_i;
                devBusy_o <= ram0WriteBusy_i;
            elsif (devPhysicalAddr_i >= 32ux"400000" and devPhysicalAddr_i <= 32ux"7fffff") then
                -- RAM1 --
                ram1Enable_o <= ENABLE;
                ram1ReadEnable_o <= not devWrite_i;
                ram1DataSave_o <= devDataSave_i;
                devDataLoad_o <= ram1DataLoad_i;
                devBusy_o <= ram1WriteBusy_i;
            elsif (devPhysicalAddr_i = 32ux"f000000") then
                -- keyboard --
            elsif (devPhysicalAddr_i >= 32ux"1e000000" and devPhysicalAddr_i <= 32ux"1effffff") then
                -- flash --
                flashEnable_o <= ENABLE;
                flashReadEnable_o <= not devWrite_i;
                devDataLoad_o <= flashDataLoad_i;
                devBusy_o <= flashBusy_i;
            elsif (devPhysicalAddr_i >= 32ux"1fc00000" and devPhysicalAddr_i <= 32ux"1fc00fff") then
                -- BOOT --
                bootEnable_o <= ENABLE;
                devDataLoad_o <= bootDataLoad_i;
                devBusy_o <= bootBusy_i;
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
            elsif (devPhysicalAddr_i = 32ux"3fd0f000") then
                -- LED. Required by functional test --
                ledEnable_o <= ENABLE;
                ledData_o <= devDataSave_i(15 downto 0);
            elsif (devPhysicalAddr_i = 32ux"3fd0f010") then
                -- 7-seg display. Required by functional test --
                numEnable_o <= ENABLE;
                numData_o <= devDataSave_i(7 downto 0);
            end if;
        end if;
    end process;
end bhv;
