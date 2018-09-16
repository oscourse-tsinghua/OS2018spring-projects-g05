library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.global_const.all;
use work.bus_const.all;

entity ipi_ctrl is
    port (
        clk, rst: in std_logic;
        cpu_i: in BusC2D;
        cpu_o: out BusD2C;
        int_o: out std_logic_vector(1 downto 0)
    );
end ipi_ctrl;

architecture bhv of ipi_ctrl is
    constant CPU1_BASE: integer := 0;
    constant CPU2_BASE: integer := 8;

    constant STATUS_OFF: integer := 0;
    constant ENABLE_OFF: integer := 1;
    constant SET_OFF:    integer := 2;
    constant CLEAR_OFF:  integer := 3;
    constant MAIL0_OFF:  integer := 4;
    constant MAIL1_OFF:  integer := 5;
    constant MAIL2_OFF:  integer := 6;
    constant MAIL3_OFF:  integer := 7;

    type RegArr is array(0 to 15) of std_logic_vector(DataWidth);
    signal regs: RegArr;

    signal base, off: integer;
begin
    process (all) begin
        int_o <= "00";
        if ((regs(CPU1_BASE + STATUS_OFF) and regs(CPU1_BASE + ENABLE_OFF)) /= 32ux"0") then
            int_o(0) <= '1';
        end if;
        if ((regs(CPU2_BASE + STATUS_OFF) and regs(CPU2_BASE + ENABLE_OFF)) /= 32ux"0") then
            int_o(1) <= '1';
        end if;
    end process;

    base <= CPU1_BASE when cpu_i.addr(5) = '0' else CPU2_BASE;
    off <= conv_integer(cpu_i.addr(4 downto 2));

    cpu_o.busy <= PIPELINE_NONSTOP;
    with off select cpu_o.dataLoad <=
        regs(base + off) when STATUS_OFF|ENABLE_OFF|MAIL0_OFF|MAIL1_OFF|MAIL2_OFF|MAIL3_OFF,
        32ux"0" when others;

    process (clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                regs <= (others => 32ux"0");
            elsif (cpu_i.enable = ENABLE and cpu_i.write = YES) then
                case off is
                    when SET_OFF =>
                        regs(base + STATUS_OFF) <= regs(base + STATUS_OFF) or cpu_i.dataSave;
                    when CLEAR_OFF =>
                        regs(base + STATUS_OFF) <= regs(base + STATUS_OFF) and not cpu_i.dataSave;
                    when ENABLE_OFF|MAIL0_OFF|MAIL1_OFF|MAIL2_OFF|MAIL3_OFF =>
                        regs(base + off) <= cpu_i.dataSave;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;
end bhv;

