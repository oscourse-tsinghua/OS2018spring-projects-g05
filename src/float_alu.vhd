library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;
use work.global_const.all;
use work.alu_const.all;
use work.cp1_const.all;
use work.mem_const.all;

entity float_alu is
	generic(
		floatEnable: boolean
	);
	port (
		rst: in std_logic;
		fpAlut_i: in FPAluType;
		fpMemt_i: in FPMemType;
		foperand1_i: in std_logic_vector(DoubleDataWidth);
		foperand2_i: in std_logic_vector(DoubleDataWidth);
		operand1_i: in std_logic_vector(DataWidth);
		operand2_i: in std_logic_vector(DataWidth);
		operandX_i: in std_logic_vector(DataWidth);
		toWriteFPReg_i: in std_logic;
		writeFPRegAddr_i: in std_logic_vector(RegAddrWidth);
		writeFPDouble_i: in std_logic;
		toWriteFPReg_o: out std_logic;
		writeFPRegAddr_o: out std_logic_vector(AddrWidth);
		writeFPRegData_o: out std_logic_vector(DoubleDataWidth);
		fpWriteTarget_o: out FloatTargetType;
		writeFPDouble_o: out std_logic;
		exceptFlags_o: out FloatExceptType;
		toStall_o: out std_logic;
		cp1RegReadAddr_o: out std_logic_vector(RegAddrWidth);
		data_i: in std_logic_vector(DataWidth);
		fpMemt_o: out FPMemType;
		fpMemAddr_o: out std_logic_vector(AddrWidth);
		fpMemData_o: out std_logic_vector(DoubleDataWidth)
	);
end float_alu;

architecture bhv of float_alu is
	function doubleadd(a: std_logic_vector(DoubleDataWidth);
					   b: std_logic_vector(DoubleDataWidth)) return std_logic_vector is
	variable dataindex: std_logic_vector(53 downto 0);
	begin
		if (a(62 downto 52) > b(62 downto 52)) then
			dataindex := "01" & a(51 downto 0);
			dataindex := to_stdlogicvector(dataindex + ("01" & b(51 downto 0)) srl (
						 to_integer(unsigned(a(62 downto 52)) - unsigned(b(62 downto 52)))));
		else
			dataindex := "01" & b(51 downto 0);
			dataindex := to_stdlogicvector(dataindex + ("01" & a(51 downto 0)) srl (
						 to_integer(unsigned(b(62 downto 52)) - unsigned(a(62 downto 52)))));
		end if;
		if (dataindex(53) = '1') then
			return a(63) & (a(62 downto 52) + 1) & dataindex(52 downto 1);
		else
			return a(63 downto 52) & dataindex(51 downto 0);
		end if;
	end doubleadd;

	function doublesub(a: std_logic_vector(DoubleDataWidth);
					   b: std_logic_vector(DoubleDataWidth)) return std_logic_vector is
	variable dataindex: std_logic_vector(53 downto 0);
	variable powerindex: std_logic_vector(10 downto 0);
	variable count: integer;
	variable haveone: std_logic;
	begin
		if (a(62 downto 0) > b(62 downto 0)) then
			dataindex := "01" & a(51 downto 0);
			dataindex := to_stdlogicvector(dataindex - ("01" & b(51 downto 0)) srl (
						 to_integer(unsigned(a(62 downto 52)) - unsigned(b(62 downto 52)))));
			haveone := '0';
	        for i in 52 downto 0 loop
    	        if haveone = '0' and dataindex(i) /= '0' then
    	        	count := i;
    	        	haveone := '1';
    	        end if;
        	end loop;
        	dataindex := dataindex sll (52 - count);
        	return a(63) & (a(62 downto 52) - 52 + count) & dataindex(51 downto 0);
		else
			dataindex := "01" & b(51 downto 0);
			dataindex := to_stdlogicvector(dataindex - ("01" & a(51 downto 0)) srl (
						 to_integer(unsigned(b(62 downto 52)) - unsigned(a(62 downto 52)))));
			haveone := '0';
	        for i in 52 downto 0 loop
    	        if haveone = '0' and dataindex(i) /= '0' then
    	        	count := i;
    	        	haveone := '1';
    	        end if;
        	end loop;
        	dataindex := dataindex sll (52 - count);
        	return not a(63) & (b(62 downto 52) - 52 + count) & dataindex(51 downto 0);
		end if;
	end doublesub;
begin
	process(all) begin
		toWriteFPReg_o <= NO;
		writeFPRegAddr_o <= (others => '0');
		writeFPRegData_o <= (others => '0');
		writeFPDouble_o <= NO;
		fpWriteTarget_o <= INVALID;
		exceptFlags_o <= NONE;
		toStall_o <= NO;
		fpMemt_o <= INVALID;
		fpMemAddr_o <= (others => '0');
		fpMemData_o <= (others => '0');
		if (floatEnable = true) then
			writeFPDouble_o <= writeFPDouble_i;
			fpMemt_o <= fpMemt_i;
			case(fpAlut_i) is

				when MF =>
					fpWriteTarget_o <= REG;
					toWriteFPReg_o <= YES;
					writeFPRegAddr_o <= 27ub"0" & writeFPRegAddr_i;
					writeFPRegData_o <= foperand2_i;

				when MT =>
					fpWriteTarget_o <= FREG;
					toWriteFPReg_o <= YES;
					writeFPRegAddr_o <= 27ub"0" & writeFPRegAddr_i;
					writeFPRegData_o <= 32ub"0" & operand2_i(31 downto 0);

				when CF =>
					fpWriteTarget_o <= REG;
					cp1RegReadAddr_o <= foperand2_i(4 downto 0);
					toWriteFPReg_o <= YES;
					writeFPRegAddr_o <= 27ub"0" & writeFPRegAddr_i;
					writeFPRegData_o <= 32ub"0" & data_i;

				when CT =>
					fpWriteTarget_o <= CP1;
					toWriteFPReg_o <= YES;
					writeFPRegAddr_o <= 27ub"0" & writeFPRegAddr_i;
					writeFPRegData_o <= 32ub"0" & operand2_i;

				when FP_STORE =>
					fpMemAddr_o <= to_stdlogicvector(operand1_i(31 downto 0) + to_integer(signed(operandX_i(15 downto 0))));
					fpMemData_o <= foperand1_i;

				when FP_LOAD =>
					toWriteFPReg_o <= YES;
					writeFPRegAddr_o <= 27ub"0" & writeFPRegAddr_i;
					fpWriteTarget_o <= FREG;
					fpMemAddr_o <= to_stdlogicvector(operand1_i(31 downto 0) + to_integer(signed(operandX_i(15 downto 0))));

				when ADD =>
					toWriteFPReg_o <= YES;
					writeFPRegAddr_o <= 27ub"0" & writeFPRegAddr_i;
					fpWriteTarget_o <= FREG;
					if foperand1_i(63) = foperand2_i(63) then
						writeFPRegData_o <= doubleadd(foperand1_i, foperand2_i);
					else
						writeFPRegData_o <= doublesub(foperand1_i, not foperand2_i(63) & foperand2_i(62 downto 0));
					end if;

				when SUB =>
					toWriteFPReg_o <= YES;
					writeFPRegAddr_o <= 27ub"0" & writeFPRegAddr_i;
					fpWriteTarget_o <= FREG;
					if foperand1_i(63) /= foperand2_i(63) then
						writeFPRegData_o <= doubleadd(foperand1_i, not foperand2_i(63) & foperand2_i(62 downto 0));
					else
						writeFPRegData_o <= doublesub(foperand1_i, foperand2_i);
					end if;

				when others =>
					null;
			end case;
		end if;
	end process;
end bhv;