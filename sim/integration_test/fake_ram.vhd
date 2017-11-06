library ieee;
use ieee.std_logic_1164.all;
use work.global_const.all;

entity fake_ram is
    port (
        rst: in std_logic;
        writeEnable_i, readEnable1_i, readEnable2_i: in std_logic;
        writeAddr_i: in std_logic_vector(AddrWidth);
        writeData_i: in std_logic_vector(DataWidth);
        readAddr1_i: in std_logic_vector(AddrWidth);
        readAddr2_i: in std_logic_vector(AddrWidth);
        readData1_o: out std_logic_vector(DataWidth);
        readData2_o: out std_logic_vector(DataWidth)
    );
end fake_ram;

architecture bhv of fake_ram is

    component ram
        port (
            clka, ena: in std_logic;
            wea: in std_logic_vector(3 downto 0);
            dina: in std_logic_vector(31 downto 0);
            addra: in std_logic_vector(18 downto 0);
            douta: out std_logic_vector(31 downto 0)
        );
    end component;

    type state is (FINISHED_WRITE, FINISHED_READ1, FINISHED_READ2);
    signal clk: std_logic;
    signal current_state, next_state: state := FINISHED_READ2;
    signal we: std_logic_vector(3 downto 0);
    signal addr: std_logic_vector(18 downto 0);
    signal din, dout: std_logic_vector(DataWidth);
begin

    ram_ist: ram
    port map (
        clka => clk, ena => '1',
        wea => we, dina => din,
        addra => addr, douta => dout
    );

    process
    begin
        clk <= '0';
        wait for 1 ns;
        clk <= '1';
        wait for 1 ns;
    end process;

    process(clk)
    begin
        current_state <= next_state;
    end process;

    process(current_state)
    begin
        case current_state is
            when FINISHED_WRITE =>    -- READY_READ1
                we <= "0000";
                addr <= readAddr1_i;
                next_state <= FINISHED_READ1;
            when FINISHED_READ1 =>    -- READY_READ2
                we <= "0000";
                readData1_o <= dout;
                addr <= readAddr2_i;
                next_state <= FINISHED_READ2;
            when FINISHED_READ2 =>    -- READY_WRITE
                we <= "1111";
                readData2_o <= dout;
                din <= writeData_i;
                addr <= writeAddr_i;
            when others =>
                next_state <= FINISHED_READ2;
        end case;
    end process;

end bhv;