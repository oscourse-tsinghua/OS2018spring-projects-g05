library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.global_const.all;

entity div is
    port (
        clk: in std_logic;
        enable_i: in std_logic;
        dividend_i, divider_i: in std_logic_vector(DataWidth);
        busy_o: out std_logic;
        quotient_o: out std_logic_vector(DataWidth);
        remainder_o: out std_logic_vector(DataWidth)
    );
end div;

architecture bhv of div is
    signal buf: std_logic_vector(DoubleDataWidth);
    signal state: integer;
begin

    busy_o <= PIPELINE_STOP when enable_i = ENABLE and state /= 32 else PIPELINE_NONSTOP;
    quotient_o <= buf(LoDataWidth);
    remainder_o <= buf(HiDataWidth);

    process(clk)
        variable movedBuf: std_logic_vector(DoubleDataWidth);
    begin
        if (rising_edge(clk)) then
            if (enable_i = DISABLE) then
                buf <= (others => '0');
                state <= 0;
            else
                if (state = 0) then
                    movedBuf := 31ux"0" & dividend_i & '0';
                else
                    movedBuf(HiDataWidth) := buf(62 downto 31);
                    movedBuf(LoDataWidth) := buf(30 downto 0) & '0';
                end if;
                if (movedBuf(HiDataWidth) >= divider_i) then
                    movedBuf(0) := '1';
                    movedBuf(HiDataWidth) := movedBuf(HiDataWidth) - divider_i;
                end if;
                buf <= movedBuf;
                state <= state + 1;
            end if;
        end if;
    end process; 

end bhv;