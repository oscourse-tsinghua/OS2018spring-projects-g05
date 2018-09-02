library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.global_const.all;
use work.alu_const.all;
use work.cp1_const.all;

entity float_alu is
	generic(
		floatEnable: boolean
	);
	port (
		rst: in std_logic;
		alut_i: in FPAluType;
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
		toStall_o: out std_logic
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
		if (floatEnable = true) then
			writeFPDouble_o <= writeFPDouble_i;
			case(alut_i) is
				when FPALU_ABS =>
					if (writeFPDouble_i = NO) then
						toWriteRegData_o <= singleabs(operand1_i(31 downto 0));
					else
						toWriteRegData_o <= doubleabs(operand1_i);
					end if;
				
				when FPALU_NEG =>
					if (writeFPDouble_i = NO) then
						toWriteRegData_o <= singleneg(operand1_i(31 downto 0));
					else
						toWriteRegData_o <= doubleneg(operand1_i);
					end if;

				when CF =>
					fpWriteTarget <= REG;
					toWriteReg_o <= YES;
					writeRegAddr_o <= 27ub"0" & writeFPRegAddr_i;
					writeFPRegData_o <= 32ub"0" & operand1_i;

				when CT =>
					fpWriteTarget <= FREG;
					toWriteFPReg_o <= YES;
					writeFPRegAddr_o <= 27ub"0" & writeFPRegAddr_i;
					writeFPRegData_o <= 32ub"0" & operand2_i;

				when others =>
					null;
			end case;
		end if;
	end process;
end bhv;