library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use work.global_const.all;
use work.bus_const.all;
use work.ddr3_const.all;

entity inst_cache is
    port (
        clk, rst: in std_logic;

        -- From/ to CPU
        req_i: in BusC2D;
        res_o: out BusD2C;

        -- From/ to AXI
        enable_o: out std_logic;
        addr_o: out std_logic_vector(AddrWidth);
        requestAck_i: in std_logic;

        enable_i: in std_logic;
        data_i: in std_logic_vector(DataWidth);
        addr_i: in std_logic_vector(AddrWidth)
    );
end inst_cache;

architecture bhv of inst_cache is
    constant INDEX_WIDTH: integer := DATA_INDEX_WIDTH + INST_LINE_WIDTH;
    constant TAG_WIDTH: integer := 29 - OFFSET_WIDTH - INDEX_WIDTH;

    constant INDEX_NUM: integer := 2 ** INDEX_WIDTH;
    constant LINE_NUM: integer := 2 ** (INST_LINE_WIDTH + OFFSET_WIDTH);
    constant PREF_INDEX: integer := INST_LINE_WIDTH + OFFSET_WIDTH - 1;
    -- if that index is one, trigger prefetch with the least priority
    subtype AddrIndex is integer range INDEX_WIDTH + OFFSET_WIDTH - 1 downto OFFSET_WIDTH;
    subtype TagIndex is integer range 28 downto (INDEX_WIDTH + OFFSET_WIDTH);

    type CacheItemType is record
        present: std_logic;
        tag: std_logic_vector(TAG_WIDTH - 1 downto 0);
        data: std_logic_vector(DataWidth);
    end record CacheItemType;

    type CacheTableType is array(0 to INDEX_NUM - 1) of CacheItemType;

    signal table: CacheTableType;
    signal requestEnable: std_logic;
    signal requestAddr: std_logic_vector(AddrWidth);
    signal needToRead: std_logic;
    signal prefetchPending: std_logic;
    signal prefetchAddr: std_logic_vector(AddrWidth);
    signal reqTag: std_logic_vector(INDEX_WIDTH - 1 downto 0);
    signal lastSentAddr: std_logic_vector(AddrWidth);
    signal ati, ati2: std_logic_vector(TAG_WIDTH - 1 downto 0);
begin

	reqTag <= req_i.addr(AddrIndex);
    needToRead <= YES when (table(conv_integer(reqTag)).tag /= req_i.addr(TagIndex)) and req_i.enable = YES else NO;
    res_o.busy <= PIPELINE_STOP when (needToRead = YES or (enable_i = YES and addr_i /= req_i.addr)) and rst = RST_DISABLE else PIPELINE_NONSTOP;
    res_o.dataLoad <= data_i when enable_i = YES and addr_i = req_i.addr else
                      table(conv_integer(reqTag)).data;

    enable_o <= '0' when needToRead = NO else
                req_i.enable when req_i.addr(31 downto 6) /= lastSentAddr(31 downto 6) else
                requestEnable;
    addr_o <= (req_i.addr(31 downto 6) & "000000") when (requestEnable = NO) else
    	      (requestAddr(31 downto 6) & "000000");

    process (clk)
    	variable reqEnable: std_logic;
    	variable reqAddr: std_logic_vector(AddrWidth);
    begin
        if (rising_edge(clk)) then
            if (rst = RST_ENABLE) then
                prefetchPending <= NO;
                prefetchAddr <= (others => '0');
                requestEnable <= NO;
                requestAddr <= (others => '0');
                lastSentAddr <= (others => '0');
            else
            	reqEnable := requestEnable;
            	reqAddr := requestAddr;
            	if (reqEnable = YES and requestAck_i = YES) then
            		reqEnable := NO;
                    lastSentAddr <= reqAddr;
            	end if;
                if (needToRead = YES and req_i.addr(31 downto 6) /= reqAddr(31 downto 6)) then
                	if (req_i.enable = YES and reqEnable = NO) then
                		reqEnable := YES;
                		reqAddr := req_i.addr;
                	end if;
                elsif (needToRead = YES) then
                	if (req_i.addr(PREF_INDEX) = YES and req_i.enable = YES) then
            	   	    if (reqEnable = YES) then
	            	      	prefetchPending <= YES;
       		         		prefetchAddr <= req_i.addr + LINE_NUM;
   	    	         	else
   		            		reqEnable := YES;
   		             		reqAddr := req_i.addr + LINE_NUM;
   		             	end if;
                     end if;
            	end if;
                if (reqEnable = NO and prefetchPending = YES) then
                    reqEnable := YES;
                    reqAddr := prefetchAddr;
                end if;
                if (reqEnable = YES) and (prefetchPending = YES) and (reqAddr(31 downto 6) = prefetchAddr(31 downto 6)) then
                    prefetchPending <= NO;
                end if;
            	requestEnable <= reqEnable;
            	requestAddr <= reqAddr;
            end if;
        end if;
    end process;


    process (clk) begin
    	if (rising_edge(clk)) then
    		if (rst = RST_ENABLE) then
    			table <= (others => (present => '0', tag => (others => '0'), data => 32ux"0"));
    		elsif (enable_i = YES) then
    			table(conv_integer(addr_i(AddrIndex))) <= (present => '1', tag => addr_i(TagIndex), data => data_i);
    		end if;
    	end if;
    end process;

end bhv;