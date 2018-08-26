library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.global_const.all;
use work.cp1_const.all;
use work.config_const.all;

entity cp1_reg is
	generic(
		extraReg: boolean;
		cpuId: std_logic_vector(9 downto 0)
	);
	port(
		rst, clk: in std_logic;

		we_i: in std_logic;
		waddr_i: in std_logic_vector(CP1RegAddrWidth);
		raddr_i: in std_logic_vector(CP1RegAddrWidth);
		data_i: in std_logic_vector(DataWidth);
		data_o: out std_logic_vector(DataWidth)
	);
end cp1_reg;

architecture bhv of cp1_reg is
	-- to keep the naming rule consistent with CP0, but not using that much registers
	-- NOTE: fir is const
	signal fcsrCur, fcsrReg: std_logic_vector(DataWidth);
begin
	EXTRA: if extraReg generate
		process (all) begin
			firCur <= firReg;
			fcsrCur <= fcsrReg;
			if (rst = RST_DISABLE and we_i = ENABLE) then
				case (conv_integer(waddr_i(4 downto 0))) is
					-- fir is read-only
					when FCSR_REG =>
						fcsrCur(FCSRFCCBits) <= data_i(FCSRFCCBits);
						fcsrCur(FCSR_FS_BIT) <= data_i(FSCR_FS_BIT);
						fcsrCur(FCSR_FCC1_BIT) <= data_i(FCSR_FCC1_BIT);
						fcsrCur(FCSRCauseBits) <= data_i(FCSRCauseBits);
						fcsrCur(FCSREnablesBits) <= data_i(FCSREnablesBits);
						fcsrCur(FCSRFlagsBits) <= data_i(FCSRFlagsBits);
						fcsrCur(FCSRRMBits) <= data_i(FCSRRMBits);
					when FEXR_REG =>
						fcsrCur(FCSRCauseBits) <= data_i(FCSRCauseBits);
						fcsrCur(FCSRFlagsBits) <= data_i(FCSRFlagsBits);
					when FENR_REG =>
						fcsrCur(FCSREnablesBits) <= data_i(FCSREnablesBits);
						fcsrCur(FCSR_FS_BIT) <= data_i(2);
						fcsrCur(FCSRRMBits) <= data_i(FCSRRMBits);
					when FCCR_REG =>
						fcsrCur(FCSRFCCBits) <= data_i(7 downto 1);
						fcsrCur(FCSR_FCC1_BIT) <= data_i(0);
					when others =>
				end case;
			end if;
		end process;

		process(clk) begin
			if (rising_edge(clk)) then
				if (rst = RST_DISABLE) then
					if (we_i = ENABLE) then
						fcsrReg <= fcsrCur;
					end if;
				end if;
			end if;
		end process;

		process(all)begin
			if (raddr_i = FIR_REG) then
				data_o <= FIR_CONST(31 downto 16) & cpuId(7 downto 0) & FIR_CONST(7 downto 0);
			elsif (raddr_i = FCSR_REG) then
				data_o <= fcsrReg;
			elsif (raddr_i = FCCR_REG) then
				data_o <= 24ub"0" & fcsrReg(FCSRFCCBits) & fcsrReg(FCSR_FCC1_BIT);
			elsif (raddr_i = FEXR_REG) then
				data_o <= 14ub"0" & fcsrReg(FCSRCauseBits) & 5ub"0" & fcsrReg(FCSRFlagsBits) & "00";
			elsif (raddr_i = FENR_REG) then
				data_o <= 20ub"0" & fcsrReg(FCSREnablesBits) & 4ub"0" & fcsrReg(FCSR_FS_BIT) & fcsrReg(FCSRRMBits);
			else
				data_o <= (others => '0');
			end if;
		end process;
	end generate EXTRA;
	EXTRA: if not extraReg generate
		data_o <= (others => '0');
	end generate EXTRA;
end bhv;