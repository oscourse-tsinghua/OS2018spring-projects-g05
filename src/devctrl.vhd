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
        bootDataLoad_i: in std_logic_vector(DataWidth);

        -- Signals connecting to lattice_ram_ctrl --
        ltcEnable_o: out std_logic;
        ltcReadEnable_o: out std_logic;
        ltcDataLoad_i: in std_logic_vector(DataWidth);
        ltcBusy_i: in std_logic;

        -- Signals connecting to eth_ctrl --
        ethEnable_o: out std_logic;
        ethReadEnable_o: out std_logic;
        ethDataSave_o: out std_logic_vector(DataWidth);
        ethDataLoad_i: in std_logic_vector(DataWidth);
        ethWriteBusy_i: in std_logic;

        ledEnable_o: out std_logic;
        ledData_o: out std_logic_vector(15 downto 0);
        numEnable_o: out std_logic;
        numData_o: out std_logic_vector(DataWidth)
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
        comEnable_o <= DISABLE;
        comReadEnable_o <= ENABLE;
        comDataSave_o <= (others => '0');
        vgaEnable_o <= ENABLE;
        vgaWriteEnable_o <= DISABLE;
        vgaWriteData_o <= (others => '0');
        ltcEnable_o <= ENABLE;
        ltcReadEnable_o <= DISABLE;
        ethDataSave_o <= (others => '0');
        ethEnable_o <= DISABLE;
        ethReadEnable_o <= ENABLE;
        ledEnable_o <= DISABLE;
        ledData_o <= (others => '0');
        numEnable_o <= DISABLE;
        numData_o <= (others => '0');
        usbEnable_o <= DISABLE;
        usbReadEnable_o <= DISABLE;
        usbWriteEnable_o <= DISABLE;
        usbWriteData_o <= (others => '0');

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
            elsif (devPhysicalAddr_i >= 32ux"1e000000" and devPhysicalAddr_i <= 32ux"1effffff") then
                -- flash --
                flashEnable_o <= ENABLE;
                devDataLoad_o <= flashDataLoad_i;
                devBusy_o <= flashBusy_i;
            elsif (devPhysicalAddr_i >= 32ux"1fc00000" and devPhysicalAddr_i <= 32ux"1fc00fff") then
                -- BOOT --
                devDataLoad_o <= bootDataLoad_i;
            elsif (devPhysicalAddr_i >= 32ux"1fd003f8" and devPhysicalAddr_i <= 32ux"1fd003fc") then
                -- COM --
                comEnable_o <= ENABLE;
                comReadEnable_o <= not devWrite_i;
                comDataSave_o <= devDataSave_i;
                devDataLoad_o <= comDataLoad_i;
            elsif (devPhysicalAddr_i = 32ux"1fd0f000") then
                -- LED. Required by functional test --
                ledEnable_o <= ENABLE;
                ledData_o <= devDataSave_i(15 downto 0);
            elsif (devPhysicalAddr_i = 32ux"1fd0f010") then
                -- 7-seg display. Required by functional test --
                numEnable_o <= ENABLE;
                numData_o <= devDataSave_i;
            elsif (devPhysicalAddr_i >= 32ux"1fe00000" and devPhysicalAddr_i <= 32ux"1fe4afff") then
                -- VGA --
                -- designated by myself, software needed to support --
                vgaWriteEnable_o <= ENABLE;
                vgaWriteData_o <= devDataSave_i;
            elsif (devPhysicalAddr_i >= 32ux"1fe4b000" and devPhysicalAddr_i <= 32ux"1fe4b7ff") then
                -- lattice --
                ltcReadEnable_o <= ENABLE;
                devDataLoad_o <= ltcDataLoad_i;
                devBusy_o <= ltcBusy_i;
            elsif (devPhysicalAddr_i >= 32ux"1c020100" and devPhysicalAddr_i <= 32ux"1c020104") then
                -- Ethernet --
                -- 1c020100: index port; 1c020104: data port (required by U-Boot)--
                ethEnable_o <= ENABLE;
                ethReadEnable_o <= not devWrite_i;
                ethDataSave_o <= devDataSave_i;
                devDataLoad_o <= ethDataLoad_i;
                devBusy_o <= ethWriteBusy_i;
            elsif (devPhysicalAddr_i >= 32ux"1c020000" and devPhysicalAddr_i <= 32ux"1c020004") then
                -- USB --
                usbEnable_o <= ENABLE;
                usbReadEnable_o <= not devWrite_i;
                usbWriteEnable_o <= devWrite_i;
                usbWriteData_o <= devDataSave_i;
                devDataLoad_o <= usbReadData_i;
                devBusy_o <= usbBusy_i;
            end if;
        end if;
    end process;
end bhv;
