library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.global_const.all;
use work.bus_const.all;
use work.ddr3_const.all;

entity data_cache is
    port (
        clk, rst: in std_logic;

        -- From/ to CPU
        req_i: in BusC2D;
        res_o: out BusD2C;

        -- From/ to AXI
        -- read
        arenable_o: out std_logic;
        araddr_o: out std_logic_vector(AddrWidth);
        arrequestAck_i: in std_logic;

        -- write
        awenable_o: out std_logic;
        awaddr_o: out std_logic_vector(AddrWidth);
        awdata_o: out std_logic_vector(DataWidth);
        awbyteSelect_o: out std_logic_vector(3 downto 0);
        awrequestAck_i: in std_logic;

        enable_i: in std_logic;
        data_i: in std_logic_vector(DataWidth);
        addr_i: in std_logic_vector(AddrWidth);
        singleByte_o: out std_logic
    );
end data_cache;

architecture bhv of data_cache is
    constant INDEX_WIDTH: integer := DATA_INDEX_WIDTH;
    constant TAG_WIDTH: integer := 32 - OFFSET_WIDTH - INDEX_WIDTH - DATA_LINE_WIDTH;

    constant INDEX_NUM: integer := 2 ** INDEX_WIDTH;
    constant LINE_NUM: integer := 2 ** DATA_LINE_WIDTH;
    constant PREF_INDEX: integer := INDEX_WIDTH + DATA_LINE_WIDTH + OFFSET_WIDTH - 1;
    -- if that index is one, trigger prefetch with the least priority
    subtype AddrIndex is integer range DATA_LINE_WIDTH + OFFSET_WIDTH - 1 downto OFFSET_WIDTH;
    subtype TagIndex is integer range 31 downto (INDEX_WIDTH + OFFSET_WIDTH + DATA_LINE_WIDTH);
    subtype LineIndex is integer range INDEX_WIDTH + OFFSET_WIDTH + DATA_LINE_WIDTH - 1 downto DATA_LINE_WIDTH + OFFSET_WIDTH;
    subtype SubLineIndex is integer range (DATA_LINE_WIDTH + OFFSET_WIDTH - 1) downto (OFFSET_WIDTH);

    type CacheUnitType is record
        data: std_logic_vector(DataWidth);
        --correct: std_logic; for future use
    end record CacheUnitType;
    type CacheDataType is array(0 to LINE_NUM - 1) of CacheUnitType;

    type CacheItemType is record
        present: std_logic;
        tag: std_logic_vector(TAG_WIDTH - 1 downto 0);
        dirty: std_logic;
        unit: CacheDataType;
    end record CacheItemType;

    type CacheTableType is array(0 to INDEX_NUM - 1) of CacheItemType;

    signal table: CacheTableType;
    signal reqTag: std_logic_vector(INDEX_WIDTH - 1 downto 0);
    signal readFromCache: std_logic;
    signal uncachedAddress: std_logic_vector(AddrWidth);
    signal uncachedData: std_logic_vector(DataWidth);
    signal bufferCount: std_logic_vector(DATA_LINE_WIDTH downto 0);
    type WriteBufferState is (INIT, SEND);
    signal bufferState: WriteBufferState;
    signal lineTag: std_logic_vector(DATA_LINE_WIDTH - 1 downto 0);
    type RequestState is (IDLE, PENDING);
    signal rstate, wstate: RequestState;

    signal dataInCache: std_logic;
    signal lastRequest: BusC2D;
    signal newRequest: std_logic;
    signal newReqRead, newReqWrite: std_logic;
    -- 0 for read, 1 for write
begin
    readFromCache <= '0' when req_i.addr(31 downto 16) = 16ux"bfaf" else
                     '1';
    singleByte_o <= '1' when req_i.addr(31 downto 16) = 16ux"bfaf" else
                    '0';
    reqTag <= req_i.addr(LineIndex);
    lineTag <= req_i.addr(SubLineIndex);
    dataInCache <= '1' when table(conv_integer(reqTag)).tag = req_i.addr(TagIndex) and table(conv_integer(reqTag)).present = '1' else '0';
    newRequest <= '1' when lastRequest /= req_i and req_i.enable = '1' else '0';
    newReqRead <= '1' when (readFromCache = YES and dataInCache = NO)
                         or (readFromCache = NO and req_i.enable = YES and req_i.write = NO) else '0';
    newReqWrite <= '1' when (readFromCache = YES and dataInCache = NO and table(conv_integer(reqTag)).dirty = '1')
                            or (readFromCache = NO and req_i.write = YES) else '0';
    -- NOTE: above signal only judges during the first clock period
    arenable_o <= '1' when (newRequest = '1' and newReqRead = '1' and newReqWrite = '0') or rstate /= IDLE else '0';
    awenable_o <= '1' when (newRequest = '1' and newReqWrite = '1') or wstate /= IDLE else '0';
    araddr_o <= req_i.addr(31 downto DATA_LINE_WIDTH + OFFSET_WIDTH) & "000000" when readFromCache = YES else req_i.addr;
    awaddr_o <= table(conv_integer(reqTag)).tag & reqTag & "000000" when readFromCache = YES else
                req_i.addr;
    awdata_o <= table(conv_integer(reqTag)).unit(conv_integer(bufferCount(DATA_LINE_WIDTH - 1 downto 0))).data when readFromCache = YES else
                req_i.dataSave;
    awbyteSelect_o <= req_i.byteSelect;

    res_o.busy <= PIPELINE_STOP when ((dataInCache = NO and readFromCache = YES) or 
                                     (readFromCache = NO and (newRequest = '1' or wstate /= IDLE or 
                                        (uncachedAddress /= req_i.addr and req_i.write = NO)))) and 
                                        req_i.enable = YES else
                  PIPELINE_NONSTOP;
    res_o.dataLoad <= uncachedData when readFromCache = NO else
                      table(conv_integer(reqTag)).unit(conv_integer(lineTag)).data;

    process (clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                rstate <= IDLE;
                wstate <= IDLE;
            else
                if (newRequest = '1') then
                    if newReqWrite = '1' then
                        if (awrequestAck_i = NO) then
                            wstate <= PENDING;
                        else
                            if (readFromCache = YES) then
                                rstate <= PENDING;
                            end if;
                        end if;
                    elsif newReqRead = '1' then
                        rstate <= PENDING;
                    end if;
                elsif (wstate = PENDING and awrequestAck_i = YES) then
                    wstate <= IDLE;
                    if (readFromCache = YES) then
                        rstate <= PENDING;
                    end if;
                elsif (rstate = PENDING and arrequestAck_i = YES) then
                    rstate <= IDLE;
                end if;
            end if;
            lastRequest <= req_i;
        end if;
    end process;

    -- driven table
    process (clk) begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                bufferState <= INIT;
                bufferCount <= (others => '0');
                table <= (others => (present => '0', tag => (others => '0'), dirty => '0', unit => (others => (data => (others => '0')))));
            else
                if (newRequest = '1') then
                    uncachedAddress <= 32ux"bfc00000";
                end if;
                if (enable_i = YES) then
                    if (addr_i(31 downto 16) /= 16ux"bfaf") then
                        table(conv_integer(addr_i(LineIndex))).unit(conv_integer(addr_i(SubLineIndex))).data <= data_i;
                        if (addr_i(5 downto 2) /= 4ub"1111") then
                            -- if not the last byte in a burst, invalidate the cache line, or vice versa
                            table(conv_integer(addr_i(LineIndex))).present <= '0';
                        else
                            table(conv_integer(addr_i(LineIndex))).present <= '1';
                        end if;
                        table(conv_integer(addr_i(LineIndex))).tag <= addr_i(TagIndex);
                    else
                        uncachedData <= data_i;
                        uncachedAddress <= addr_i;
                    end if;
                end if;
                if (bufferState = SEND) then
                    bufferCount <= bufferCount + '1';
                    if (bufferCount = "10000") then
                        bufferState <= INIT;
                        bufferCount <= (others => '0');
                    end if;
                end if;
                if (awrequestAck_i = YES and readFromCache = YES) then
                    bufferState <= SEND;
                    table(conv_integer(reqTag)).present <= '0';
                    table(conv_integer(reqTag)).dirty <= '0';
                end if;
                if (req_i.write = YES and req_i.enable = YES and req_i.addr(TagIndex) = table(conv_integer(reqTag)).tag and table(conv_integer(reqTag)).present = '1') then
                    table(conv_integer(reqTag)).dirty <= '1';
                    if (req_i.byteSelect(0) = '1') then
                        table(conv_integer(reqTag)).unit(conv_integer(lineTag)).data(7 downto 0) <= req_i.dataSave(7 downto 0);
                    end if;
                    if (req_i.byteSelect(1) = '1') then
                        table(conv_integer(reqTag)).unit(conv_integer(lineTag)).data(15 downto 8) <= req_i.dataSave(15 downto 8);
                    end if;
                    if (req_i.byteSelect(2) = '1') then
                        table(conv_integer(reqTag)).unit(conv_integer(lineTag)).data(23 downto 16) <= req_i.dataSave(23 downto 16);
                    end if;
                    if (req_i.byteSelect(3) = '1') then
                        table(conv_integer(reqTag)).unit(conv_integer(lineTag)).data(31 downto 24) <= req_i.dataSave(31 downto 24);
                    end if;
                end if;
            end if;
        end if;
    end process;

end bhv;