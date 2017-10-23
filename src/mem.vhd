library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.mem_const.all;

entity mem is
    port (
        rst: in std_logic;
        toWriteReg_i: in std_logic;
        writeRegAddr_i: in std_logic_vector(RegAddrWidth);
        writeRegData_i: in std_logic_vector(DataWidth);
        toWriteReg_o: out std_logic;
        writeRegAddr_o: out std_logic_vector(RegAddrWidth);
        writeRegData_o: out std_logic_vector(DataWidth);

        -- Hi Lo --
        toWriteHi_i, toWriteLo_i: in std_logic;
        writeHiData_i, writeLoData_i: in std_logic_vector(DataWidth);
        toWriteHi_o, toWriteLo_o: out std_logic;
        writeHiData_o, writeLoData_o: out std_logic_vector(DataWidth)

        -- Memory --
        memt_i: in MemType;
        memAddr_i: in std_logic_vector(AddrWidth);
        memData_i: in std_logic_vector(DataWidth); -- Data to store
        loadedData_i: in std_logic_vector(DataWidth); -- Data loaded from RAM
        savingData_o: out std_logic_vector(DataWidth);
        memAddr_o: out std_logic_vector(AddrWidth);
        dataEnable_o: out std_logic;
        dataWrite_o: out std_logic;
        dataByteSelect_o: out std_logic_vector(3 downto 0);
    );
end mem;

architecture bhv of mem is
begin
    memAddr_o <= memAddr_i(31 downto 2) & "00";

    process(all)
        variable loadedByte: std_logic_vector(7 downto 0);
    begin
        savingData_o <= (others => '0');
        dataEnable_o <= DISABLE;
        dataWrite_o <= NO;
        dataByteSelect_o <= "0000";
        loadedByte := (others => '0');

        if (rst = RST_ENABLE) then
            toWriteReg_o <= NO;
            writeRegAddr_o <= (others => '0');
            writeRegData_o <= (others => '0');

            toWriteHi_o <= NO;
            toWriteLo_o <= NO;
            writeHiData_o <= (others => '0');
            writeLoData_o <= (others => '0');
        else
            toWriteReg_o <= toWriteReg_i;
            writeRegAddr_o <= writeRegAddr_i;
            writeRegData_o <= writeRegData_i;

            toWriteHi_o <= toWriteHi_i;
            toWriteLo_o <= toWriteLo_i;
            writeHiData_o <= writeHiData_i;
            writeLoData_o <= writeLoData_i;

            -- Byte selection --
            if ((memt_i = MEM_LW) or (memt_i = MEM_SW))
                savingData_o <= memData_i;
                dataByteSelect_o <= "1111";
            end if;
            if ((memt_i = MEM_LB) or (memt_i = MEM_LBU) or (memt_i = MEM_SB))
                case memAddr_i(1 downto 0) is
                    when "00" =>
                        savingData_o <= 24b"0" & memData_i(7 downto 0);
                        loadedByte := loadedData_i(7 downto 0);
                        dataByteSelect_o <= "0001";
                    when "01" =>
                        savingData_o <= 16b"0" & memData_i(7 downto 0) & 8b"0";
                        loadedByte := loadedData_i(15 downto 8);
                        dataByteSelect_o <= "0010";
                    when "10" =>
                        savingData_o <= 8b"0" & memData_i(7 downto 0) & 16b"0";
                        loadedByte := loadedData_i(23 downto 16);
                        dataByteSelect_o <= "0100";
                    when "11" =>
                        savingData_o <= memData_i(7 downto 0) & 24b"0";
                        loadedByte := loadedData_i(31 downto 24);
                        dataByteSelect_o <= "1000";
                end case;
            end if;

            case memt_i is
                when MEM_LB => -- toWriteReg_o is already YES
                    writeRegData_o <= (31 downto 8 => loadedByte(7), 7 downto 0 => loadedByte);
                    dataEnable_o <= ENABLE;
                when MEM_LBU =>
                    writeRegData_o <= (31 downto 8 => '0', 7 downto 0 => loadedByte);
                    dataEnable_o <= ENABLE;
                when MEM_LW =>
                    writeRegData_o <= loadedData_i;
                    dataEnable_o <= ENABLE;
                when MEM_SB =>
                    dataWrite_o <= YES;
                    dataEnable_o <= ENABLE;
                when MEM_SW =>
                    dataWrite_o <= YES;
                    dataEnable_o <= ENABLE;
                when others =>
                    null;
            end case;
        end if;
    end process;
end bhv;
