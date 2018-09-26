library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.global_const.all;
use work.ddr3_const.all;

entity ddr3_ctrl_cache is
    port (
        clk, rst: in std_logic;
        enable_i, readEnable_i: in std_logic;
        addr_i: in std_logic_vector(AddrWidth);
        writeData_i: in std_logic_vector(DataWidth);
        readData_o: out std_logic_vector(DataWidth);
        byteSelect_i: in std_logic_vector(3 downto 0);
        busy_o: out std_logic;

        enable_o: out std_logic;
        readDataBurst_i: in BurstDataType;
        busy_i: in std_logic
    );
end ddr3_ctrl_cache;

architecture bhv of ddr3_ctrl_cache is
    constant OFFSET_WIDTH: integer := BURST_LEN_WIDTH;
    constant INDEX_WIDTH: integer := 4;
    constant TAG_WIDTH: integer := 25 - OFFSET_WIDTH - INDEX_WIDTH;

    constant INDEX_NUM: integer := 2 ** INDEX_WIDTH;

    type CacheItemType is record
        present: std_logic;
        tag: std_logic_vector(TAG_WIDTH - 1 downto 0);
        data: BurstDataType;
    end record CacheItemType;

    type CacheTableType is array(0 to INDEX_NUM - 1) of CacheItemType;

    signal table: CacheTableType;
    signal tag: std_logic_vector(TAG_WIDTH - 1 downto 0);
    signal index, offset: integer;
    signal needToRead: std_logic;
begin

    tag <= addr_i(26 downto 27 - TAG_WIDTH);
    index <= conv_integer(addr_i(26 - TAG_WIDTH downto 27 - TAG_WIDTH - INDEX_WIDTH));
    offset <= conv_integer(addr_i(OFFSET_WIDTH + 1 downto 2));

    needToRead <= '0' when (table(index).tag = tag and table(index).present = '1') else '1';
    busy_o <= needToRead when readEnable_i = ENABLE else busy_i;
    readData_o <= table(index).data(offset) when (enable_i = ENABLE and readEnable_i = ENABLE and needToRead = '0') else (others => '0');

    enable_o <= ENABLE when (enable_i = ENABLE and (readEnable_i = DISABLE or needToRead = '1')) else DISABLE;

    process (clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                table <= (others => (present => '0', tag => (others => '0'), data => (others => (others => '0'))));
            else
                if (enable_i = ENABLE) then
                    if (readEnable_i = ENABLE and busy_i = PIPELINE_NONSTOP) then
                        table(index) <= (present => '1', tag => tag, data => readDataBurst_i);
                    elsif (readEnable_i = DISABLE) then
                        if (table(index).present = '1' and table(index).tag = tag) then
                            if (byteSelect_i(0) = '1') then
                                table(index).data(offset)(7 downto 0) <= writeData_i(7 downto 0);
                            end if;
                            if (byteSelect_i(1) = '1') then
                                table(index).data(offset)(15 downto 8) <= writeData_i(15 downto 8);
                            end if;
                            if (byteSelect_i(2) = '1') then
                                table(index).data(offset)(23 downto 16) <= writeData_i(23 downto 16);
                            end if;
                            if (byteSelect_i(3) = '1') then
                                table(index).data(offset)(31 downto 24) <= writeData_i(31 downto 24);
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

end bhv;
