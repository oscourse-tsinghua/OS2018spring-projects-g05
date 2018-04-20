library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

entity seg7_ctrl is
    port (
        clk, rst: in std_logic;
        we_i: in std_logic;
        data_i: in std_logic_vector(DataWidth);
        cs_n_o: out std_logic_vector(7 downto 0);
        lights_o: out std_logic_vector(6 downto 0)
    );
end seg7_ctrl;

architecture bhv of seg7_ctrl is
    signal data: std_logic_vector(DataWidth);
    signal cs: std_logic_vector(7 downto 0);
    signal part: std_logic_vector(3 downto 0);
begin
    process (all) begin
        case (cs) is
            when "00000001" => part <= data(3 downto 0);
            when "00000010" => part <= data(7 downto 4);
            when "00000100" => part <= data(11 downto 8);
            when "00001000" => part <= data(15 downto 12);
            when "00010000" => part <= data(19 downto 16);
            when "00100000" => part <= data(23 downto 20);
            when "01000000" => part <= data(27 downto 24);
            when "10000000" => part <= data(31 downto 28);
            when others => null;
        end case;
    end process;

    process (all) begin
        case (part) is
            when x"0" => lights_o <= "0111111";
            when x"1" => lights_o <= "0000110";
            when x"2" => lights_o <= "1011011";
            when x"3" => lights_o <= "1001111";
            when x"4" => lights_o <= "1100110";
            when x"5" => lights_o <= "1101101";
            when x"6" => lights_o <= "1111101";
            when x"7" => lights_o <= "0000111";
            when x"8" => lights_o <= "1111111";
            when x"9" => lights_o <= "1101111";
            when x"A" => lights_o <= "1110111";
            when x"B" => lights_o <= "1111100";
            when x"C" => lights_o <= "0111001";
            when x"D" => lights_o <= "1011110";
            when x"E" => lights_o <= "1111001";
            when x"F" => lights_o <= "1110001";
            when others => null;
        end case;
    end process;

    cs_n_o <= not cs;

    process (clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                data <= (others => '0');
                cs <= "00000001";
            else
                data <= data_i;
                case (cs) is
                    when "00000001" => cs <= "00000010";
                    when "00000010" => cs <= "00000100";
                    when "00000100" => cs <= "00001000";
                    when "00001000" => cs <= "00010000";
                    when "00010000" => cs <= "00100000";
                    when "00100000" => cs <= "01000000";
                    when "01000000" => cs <= "10000000";
                    when "10000000" => cs <= "00000001";
                    when others => null;
                end case;
            end if;
        end if;
    end process;
end bhv;

