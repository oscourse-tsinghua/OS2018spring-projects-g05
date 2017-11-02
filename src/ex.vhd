library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
-- NOTE: std_logic_unsigned cannot be used at the same time with std_logic_unsigned
--       Use numeric_std if signed number is needed (different API)
use work.global_const.all;
use work.alu_const.all;
use work.mem_const.all;

entity ex is
    port (
        rst: in std_logic;
        alut_i: in AluType;
        memt_i: in MemType;
        operand1_i: in std_logic_vector(DataWidth);
        operand2_i: in std_logic_vector(DataWidth);
        operandX_i: in std_logic_vector(DataWidth);
        toWriteReg_i: in std_logic;
        writeRegAddr_i: in std_logic_vector(RegAddrWidth);
        linkAddress_i: in std_logic_vector(AddrWidth);
        isInDelaySlot_i: in std_logic;

        toStall_o: out std_logic;
        toWriteReg_o: out std_logic;
        writeRegAddr_o: out std_logic_vector(RegAddrWidth);
        writeRegData_o: out std_logic_vector(DataWidth);

        -- Hi Lo --
        hi_i, lo_i: in std_logic_vector(DataWidth);
        memToWriteHi_i, memToWriteLo_i: in std_logic;
        memWriteHiData_i, memWriteLoData_i: in std_logic_vector(DataWidth);
        wbToWriteHi_i, wbToWriteLo_i: in std_logic;
        wbWriteHiData_i, wbWriteLoData_i: in std_logic_vector(DataWidth);
        toWriteHi_o, toWriteLo_o: out std_logic;
        writeHiData_o, writeLoData_o: out std_logic_vector(DataWidth);

        -- Memory --
        memt_o: out MemType;
        memAddr_o: out std_logic_vector(AddrWidth);
        memData_o: out std_logic_vector(DataWidth);

        -- multi-period --
        tempProduct_i: in std_logic_vector(DoubleDataWidth);
        cnt_i: in std_logic_vector(CntWidth);
        tempProduct_o: out std_logic_vector(DoubleDataWidth);
        cnt_o: out std_logic_vector(CntWidth);

        -- interact with CP0 --
        cp0RegData_i: in std_logic_vector(DataWidth);
        wbCP0RegData_i: in std_logic_vector(DataWidth);
        wbCP0RegWriteAddr_i: in std_logic_vector(CP0RegAddrWidth);
        wbCP0RegWe_i: in std_logic;
        memCP0RegData_i: in std_logic_vector(DataWidth);
        memCP0RegWriteAddr_i: in std_logic_vector(CP0RegAddrWidth);
        memCP0RegWe_i: in std_logic;
        cp0RegReadAddr_o: out std_logic_vector(CP0RegAddrWidth);
        cp0RegData_o: out std_logic_vector(DataWidth);
        cp0RegWriteAddr_o: out std_logic_vector(CP0RegAddrWidth);
        cp0RegWe_o: out std_logic;

        -- for exception --
        exceptType_i: in std_logic_vector(ExceptionWidth);
        currentInstAddress_i: in std_logic_vector(ExceptionWidth);
        exceptType_o: out std_logic_vector(ExceptionWidth);
        isInDelaySlot_o: out std_logic;
        currentInstAddress_o: out std_logic_vector(AddrWidth)
    );
end ex;

architecture bhv of ex is

    function complement(x: std_logic_vector(DataWidth)) return std_logic_vector is
    begin
        return (not x) + 1;
    end complement;

    function complement64(x: std_logic_vector(DoubleDataWidth)) return std_logic_vector is
    begin
        return (not x) + 1;
    end complement64;

    function overflow(x, y: std_logic_vector(DataWidth)) return boolean is
        variable res: std_logic_vector(DataWidth);
    begin
        res := x + y;
        return ((x(31)  or y(31)) = '0' and res(31) = '1') or
               ((x(31) and y(31)) = '1' and res(31) = '0');
    end overflow;

    signal realHiData, realLoData: std_logic_vector(DataWidth) := (others => '0');
    signal clo, clz: std_logic_vector(DataWidth);

    signal multip1, multip2: std_logic_vector(DataWidth);
    signal calcMult: std_logic := '0';
    signal product: std_logic_vector(DoubleDataWidth);
    signal cp0ReadValue: std_logic_vector(DataWidth);
    signal trapAssert: std_logic;
    signal ovAssert: std_logic;
    signal reg2IMux: std_logic_vector(DataWidth);
    signal resultSum: std_logic_vector(DataWidth);
    signal ovSum: std_logic;
    signal reg1Ltreg2: std_logic;
begin

    memt_o <= memt_i;

    clo <= 32ux"00" when operand1_i(31) = '0' else 32ux"01" when operand1_i(30) = '0' else
           32ux"02" when operand1_i(29) = '0' else 32ux"03" when operand1_i(28) = '0' else
           32ux"04" when operand1_i(27) = '0' else 32ux"05" when operand1_i(26) = '0' else
           32ux"06" when operand1_i(25) = '0' else 32ux"07" when operand1_i(24) = '0' else
           32ux"08" when operand1_i(23) = '0' else 32ux"09" when operand1_i(22) = '0' else
           32ux"0a" when operand1_i(21) = '0' else 32ux"0b" when operand1_i(20) = '0' else
           32ux"0c" when operand1_i(19) = '0' else 32ux"0d" when operand1_i(18) = '0' else
           32ux"0e" when operand1_i(17) = '0' else 32ux"0f" when operand1_i(16) = '0' else
           32ux"10" when operand1_i(15) = '0' else 32ux"11" when operand1_i(14) = '0' else
           32ux"12" when operand1_i(13) = '0' else 32ux"13" when operand1_i(12) = '0' else
           32ux"14" when operand1_i(11) = '0' else 32ux"15" when operand1_i(10) = '0' else
           32ux"16" when operand1_i( 9) = '0' else 32ux"17" when operand1_i( 8) = '0' else
           32ux"18" when operand1_i( 7) = '0' else 32ux"19" when operand1_i( 6) = '0' else
           32ux"1a" when operand1_i( 5) = '0' else 32ux"1b" when operand1_i( 4) = '0' else
           32ux"1c" when operand1_i( 3) = '0' else 32ux"1d" when operand1_i( 2) = '0' else
           32ux"1e" when operand1_i( 1) = '0' else 32ux"1f" when operand1_i( 0) = '0' else
           32ux"20";
    clz <= 32ux"00" when operand1_i(31) = '1' else 32ux"01" when operand1_i(30) = '1' else
           32ux"02" when operand1_i(29) = '1' else 32ux"03" when operand1_i(28) = '1' else
           32ux"04" when operand1_i(27) = '1' else 32ux"05" when operand1_i(26) = '1' else
           32ux"06" when operand1_i(25) = '1' else 32ux"07" when operand1_i(24) = '1' else
           32ux"08" when operand1_i(23) = '1' else 32ux"09" when operand1_i(22) = '1' else
           32ux"0a" when operand1_i(21) = '1' else 32ux"0b" when operand1_i(20) = '1' else
           32ux"0c" when operand1_i(19) = '1' else 32ux"0d" when operand1_i(18) = '1' else
           32ux"0e" when operand1_i(17) = '1' else 32ux"0f" when operand1_i(16) = '1' else
           32ux"10" when operand1_i(15) = '1' else 32ux"11" when operand1_i(14) = '1' else
           32ux"12" when operand1_i(13) = '1' else 32ux"13" when operand1_i(12) = '1' else
           32ux"14" when operand1_i(11) = '1' else 32ux"15" when operand1_i(10) = '1' else
           32ux"16" when operand1_i( 9) = '1' else 32ux"17" when operand1_i( 8) = '1' else
           32ux"18" when operand1_i( 7) = '1' else 32ux"19" when operand1_i( 6) = '1' else
           32ux"1a" when operand1_i( 5) = '1' else 32ux"1b" when operand1_i( 4) = '1' else
           32ux"1c" when operand1_i( 3) = '1' else 32ux"1d" when operand1_i( 2) = '1' else
           32ux"1e" when operand1_i( 1) = '1' else 32ux"1f" when operand1_i( 0) = '1' else
           32ux"20";

    excepttype_o <= excepttype_i(31 downto 12) & ovAssert & trapAssert & excepttype_i(9 downto 8) & "00000000";
    isInDelaySlot_o <= isInDelaySlot_i;

    -- multiplication --
    process(multip1, multip2, alut_i, calcMult)
        variable m1, m2: std_logic_vector(DataWidth);
        variable ans: std_logic_vector(DoubleDataWidth);
        variable sgnMul: boolean;
        variable neg: boolean;
    begin
        if (alut_i = ALU_MULTU or alut_i = ALU_MADDU or alut_i = ALU_MSUBU) then
            sgnMul := false;
        else
            sgnMul := true;
        end if;

        neg := false;
        if (calcMult = '1') then
            if (sgnMul and multip1(31) = '1') then
                m1 := complement(multip1);
                neg := not neg;
            else
                m1 := multip1;
            end if;
            if (sgnMul and multip2(31) = '1') then
                m2 := complement(multip2);
                neg := not neg;
            else
                m2 := multip2;
            end if;
        end if;

        ans := m1 * m2;
        if (neg) then
            product <= complement64(ans);
        else
            product <= ans;
        end if;
    end process;

    -- hi lo --
    process(all) begin
        if (rst = RST_ENABLE) then
            realHiData <= (others => '0');
            realLoData <= (others => '0');
        else
            realHiData <= hi_i;
            realLoData <= lo_i;
            if (wbToWriteHi_i = YES) then
                realHiData <= wbWriteHiData_i;
            end if;
            if (memToWriteHi_i = YES) then
                realHiData <= memWriteHiData_i;
            end if;
            if (wbToWriteLo_i = YES) then
                realLoData <= wbWriteLoData_i;
            end if;
            if (memToWriteLo_i = YES) then
                realLoData <= memWriteLoData_i;
            end if;
        end if;
    end process;

    process(all)
        variable res: std_logic_vector(DataWidth);
        variable res64: std_logic_vector(DoubleDataWidth);
    begin
        toWriteHi_o <= NO;
        toWriteLo_o <= NO;
        toWriteReg_o <= toWriteReg_i;
        memAddr_o <= (others => '0');
        memData_o <= (others => '0');
        writeRegAddr_o <= (others => '0');
        writeRegData_o <= (others => '0');
        toStall_o <= PIPELINE_NONSTOP;
        calcMult <= '0';
        tempProduct_o <= (others => '0');
        cnt_o <= (others => '0');
        cp0RegWe_o <= NO;
        cp0ReadValue <= (others => '0');
        cp0RegWriteAddr_o <= (others => '0');
        cp0RegData_o <= (others => '0');

        if (rst = RST_DISABLE) then
            if (alut_i = ALU_SUB or alut_i = ALU_SUBU or alut_i = ALU_SLT) then
                reg2IMux <= not(operand2_i) + 1;
            else
                reg2IMux <= operand2_i;
            end if;
            resultSum <= to_stdlogicvector(to_integer(operand1_i) + to_integer(reg2IMux)); 
            ovSum <= ((not operand1_i(31) and not(reg2IMux(31)) and resultSum(31)) or ((operand1_i(31)) and (reg2IMux(31))) and (not(resultSum(31))));
            writeRegAddr_o <= writeRegAddr_i;
            case alut_i is
                when ALU_OR => writeRegData_o <= operand1_i or operand2_i;
                when ALU_AND => writeRegData_o <= operand1_i and operand2_i;
                when ALU_XOR => writeRegData_o <= operand1_i xor operand2_i;
                when ALU_NOR => writeRegData_o <= operand1_i nor operand2_i;
                when ALU_SLL => writeRegData_o <= operand2_i sll to_integer(unsigned(operand1_i));
                when ALU_SRL => writeRegData_o <= operand2_i srl to_integer(unsigned(operand1_i));
                when ALU_SRA => writeRegData_o <= to_stdlogicvector(to_bitvector(operand2_i) sra to_integer(unsigned(operand1_i)));
                when ALU_LUI => writeRegData_o <= operand1_i(15 downto 0) & 16b"0";
                when ALU_JALR => writeRegData_o <= linkAddress_i;
                when ALU_JAL => writeRegData_o <= linkAddress_i;

                when ALU_MOVN =>
                    if (operand2_i /= ZEROS_32) then
                        writeRegData_o <= operand1_i;
                    else
                        toWriteReg_o <= NO;
                        writeRegData_o <= (others => '0');
                    end if;

                when ALU_MOVZ =>
                    if (operand2_i = ZEROS_32) then
                        writeRegData_o <= operand1_i;
                    else
                        toWriteReg_o <= NO;
                        writeRegData_o <= (others => '0');
                    end if;

                when ALU_MFHI =>
                    writeRegData_o <= realHiData;

                when ALU_MFLO =>
                    writeRegData_o <= realLoData;

                when ALU_MTHI =>
                    toWriteHi_o <= YES;
                    writeHiData_o <= operand1_i;

                when ALU_MTLO =>
                    toWriteLo_o <= YES;
                    writeLoData_o <= operand1_i;

                when ALU_LOAD =>
                    memAddr_o <= operand1_i + operandX_i;

                when ALU_STORE =>
                    memAddr_o <= operand1_i + operandX_i;
                    memData_o <= operand2_i;

                when ALU_ADD =>
                    if (overflow(operand1_i, operand2_i)) then
                        toWriteReg_o <= NO;
                        writeRegData_o <= (others => '0');
                    else
                        writeRegData_o <= operand1_i + operand2_i;
                    end if;

                when ALU_ADDU =>
                    writeRegData_o <= operand1_i + operand2_i;

                when ALU_SUB =>
                    if (overflow(operand1_i, complement(operand2_i))) then
                        toWriteReg_o <= NO;
                        writeRegData_o <= (others => '0');
                    else
                        writeRegData_o <= operand1_i - operand2_i;
                    end if;

                when ALU_SUBU =>
                    writeRegData_o <= operand1_i - operand2_i;

                when ALU_SLT =>
                    res := operand1_i - operand2_i;
                    if (not overflow(operand1_i, complement(operand2_i))) then
                        writeRegData_o <= ZEROS_31 & res(31);
                    else
                        writeRegData_o <= ZEROS_31 & (not res(31));
                    end if;

                when ALU_SLTU =>
                    if (operand1_i < operand2_i) then
                        writeRegData_o <= ZEROS_31 & '1';
                    else
                        writeRegData_o <= ZEROS_31 & '0';
                    end if;

                when ALU_CLO => writeRegData_o <= clo;

                when ALU_CLZ => writeRegData_o <= clz;

                when ALU_MUL =>
                    calcMult <= '1';
                    multip1 <= operand1_i;
                    multip2 <= operand2_i;
                    writeRegData_o <= product(LoDataWidth);

                when ALU_MULT =>
                    calcMult <= '1';
                    multip1 <= operand1_i;
                    multip2 <= operand2_i;
                    toWriteHi_o <= YES;
                    writeHiData_o <= product(HiDataWidth);
                    toWriteLo_o <= YES;
                    writeLoData_o <= product(LoDataWidth);

                when ALU_MULTU =>
                    calcMult <= '1';
                    multip1 <= operand1_i;
                    multip2 <= operand2_i;
                    toWriteHi_o <= YES;
                    writeHiData_o <= product(HiDataWidth);
                    toWriteLo_o <= YES;
                    writeLoData_o <= product(LoDataWidth);

                when ALU_MADD|ALU_MADDU|ALU_MSUB|ALU_MSUBU =>
                    if (cnt_i = "00") then
                        calcMult <= '1';
                        multip1 <= operand1_i;
                        multip2 <= operand2_i;
                        tempProduct_o <= product;
                        cnt_o <= "01";
                        toStall_o <= PIPELINE_STOP;
                    elsif (cnt_i = "01") then
                        calcMult <= '0';
                        tempProduct_o <= (others => '0');
                        cnt_o <= "00";
                        toStall_o <= PIPELINE_NONSTOP;
                        toWriteHi_o <= YES;
                        toWriteLo_o <= YES;
                        if (alut_i = ALU_MADD or alut_i = ALU_MADDU) then
                            res64 := (realHiData & realLoData) + tempProduct_i;
                        elsif (alut_i = ALU_MSUB or alut_i = ALU_MSUBU) then
                            res64 := (realHiData & realLoData) - tempProduct_i;
                        end if;
                        writeHiData_o <= res64(HiDataWidth);
                        writeLoData_o <= res64(LoDataWidth);
                    end if;

                when ALU_MFC0 =>
                    cp0RegReadAddr_o <= operand1_i(4 downto 0);
                    cp0ReadValue <= cp0RegData_i;

                    -- Push forward for cp0 --
                    if (memCP0RegWe_i = YES and memCP0RegWriteAddr_i = operand1_i(4 downto 0)) then
                        cp0ReadValue <= memCP0RegData_i;
                    elsif (wbCP0RegWe_i = YES and wbCP0RegWriteAddr_i = operand1_i(4 downto 0)) then
                        cp0ReadValue <= wbCP0RegData_i;
                    end if;

                    writeRegData_o <= cp0ReadValue;
                
                when ALU_MTC0 =>
                    cp0RegWriteAddr_o <= operand1_i(4 downto 0);
                    cp0RegWe_o <= YES;
                    cp0RegData_o <= operand2_i;

                when others =>
                    toWriteReg_o <= NO;
            end case;
            if (((alut_i = ALU_ADD) or (alut_i = ALU_SUB)) and (ovSum = YES)) then
                toWriteReg_o <= NO;
                ovAssert <= YES;
            else
                toWriteReg_o <= YES;
                ovAssert <= NO;
            end if;
        end if;
    end process;

end bhv;
