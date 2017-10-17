library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;
use work.inst_const.all;
use work.alu_const.all;

entity id is
    port (
        rst: in std_logic;
        pc_i: in std_logic_vector(AddrWidth);
        inst_i: in std_logic_vector(InstWidth);
        regData1_i: in std_logic_vector(DataWidth);
        regData2_i: in std_logic_vector(DataWidth);

        regReadEnable1_o: out std_logic;
        regReadEnable2_o: out std_logic;
        regReadAddr1_o: out std_logic_vector(RegAddrWidth);
        regReadAddr2_o: out std_logic_vector(RegAddrWidth);
        alut_o: out AluType;
        operand1_o: out std_logic_vector(DataWidth);
        operand2_o: out std_logic_vector(DataWidth);
        toWriteReg_o: out std_logic;
        writeRegAddr_o: out std_logic_vector(RegAddrWidth)
    );
end id;

architecture bhv of id is
    signal instOp:   std_logic_vector(InstOpWidth);
    signal instRs:   std_logic_vector(InstRsWidth);
    signal instRt:   std_logic_vector(InstRtWidth);
    signal instRd:   std_logic_vector(InstRdWidth);
    signal instSa:   std_logic_vector(InstSaWidth);
    signal instFunc: std_logic_vector(InstFuncWidth);
    signal instImm:  std_logic_vector(InstImmWidth);
    signal instAddr: std_logic_vector(InstAddrWidth);
begin

    -- Segment the instruction --
    instOp   <= inst_i(InstOpIdx);
    instRs   <= inst_i(InstRsIdx);
    instRt   <= inst_i(InstRtIdx);
    instRd   <= inst_i(InstRdIdx);
    instSa   <= inst_i(InstSaIdx);
    instFunc <= inst_i(InstFuncIdx);
    instImm  <= inst_i(InstImmIdx);
    instAddr <= inst_i(InstAddrIdx);

    process(rst, pc_i, regData1_i, regData2_i,
            instOp, instRs, instRt, instRd,
            instSa, instFunc, instImm, instAddr) begin
        if (rst = RST_ENABLE) then
            regReadEnable1_o <= DISABLE;
            regReadEnable2_o <= DISABLE;
            regReadAddr1_o <= (others => '0');
            regReadAddr2_o <= (others => '0');
            alut_o <= INVALID;
            operand1_o <= (others => '0');
            operand2_o <= (others => '0');
            toWriteReg_o <= NO;
            writeRegAddr_o <= (others => '0');
        else
            case (instOp) is

                -- ori --
                when OP_ORI =>
                    regReadEnable1_o <= ENABLE;
                    regReadEnable2_o <= DISABLE;
                    regReadAddr1_o <= instRs;
                    regReadAddr2_o <= (others => '0');
                    alut_o <= ALU_OR;
                    operand1_o <= regData1_i;
                    operand2_o <= "0000000000000000" & instImm;
                    toWriteReg_o <= YES;
                    writeRegAddr_o <= instRt;

                -- others --
                when others =>
                    regReadEnable1_o <= DISABLE;
                    regReadEnable2_o <= DISABLE;
                    regReadAddr1_o <= (others => '0');
                    regReadAddr2_o <= (others => '0');
                    alut_o <= INVALID;
                    operand1_o <= (others => '0');
                    operand2_o <= (others => '0');
                    toWriteReg_o <= NO;
                    writeRegAddr_o <= (others => '0');

            end case;
        end if;
    end process;

end bhv;