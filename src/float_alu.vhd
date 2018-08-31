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
		operand1_i: in std_logic_vector(DoubleDataWidth);
		operand2_i: in std_logic_vector(DoubleDataWidth);
		type1_i: in FOprSrcType;
		type2_i: in FOprSrcType;
		toWriteReg_i: in std_logic;
		toWriteRegAddr_i: in std_logic_vector(CP1RegAddrWidth);
		toWriteReg_o: out std_logic;
		toWriteRegAddr_o: out std_logic_vector(CP1RegAddrWidth);
		toWriteRegData_o: out std_logic_vector(DoubleDataWidth);
		exceptFlags: out FloatExceptType;
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
		if (floatEnable = true) then
			toWriteReg_o <= toWriteReg_i;
			toWriteRegAddr_o <= toWriteRegAddr_i;
			case(alut_i) is
				when FPALU_ABS =>
					if (type1_i = SINGLE) then
						toWriteRegData_o <= singleabs(operand1_i(31 downto 0));
					else
						toWriteRegData_o <= doubleabs(operand1_i);
					end if;
				when FPALU_NEG =>
					if (type1_i = SINGLE) then
						toWriteRegData_o <= singleneg(operand1_i(31 downto 0));
					else
						toWriteRegData_o <= doubleneg(operand1_i);
					end if;
				when others =>
					null;
			end case;
		end if;
	end process;
end bhv;