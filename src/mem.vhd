library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.global_const.all;
use work.mem_const.all;
use work.cp0_const.all;
use work.except_const.all;

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
        writeHiData_o, writeLoData_o: out std_logic_vector(DataWidth);

        -- Memory --
        memt_i: in MemType;
        memAddr_i: in std_logic_vector(AddrWidth);
        memData_i: in std_logic_vector(DataWidth); -- Data to store
        memExcept_i: in std_logic_vector(ExceptionCauseWidth);
        loadedData_i: in std_logic_vector(DataWidth); -- Data loaded from RAM
        savingData_o: out std_logic_vector(DataWidth);
        memAddr_o: out std_logic_vector(AddrWidth);
        dataEnable_o: out std_logic;
        dataWrite_o: out std_logic;
        dataByteSelect_o: out std_logic_vector(3 downto 0);

        -- interact with cp0 --
        cp0RegData_i: in std_logic_vector(DataWidth);
        cp0RegWriteAddr_i: in std_logic_vector(CP0RegAddrWidth);
        cp0RegWriteSel_i: in std_logic_vector(SelWidth);
        cp0RegWe_i: in std_logic;
        cp0Sp_i: in CP0Special;
        cp0RegData_o: out std_logic_vector(DataWidth);
        cp0RegWriteAddr_o: out std_logic_vector(CP0RegAddrWidth);
        cp0RegWriteSel_o: out std_logic_vector(SelWidth);
        cp0RegWe_o: out std_logic;
        cp0Sp_o: out CP0Special;

        -- for exception --
        valid_i: in std_logic;
        exceptCause_i: in std_logic_vector(ExceptionCauseWidth);
        isInDelaySlot_i: in std_logic;
        currentInstAddr_i: in std_logic_vector(AddrWidth);
        cp0Status_i, cp0Cause_i: in std_logic_vector(DataWidth);
        exceptCause_o: out std_logic_vector(ExceptionCauseWidth);
        isInDelaySlot_o: out std_logic;
        currentInstAddr_o: out std_logic_vector(AddrWidth);
        currentAccessAddr_o: out std_logic_vector(AddrWidth);

        -- for sync --
        scCorrect_i: in std_logic;
        sync_o: out std_logic_vector(2 downto 0) -- bit0 for ll, bit1 for sc, 2 for flush caused by eret
    );
end mem;

architecture bhv of mem is
    signal dataWrite: std_logic;
    signal interrupt: std_logic_vector(ExceptionCauseWidth);
begin
    memAddr_o <= memAddr_i(31 downto 2) & "00";
    isInDelaySlot_o <= isInDelaySlot_i;
    currentInstAddr_o <= currentInstAddr_i;
    -- When IF has an exception, memt_i must be INVALID
    currentAccessAddr_o <= currentInstAddr_i when memt_i = INVALID else memAddr_i;
    -- We preserve the low 2 bits for `lw` and `sw` as required by BadVAddr register
    -- `lh`, `lhu` and `sh` likewise

    cp0Sp_o <= cp0Sp_i;

    process(all)
        variable loadedByte: std_logic_vector(7 downto 0);
        variable loadedShort: std_logic_vector(15 downto 0);
        variable loadedMask: std_logic_vector(31 downto 0);
    begin
        savingData_o <= (others => '0');
        dataEnable_o <= DISABLE;
        dataWrite <= NO;
        dataByteSelect_o <= "0000";
        loadedByte := (others => '0');
        loadedShort := (others => '0');
        loadedMask := (others => '0');

        if (rst = RST_ENABLE) then
            toWriteReg_o <= NO;
            writeRegAddr_o <= (others => '0');
            writeRegData_o <= (others => '0');

            toWriteHi_o <= NO;
            toWriteLo_o <= NO;
            writeHiData_o <= (others => '0');
            writeLoData_o <= (others => '0');

            cp0RegWe_o <= NO;
            cp0RegWriteAddr_o <= (others => '0');
            cp0RegWriteSel_o <= (others => '0');
            cp0RegData_o <= (others => '0');
            sync_o <= (others => '0');
        else
            toWriteReg_o <= toWriteReg_i;
            writeRegAddr_o <= writeRegAddr_i;
            writeRegData_o <= writeRegData_i;

            toWriteHi_o <= toWriteHi_i;
            toWriteLo_o <= toWriteLo_i;
            writeHiData_o <= writeHiData_i;
            writeLoData_o <= writeLoData_i;

            cp0RegWe_o <= cp0RegWe_i;
            cp0RegWriteAddr_o <= cp0RegWriteAddr_i;
            cp0RegWriteSel_o <= cp0RegWriteSel_i;
            cp0RegData_o <= cp0RegData_i;

            sync_o(2) <= '1' when exceptCause_i = ERET_CAUSE else '0';
            sync_o(1) <= '1' when memt_i = MEM_SC else '0';
            sync_o(0) <= '1' when memt_i = MEM_LL else '0';

            if (exceptCause_i = NO_CAUSE) then
                -- Byte selection --
                case memt_i is
                    when MEM_LW|MEM_SW|MEM_LL|MEM_SC =>
                        savingData_o <= memData_i;
                        dataByteSelect_o <= "1111";
                    when MEM_LWL|MEM_SWL =>
                        savingData_o <= memData_i;
                        case memAddr_i(1 downto 0) is
                            when "00" =>
                                loadedMask := 32ux"00_00_00_ff";
                                dataByteSelect_o <= "0001"; -- Read this from right(low) to left(high)!!
                            when "01" =>
                                loadedMask := 32ux"00_00_ff_ff";
                                dataByteSelect_o <= "0011";
                            when "10" =>
                                loadedMask := 32ux"00_ff_ff_ff";
                                dataByteSelect_o <= "0111";
                            when "11" =>
                                loadedMask := 32ux"ff_ff_ff_ff";
                                dataByteSelect_o <= "1111";
                            when others =>
                                -- Although there is actually no other cases
                                -- But the simulator thinks something like 'Z' should be considered
                                null;
                        end case;
                    when MEM_LWR|MEM_SWR =>
                        savingData_o <= memData_i;
                        case memAddr_i(1 downto 0) is
                            when "00" =>
                                loadedMask := 32ux"ff_ff_ff_ff";
                                dataByteSelect_o <= "1111";
                            when "01" =>
                                loadedMask := 32ux"ff_ff_ff_00";
                                dataByteSelect_o <= "1110";
                            when "10" =>
                                loadedMask := 32ux"ff_ff_00_00";
                                dataByteSelect_o <= "1100";
                            when "11" =>
                                loadedMask := 32ux"ff_00_00_00";
                                dataByteSelect_o <= "1000";
                            when others =>
                                null;
                        end case;
                    when MEM_LB|MEM_LBU|MEM_SB =>
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
                            when others =>
                                null;
                        end case;
                    when MEM_LH|MEM_LHU|MEM_SH =>
                        if (memAddr_i(1) = '0') then
                            savingData_o <= 16b"0" & memData_i(15 downto 0);
                            loadedShort := loadedData_i(15 downto 0);
                            dataByteSelect_o <= "0011";
                        else
                            savingData_o <= memData_i(15 downto 0) & 16b"0";
                            loadedShort := loadedData_i(31 downto 16);
                            dataByteSelect_o <= "1100";
                        end if;
                    when others =>
                        null;
                end case;

                case memt_i is
                    when MEM_LB => -- toWriteReg_o is already YES
                        writeRegData_o <= std_logic_vector(resize(signed(loadedByte), 32));
                        dataEnable_o <= ENABLE;
                    when MEM_LBU =>
                        writeRegData_o <= std_logic_vector(resize(unsigned(loadedByte), 32));
                        dataEnable_o <= ENABLE;
                    when MEM_LH =>
                        writeRegData_o <= std_logic_vector(resize(signed(loadedShort), 32));
                        dataEnable_o <= ENABLE;
                    when MEM_LHU =>
                        writeRegData_o <= std_logic_vector(resize(unsigned(loadedShort), 32));
                        dataEnable_o <= ENABLE;
                    when MEM_LW|MEM_LL =>
                        writeRegData_o <= loadedData_i;
                        dataEnable_o <= ENABLE;
                    when MEM_LWL|MEM_LWR =>
                        writeRegData_o <= (loadedData_i and loadedMask) or (memData_i and not loadedMask);
                        dataEnable_o <= ENABLE;
                    when MEM_SB|MEM_SH|MEM_SW|MEM_SWL|MEM_SWR =>
                        dataWrite <= YES;
                        dataEnable_o <= ENABLE;
                    when MEM_SC =>
                        dataWrite <= YES;
                        dataEnable_o <= ENABLE;
                        writeRegData_o <= 31ub"0" & scCorrect_i;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    interrupt <= EXTERNAL_CAUSE when
                    valid_i = YES and
                    (cp0Cause_i(CauseIpBits) and cp0Status_i(StatusImBits)) /= 8ux"0" and
                    cp0Status_i(STATUS_EXL_BIT) = NO and
                    cp0Status_i(STATUS_ERL_BIT) = NO and
                    cp0Status_i(STATUS_IE_BIT) = YES
                 else
                    NO_CAUSE;

    dataWrite_o <= dataWrite when
                   (exceptCause_i and interrupt) = NO_CAUSE else
                   NO;
    -- NOTE: dataWrite_o should not depend on memExcept_i, or there might be an oscillation

    exceptCause_o <= interrupt when
                     interrupt /= NO_CAUSE else
                     exceptCause_i and memExcept_i;
    -- If exceptCause_i /= NO_CAUSE, there won't be any memory access, so memExcept_i should be NO_CAUSE
end bhv;
