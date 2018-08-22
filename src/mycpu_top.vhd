library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.global_const.all;
use work.except_const.all;
use work.bus_const.all;
use work.ddr3_const.all;

entity mycpu_top is
    port(
        aclk: in std_logic;
        aresetn: in std_logic;

        arid: out std_logic_vector(3 downto 0);
        araddr: out std_logic_vector(31 downto 0);
        arlen: out std_logic_vector(7 downto 0);
        arsize: out std_logic_vector(2 downto 0);
        arburst: out std_logic_vector(1 downto 0);
        arlock: out std_logic_vector(1 downto 0);
        arcache: out std_logic_vector(3 downto 0);
        arprot: out std_logic_vector(2 downto 0);
        arvalid: out std_logic;
        arready: in std_logic;

        rid: in std_logic_vector(3 downto 0);
        rdata: in std_logic_vector(31 downto 0);
        rresp: in std_logic_vector(1 downto 0);
        rlast: in std_logic;
        rvalid: in std_logic;
        rready: out std_logic;

        awid: out std_logic_vector(3 downto 0);
        awaddr: out std_logic_vector(31 downto 0);
        awlen: out std_logic_vector(7 downto 0);
        awsize: out std_logic_vector(2 downto 0);
        awburst: out std_logic_vector(1 downto 0);
        awlock: out std_logic_vector(1 downto 0);
        awcache: out std_logic_vector(3 downto 0);
        awprot: out std_logic_vector(2 downto 0);
        awvalid: out std_logic;
        awready: in std_logic;

        wid: out std_logic_vector(3 downto 0);
        wdata: out std_logic_vector(31 downto 0);
        wstrb: out std_logic_vector(3 downto 0);
        wlast: out std_logic;
        wvalid: out std_logic;
        wready: in std_logic;

        bid: in std_logic_vector(3 downto 0);
        bresp: in std_logic_vector(1 downto 0);
        bvalid: in std_logic;
        bready: out std_logic;

        int: in std_logic_vector(IntWidth);
        debug_wb_pc: out std_logic_vector(AddrWidth);
        debug_wb_rf_wen: out std_logic_vector(3 downto 0);
        debug_wb_rf_wnum: out std_logic_vector(CP0RegAddrWidth);
        debug_wb_rf_wdata: out std_logic_vector(DataWidth)
    );
end mycpu_top;

architecture bhv of mycpu_top is
    signal areset: std_logic;

    -- fit loongnix's name norm in my view
    -- Xihang Liu, Aug. 13, 2018
    signal aInstArEnable: std_logic;
    signal aInstAraddr: std_logic_vector(AddrWidth);
    signal aInstRequestAck: std_logic;
    signal aInstEnable: std_logic;
    signal aInstData: std_logic_vector(DataWidth);
    signal aInstAddr: std_logic_vector(AddrWidth);

    signal aDataArenable: std_logic;
    signal aDataAraddr: std_logic_vector(AddrWidth);
    signal aDataArrequestAck: std_logic;
    signal aDataAwenable: std_logic;
    signal aDataAwaddr: std_logic_vector(AddrWidth);
    signal aDataAwdata: std_logic_vector(DataWidth);
    signal aDataAwbyteSelect: std_logic_vector(3 downto 0);
    signal aDataAwrequestAck: std_logic;
    signal aDataEnable: std_logic;
    signal aDataData: std_logic_vector(DataWidth);
    signal aDataAddr: std_logic_vector(AddrWidth);
    signal aDataSingleByte: std_logic;
    constant INST_WRITE_LEN: integer := 2 ** INST_LINE_WIDTH - 1;
    constant DATA_WRITE_LEN: integer := 2 ** DATA_LINE_WIDTH - 1;

    type BufferUnit is record
        data: std_logic_vector(DataWidth);
    end record;
    type BufferData is array(0 TO DATA_WRITE_LEN) of BufferUnit;
    type BufferState is (UNSYNC, SYNCED);
    type XBuffer is record
        data: BufferData;
        state: BufferState;
        sendCount: std_logic_vector(DATA_LINE_WIDTH downto 0);
        readCount: std_logic_vector(DATA_LINE_WIDTH downto 0);
        tag: std_logic_vector(25 downto 0);
        present: std_logic;
    end record;
    -- to make vivado happy, call it X-Buffer instead of Buffer
    signal writeBuffer: XBuffer;

    type AxiRequestState is (INIT, READ);
    -- note: read here is not for reading, but still valid
    type AxiRequest is record
        state: AxiRequestState;
        addr: std_logic_vector(AddrWidth);
        target: std_logic;
        -- 0 for inst cache, 1 for data cache
    end record;
    type RequestTable is array(0 to 15) of AxiRequest;
    signal table: RequestTable;

    type SendReqState is (INIT, PENDING);
    signal sstate: SendReqState;
    type RequestFrom is (INST, DATA, IDLE);
    signal sendReqFrom: RequestFrom;
    -- 0 for inst cache and 1 for data cache still
    type WriteState is (INIT, AOK, DOK, WRITE);
    signal wstate, bstate: WriteState;
    type writeSource is (BUF, CACHE, IDLE);
    signal writeFrom: writeSource;

    signal currentSendIdx: std_logic_vector(3 downto 0);
    signal readFromInst, readFromData: std_logic;
begin
    areset <= not aresetn;

    readFromInst <= YES when sstate = INIT and aInstArenable = YES and readFromData = NO and
                        table(conv_integer(aInstAraddr(RequestIdIndex))).state = INIT else
                    NO;
    readFromData <= YES when sstate = INIT and aDataArenable = YES and
                        table(conv_integer(aDataAraddr(RequestIdIndex))).state = INIT and
                        (aDataAraddr(31 downto 6) /= writeBuffer.tag or writeBuffer.state = SYNCED) else
                    NO;
    -- valid only the first clock period

    arid <= aDataAraddr(RequestIdIndex) when readFromData = YES else
            aInstAraddr(RequestIdIndex) when readFromInst = YES else
            currentSendIdx;
    araddr <= "000" & aDataAraddr(28 downto 0) when readFromData = YES else
              "000" & aInstAraddr(28 downto 0) when readFromInst = YES else
              "000" & table(conv_integer(currentSendIdx)).addr(28 downto 0);
    arlen <= (others => '0') when (readFromData = YES or sendReqFrom = DATA) and aDataSingleByte = YES else
             conv_std_logic_vector(INST_WRITE_LEN, 8);
    arsize <= "010";
    arburst <= "01";

    arlock <= (others => '0');
    arcache <= (others => '0');
    arprot <= (others => '0');
    awlock <= (others => '0');
    awcache <= (others => '0');
    awprot <= (others => '0');

    arvalid <= '1' when (sstate /= INIT or readFromInst = YES or readFromData = YES) else '0';
    rready <= '1';

    aInstRequestAck <= arready when table(conv_integer(currentSendIdx)).target = '0'
                       else '0';
    aDataArrequestAck <= arready when table(conv_integer(currentSendIdx)).target = '1'
                       else '0';

    aInstEnable <= YES when rvalid = '1' and table(conv_integer(rid)).target = '0' else NO;
    aInstAddr <= table(conv_integer(rid)).addr;
    aInstData <= rdata;
    aDataEnable <= YES when rvalid = '1' and table(conv_integer(rid)).target = '1' else NO;
    aDataAddr <= table(conv_integer(rid)).addr;
    aDataData <= rdata;

    awid <= "0000" when writeFrom = CACHE else "0001";
    wid <= "0000" when writeFrom = CACHE else "0001";
    awaddr <= "000" & aDataAwaddr(28 downto 0) when writeFrom = CACHE else
              "000" & writeBuffer.tag(22 downto 0) & writeBuffer.sendCount(3 downto 0) & "00";
    awlen <= (others => '0') when writeFrom = CACHE else
             conv_std_logic_vector(DATA_WRITE_LEN, 8);
    awsize <= "010";
    awburst <= "01";

    awvalid <= '1' when ((wstate = INIT or wstate = DOK) and writeFrom = CACHE) or
                        ((bstate = INIT or bstate = DOK) and writeFrom = BUF and writeBuffer.sendCount = "00000") else
               '0';

    wdata <= aDataAwdata when writeFrom = CACHE else
             writeBuffer.data(conv_integer(writeBuffer.sendCount(3 downto 0))).data;
    wstrb <= aDataAwbyteSelect when writeFrom = CACHE else
             (others => '1');
    wvalid <= '1' when ((wstate = INIT or wstate = AOK) and writeFrom = CACHE) or
                       ((bstate = INIT or bstate = AOK) and writeFrom = BUF) else
              '0';
    wlast <= '1' when (writeFrom = CACHE) or
                      (writeFrom = BUF and writeBuffer.sendCount = "01111") else
             '0';

    bready <= '1';

    aDataAwrequestAck <= '1' when ((writeBuffer.tag = aDataAwaddr(31 downto 6) and writeBuffer.present = '1') or
                                  (writeBuffer.state = SYNCED and aDataSingleByte = NO)) and writeFrom = IDLE and aDataAwenable = YES else
                         bvalid when aDataSingleByte = YES and aDataSingleByte = YES and writeFrom = CACHE else
                         '0';

    process (aclk) begin
        if (rising_edge(aclk)) then
            if (areset = RST_ENABLE) then
                sstate <= INIT;
                wstate <= INIT;
                bstate <= INIT;
                writeFrom <= IDLE;
                writeBuffer <= (data => (others => (others => (others => '0'))), state => SYNCED, sendCount => (others => '0'), tag => (others => '0'), present => '0', readCount => (others => '0'));
                table <= (others => (target => '0', addr => (others => '0'), state => INIT));
                currentSendIdx <= (others => '0');
                sendReqFrom <= IDLE;
            else
                if (sstate = PENDING and arready = '1') then
                    sstate <= INIT;
                    sendReqFrom <= IDLE;
                end if;
                if (sstate = INIT) then
                    if (readFromData = YES and table(conv_integer(aDataAraddr(RequestIdIndex))).state = INIT) then
                        table(conv_integer(aDataAraddr(RequestIdIndex))) <= (state => READ, addr => aDataAraddr, target => '1');
                        sstate <= PENDING;
                        currentSendIdx <= (aDataAraddr(RequestIdIndex));
                        sendReqFrom <= DATA;
                    elsif (readFromInst = YES and table(conv_integer(aInstAraddr(RequestIdIndex))).state = INIT) then
                        table(conv_integer(aInstAraddr(RequestIdIndex))) <= (state => READ, addr => aInstAraddr, target => '0');
                        sstate <= PENDING;
                        currentSendIdx <= (aInstAraddr(RequestIdIndex));
                        sendReqFrom <= INST;
                    end if;
                end if;
                if (rvalid = '1' and table(conv_integer(rid)).addr(5 downto 2) /= "1111") then
                    table(conv_integer(rid)).addr <= table(conv_integer(rid)).addr + 4;
                end if;
                if (rlast = '1' and rvalid = '1') then
                    table(conv_integer(rid)).state <= INIT;
                end if;

                if (writeFrom = IDLE and aDataAwenable = YES and aDataSingleByte = YES) then
                    writeFrom <= CACHE;
                elsif (writeBuffer.state = UNSYNC and writeFrom = IDLE) then
                    writeFrom <= BUF;
                end if;

                if (aDataAwenable = YES and aDataSingleByte = NO and writeBuffer.state = SYNCED) then
                    writeBuffer.present <= '1';
                    writeBuffer.state <= UNSYNC;
                    writeBuffer.readCount <= (others => '0');
                    writeBuffer.tag <= aDataAwaddr(31 downto 6);
                end if;

                if (writeFrom = BUF) then
                    if (bstate = INIT and awready = '1' and wready = '1') then
                        bstate <= WRITE;
                    elsif (bstate = INIT and awready = '1') then
                        bstate <= AOK;
                    elsif (bstate = INIT and wready = '1') then
                        bstate <= DOK;
                    elsif ((bstate = DOK and awready = '1') or (bstate = AOK and wready = '1')) then
                        bstate <= WRITE;
                    elsif (bstate = WRITE and wready = '1' and writeBuffer.sendCount /= "01111") then
                        bstate <= AOK;
                        writeBuffer.sendCount <= writeBuffer.sendCount + '1';
                    end if;
                    if (bvalid = '1') then
                        bstate <= INIT;
                        writeBuffer.state <= SYNCED;
                        writeFrom <= IDLE;
                        writeBuffer.sendCount <= "00000";
                    end if;
                end if;
                if (writeBuffer.state = UNSYNC and writeBuffer.readCount /= "10000") then
                    writeBuffer.data(conv_integer(writeBuffer.readCount(3 downto 0))).data <= aDataAwdata;
                    writeBuffer.readCount <= writeBuffer.readCount + '1';
                end if;

                if (aDataAwenable = ENABLE and aDataSingleByte = YES and writeFrom = CACHE) then
                    if (wstate = INIT and awready = '1' and wready = '1') then
                        wstate <= WRITE;
                    elsif (wstate = INIT and awready = '1') then
                        wstate <= AOK;
                    elsif (wstate = INIT and wready = '1') then
                        wstate <= DOK;
                    elsif ((wstate = DOK and awready = '1') or (wstate = AOK and wready = '1')) then
                        wstate <= WRITE;
                    elsif (wstate = WRITE and bvalid = '1') then
                        wstate <= INIT;
                        writeFrom <= IDLE;
                    end if;
                end if;
            end if;
        end if;
    end process;

    cpu: entity work.cpu
        generic map(
            interruptIv1Offset => 32ux"180"
        )
        port map(
            clk => aclk, rst => areset,

            instEnable_o => aInstArenable,
            instAddr_o => aInstAraddr,
            instRequestAck_i => aInstRequestAck,
            instEnable_i => aInstEnable,
            instData_i => aInstData,
            instAddr_i => aInstAddr,

            dataArenable_o => aDataArenable,
            dataAraddr_o => aDataAraddr,
            dataArrequestAck_i => aDataArrequestAck,
            dataAwenable_o => aDataAwenable,
            dataAwaddr_o => aDataAwaddr,
            dataAwdata_o => aDataAwdata,
            dataAwbyteSelect_o => aDataAwbyteSelect,
            dataAwrequestAck_i => aDataAwrequestAck,
            dataEnable_i => aDataEnable,
            dataData_i => aDataData,
            dataAddr_i => aDataAddr,
            dataSingleByte_o => aDataSingleByte,

            int => int,
            debug_wb_pc => debug_wb_pc,
            debug_wb_rf_wen => debug_wb_rf_wen,
            debug_wb_rf_wnum => debug_wb_rf_wnum,
            debug_wb_rf_wdata => debug_wb_rf_wdata
        );
end bhv;
