library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
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
		fpMemAddr_o: out std_logic_vector(AddrWidth)
	);
end float_alu;

architecture bhv of float_alu is
	function singleabs(x: std_logic_vector(DataWidth)) return std_logic_vector is
	begin
		return 32ub"0" & '1' & x(30 downto 0);
	end singleabs;

	function doubleabs(x: std_logic_vector(DoubleDataWidth)) return std_logic_vector is
	begin
		return '1' & x(62 downto 0);
	end doubleabs;

	function singleneg(x: std_logic_vector(DataWidth)) return std_logic_vector is
	begin
		return 32ub"0" & not x(31) & x(30 downto 0);
	end singleneg;

	function doubleneg(x: std_logic_vector(DoubleDataWidth)) return std_logic_vector is
	begin
		return not x(63) & x(62 downto 0);
	end doubleneg;
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
		if (floatEnable = true) then
			writeFPDouble_o <= writeFPDouble_i;
			fpMemt_o <= fpMemt_i;
			case(fpAlut_i) is
				when FPALU_ABS =>
					if (writeFPDouble_i = NO) then
						writeFPRegData_o <= singleabs(foperand1_i(31 downto 0));
					else
						writeFPRegData_o <= doubleabs(foperand1_i);
					end if;
				
				when FPALU_NEG =>
					if (writeFPDouble_i = NO) then
						writeFPRegData_o <= singleneg(foperand1_i(31 downto 0));
					else
						writeFPRegData_o <= doubleneg(foperand1_i);
					end if;

				when CF =>
					fpWriteTarget_o <= REG;
					toWriteFPReg_o <= YES;
					writeFPRegAddr_o <= 27ub"0" & writeFPRegAddr_i;
					writeFPRegData_o <= 32ub"0" & foperand2_i(31 downto 0);

				when CT =>
					fpWriteTarget_o <= FREG;
					toWriteFPReg_o <= YES;
					writeFPRegAddr_o <= 27ub"0" & writeFPRegAddr_i;
					writeFPRegData_o <= 32ub"0" & foperand1_i(31 downto 0);

				when MF =>
					fpWriteTarget_o <= REG;
					cp1RegReadAddr_o <= foperand2_i(4 downto 0);
					toWriteFPReg_o <= YES;
					writeFPRegAddr_o <= 27ub"0" & writeFPRegAddr_i;
					writeFPRegData_o <= 32ub"0" & data_i;

				when MT =>
					fpWriteTarget_o <= CP1;
					toWriteFPReg_o <= YES;
					writeFPRegAddr_o <= 27ub"0" & writeFPRegAddr_i;
					writeFPRegData_o <= foperand1_i;

				when FP_LOAD | FP_STORE =>
					fpWriteTarget_o <= FREG;
					fpMemAddr_o <= to_stdlogicvector(foperand1_i(31 downto 0) + to_integer(signed(foperand2_i(15 downto 0))));

				when others =>
					null;
			end case;
		end if;
	end process;
end bhv;