library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.global_const.all;

entity float_regs is
	generic(
		extraReg: boolean
	);
    port(
        rst, clk: in std_logic;
        writeEnable_i: in std_logic;
        writeAddr_i: in std_logic_vector(RegAddrWidth);
        writeDouble_i: in std_logic;
        writeData_i: in std_logic_vector(DoubleDataWidth);
        readAddr1_i: in std_logic_vector(RegAddrWidth);
        readDouble1_i: in std_logic;
        readData1_o: out std_logic_vector(DoubleDataWidth);
        readAddr2_i: in std_logic_vector(RegAddrWidth);
        readDouble2_i: in std_logic;
        readData2_o: out std_logic_vector(DoubleDataWidth)
    );
end float_regs;

architecture bhv of float_regs is
    signal regArray: regArrayType := (others => (others => '0'));
begin
	EXTRA: if extraReg generate
	    process(clk) begin
	        if (rising_edge(clk)) then
	            if (rst = RST_ENABLE) then
    	            regArray <= (others => (others => '0'));
	            else
	                if (writeEnable_i = ENABLE) then
	                    if (writeDouble_i = YES) then
	            	        regArray(conv_integer(writeAddr_i(4 downto 1) & '1')) <= writeData_i(63 downto 32);
	            	        regArray(conv_integer(writeAddr_i(4 downto 1) & '0')) <= writeData_i(31 downto 0);
	             	    else
	            		    regArray(conv_integer(writeAddr_i(4 downto 0))) <= writeData_i(31 downto 0);
	            		end if;
	            	end if;
	            end if;
	        end if;
	    end process;

	    process(all) begin
    	    readData1_o <= (others => '0');
    	    if (rst = RST_DISABLE) then
    	        if (readDouble1_i = YES) then
    	            readData1_o(63 downto 32) <= regArray(conv_integer(readAddr1_i(4 downto 1) & '1'));
    	            readData1_o(31 downto 0) <= regArray(conv_integer(readAddr1_i(4 downto 1) & '0'));
    	        else
    	            readData1_o <= 32ub"0" & regArray(conv_integer(readAddr1_i(4 downto 0)));
    	        end if;
                if (readDouble1_i = YES) then
                    if (writeDouble_i = NO) then
                        if (readAddr1_i(4 downto 1) = writeAddr_i(4 downto 1)) then
                            if (writeAddr_i(0) = '1') then
                                readData1_o(63 downto 32) <= writeData_i(31 downto 0);
                            else
                                readData1_o(31 downto 0) <= writeData_i(31 downto 0);
                            end if;
                        end if;
                    else
                        if (readAddr1_i(4 downto 1) = writeAddr_i(4 downto 1)) then
                            readData1_o <= writeData_i;
                        end if;
                    end if;
                else
                    if (writeDouble_i = NO) then
                        if (readAddr1_i = writeAddr_i) then
                            readData1_o <= writeData_i;
                        end if;
                    else
                        if (readAddr1_i(4 downto 1) = writeAddr_i(4 downto 1)) then
                            if (readAddr1_i(0) = '1') then
                                readData1_o(31 downto 0) <= writeData_i(63 downto 32);
                            else
                                readData1_o(31 downto 0) <= writeData_i(31 downto 0);
                            end if;
                        end if;
                    end if;
                end if;
    	    end if;
    	end process;

    	process(all) begin
   	    	readData2_o <= (others => '0');
   	    	if (rst = RST_DISABLE) then
	            if (readDouble2_i = YES) then
	                readData2_o(63 downto 32) <= regArray(conv_integer(readAddr2_i(4 downto 1) & '1'));
	                readData2_o(31 downto 0) <= regArray(conv_integer(readAddr2_i(4 downto 1) & '0'));
	            else
	                readData2_o <= 32ub"0" & regArray(conv_integer(readAddr2_i(4 downto 0)));
	            end if;
                if (readDouble2_i = YES) then
                    if (writeDouble_i = NO) then
                        if (readAddr2_i(4 downto 1) = writeAddr_i(4 downto 1)) then
                            if (writeAddr_i(0) = '1') then
                                readData2_o(63 downto 32) <= writeData_i(31 downto 0);
                            else
                                readData2_o(31 downto 0) <= writeData_i(31 downto 0);
                            end if;
                        end if;
                    else
                        if (readAddr2_i(4 downto 1) = writeAddr_i(4 downto 1)) then
                            readData2_o <= writeData_i;
                        end if;
                    end if;
                else
                    if (writeDouble_i = NO) then
                        if (readAddr2_i = writeAddr_i) then
                            readData2_o <= writeData_i;
                        end if;
                    else
                        if (readAddr2_i(4 downto 1) = writeAddr_i(4 downto 1)) then
                            if (readAddr2_i(0) = '1') then
                                readData2_o(31 downto 0) <= writeData_i(63 downto 32);
                            else
                                readData2_o(31 downto 0) <= writeData_i(31 downto 0);
                            end if;
                        end if;
                    end if;
                end if;
	        end if;
	    end process;
	end generate EXTRA;
end bhv;