`default_nettype none

module top(/*autoport*/
    clk_in,
    rst_n,
    led_n,
    led_rg0, led_rg1,
    num_cs_n, num_a_g,
    switch,
    btn_key_col, btn_key_row,
    btn_step,
    spi_clk, spi_cs_n, spi_di, spi_do,
    eth_txclk, eth_rxclk, eth_txen, eth_txd, eth_txerr, eth_rxdv, eth_rxd,
    eth_rxerr, eth_coll, eth_crs, eth_mdc, eth_mdio, eth_rst_n,
    uart_rx, uart_tx
);

input wire clk_in; //100MHz clock input
input wire rst_n; // Reset

output wire[15:0] led_n; // Single color LED
output wire[1:0] led_rg0, led_rg1; // Dual color LED

output wire[7:0] num_cs_n; // 7-seg enable
output wire[6:0] num_a_g; // 7-seg data

input wire[7:0] switch; // Switches
input wire[3:0] btn_key_col, btn_key_row; // Keypad
input wire[1:0] btn_step; // Pulse button

// SPI flash EN25F80
output wire spi_clk; // clock
output wire spi_cs_n; // enable
output wire spi_di; // data CPU -> flash
input wire spi_do; // data flash -> CPU

// Ethernet DM9161AEP
input wire eth_txclk; // Transmit reference clock
input wire eth_rxclk; // Receive reference clock
output wire eth_txen; // Transmit enable
output wire[3:0] eth_txd; // Transmit data
output wire eth_txerr; // Transmit error
input wire eth_rxdv; // Receive valid
input wire[3:0] eth_rxd; // Receive data
input wire eth_rxerr; // Receive error
input wire eth_coll; // Collision
input wire eth_crs; // Carrier sence detect
output wire eth_mdc; // Management data clock
inout wire eth_mdio; // Management data I/O
output wire eth_rst_n; // Reset

//UART
input wire uart_rx; // Receive
output wire uart_tx; // Transmit

/* =========== END OF PORT DECLARATION ============= */

wire rst;
assign rst = ~rst_n;

wire clkMain; // 25MHz clock
clk_ctrl clk_ctrl_ist(
    .clk_in1(clk_in),
    .clk_out1(clkMain)
);

// Serial COM
wire rxdReady, txdBusy, txdStart;
wire[7:0] rxdData, txdData;
async_receiver
    #(.ClkFrequency(25000000), .Baud(9600))
    uart_r(.clk(clkMain), .RxD(uart_rx), .RxD_data_ready(rxdReady), .RxD_data(rxdData));
async_transmitter
    #(.ClkFrequency(25000000),.Baud(9600))
    uart_t(.clk(clkMain), .TxD(uart_tx), .TxD_busy(txdBusy), .TxD_start(txdStart), .TxD_data(txdData));

wire devEnable, devWrite, devBusy;
wire[31:0] dataSave, dataLoad, addr;
wire[3:0] byteSelect;
wire[5:0] int;
wire timerInt, comInt, usbInt, ethInt;
assign int = {timerInt, 1'b0, 1'b0, comInt, ethInt, usbInt};
// NOTE: 1'b0 cannot be written as 0
// MIPS standard requires int[5] = timer
// Monitor requires int[2] = COM

cpu #(
`ifdef FUNC_TEST
    .exceptBootBaseAddr(32'h80000000),
    .tlbRefillExl0Offset(32'h180),
`elsif MONITOR
    .exceptBootBaseAddr(32'h80000000),
    .tlbRefillExl0Offset(32'h1000),
    .generalExceptOffset(32'h1180),
`endif
`ifdef USE_BOOTLOADER
    .instEntranceAddr(32'hbfc00000)
`else
    .instEntranceAddr(32'h80000000)
`endif
) cpu_ist (
    .clk(clkMain),
    .rst(rst),
    .devEnable_o(devEnable),
    .devWrite_o(devWrite),
    .devBusy_i(devBusy),
    .devDataSave_o(dataSave),
    .devDataLoad_i(dataLoad),
    .devPhysicalAddr_o(addr),
    .devByteSelect_o(byteSelect),
    .int_i(int),
    .timerInt_o(timerInt)
);

wire ram0Enable, ram0ReadEnable, ram0WriteBusy;
wire[31:0] ram0DataSave, ram0DataLoad;
wire ram1Enable, ram1ReadEnable, ram1WriteBusy;
wire[31:0] ram1DataSave, ram1DataLoad;

wire flashEnable, flashReadEnable, flashBusy;
wire[31:0] flashDataLoad;

wire vgaEnable, vgaWriteEnable;
wire[31:0] vgaWriteData;
//assign video_clk = clkMain;

wire ltcEnable, ltcReadEnable, ltcBusy;
wire[31:0] ltcDataLoad;

wire comEnable, comReadEnable;
wire[31:0] comDataSave, comDataLoad;

wire usbEnable, usbReadEnable, usbWriteEnable, usbBusy;
wire[31:0] usbReadData, usbWriteData;

wire ethEnable, ethReadEnable, ethWriteBusy;
wire[31:0] ethDataLoad, ethDataSave;

wire[31:0] bootDataLoad;

wire ledEnable, numEnable;
wire[15:0] ledData;
wire[31:0] numData;

devctrl devctrl_ist(
    .devEnable_i(devEnable),
    .devWrite_i(devWrite),
    .devBusy_o(devBusy),
    .devDataSave_i(dataSave),
    .devDataLoad_o(dataLoad),
    .devPhysicalAddr_i(addr),

    .ram0Enable_o(ram0Enable),
    .ram0ReadEnable_o(ram0ReadEnable),
    .ram0DataSave_o(ram0DataSave),
    .ram0DataLoad_i(ram0DataLoad),
    .ram0WriteBusy_i(ram0WriteBusy),
    .ram1Enable_o(ram1Enable),
    .ram1ReadEnable_o(ram1ReadEnable),
    .ram1DataSave_o(ram1DataSave),
    .ram1DataLoad_i(ram1DataLoad),
    .ram1WriteBusy_i(ram1WriteBusy),

    .flashEnable_o(flashEnable),
    .flashReadEnable_o(flashReadEnable),
    .flashDataLoad_i(flashDataLoad),
    .flashBusy_i(flashBusy),

    .vgaEnable_o(vgaEnable),
    .vgaWriteEnable_o(vgaWriteEnable),
    .vgaWriteData_o(vgaWriteData),

    .comEnable_o(comEnable),
    .comReadEnable_o(comReadEnable),
    .comDataSave_o(comDataSave),
    .comDataLoad_i(comDataLoad),

    .usbEnable_o(usbEnable),
    .usbReadEnable_o(usbReadEnable),
    .usbReadData_i(usbReadData),
    .usbWriteEnable_o(usbWriteEnable),
    .usbWriteData_o(usbWriteData),
    .usbBusy_i(usbBusy),

    .bootDataLoad_i(bootDataLoad),

    .ltcEnable_o(ltcEnable),
    .ltcReadEnable_o(ltcReadEnable),
    .ltcDataLoad_i(ltcDataLoad),
    .ltcBusy_i(ltcBusy),

    .ethEnable_o(ethEnable),
    .ethReadEnable_o(ethReadEnable),
    .ethDataLoad_i(ethDataLoad),
    .ethDataSave_o(ethDataSave),
    .ethWriteBusy_i(ethWriteBusy),

    .ledEnable_o(ledEnable),
    .ledData_o(ledData),
    .numEnable_o(numEnable),
    .numData_o(numData)
);

// Please don't pass inout port into a sub-module
/*
wire ram0TriStateWrite;
sram_ctrl base_sram_ctrl(
    .clk(clkMain),
    .rst(rst),
    .enable_i(ram0Enable),
    .readEnable_i(ram0ReadEnable),
    .addr_i(addr),
    .byteSelect_i(byteSelect),
    .busy_o(ram0WriteBusy),
    .triStateWrite_o(ram0TriStateWrite),
    .addr_o(base_ram_addr),
    .be_n_o(base_ram_be_n),
    .ce_n_o(base_ram_ce_n),
    .oe_n_o(base_ram_oe_n),
    .we_n_o(base_ram_we_n)
);
assign base_ram_data = ram0TriStateWrite ? ram0DataSave : 32'hzzzzzzzz;
assign ram0DataLoad = base_ram_data;

wire ram1TriStateWrite;
sram_ctrl ext_sram_ctrl(
    .clk(clkMain),
    .rst(rst),
    .enable_i(ram1Enable),
    .readEnable_i(ram1ReadEnable),
    .addr_i(addr),
    .byteSelect_i(byteSelect),
    .busy_o(ram1WriteBusy),
    .triStateWrite_o(ram1TriStateWrite),
    .addr_o(ext_ram_addr),
    .be_n_o(ext_ram_be_n),
    .ce_n_o(ext_ram_ce_n),
    .oe_n_o(ext_ram_oe_n),
    .we_n_o(ext_ram_we_n)
);
assign ext_ram_data = ram1TriStateWrite ? ram1DataSave : 32'hzzzzzzzz;
assign ram1DataLoad = ext_ram_data;
*/

/*
flash_ctrl flash_ctrl_ist(
    .clk(clkMain),
    .rst(rst),
    .devEnable_i(flashEnable),
    .addr_i(addr),
    .readEnable_i(flashReadEnable),
    .readData_o(flashDataLoad),
    .busy_o(flashBusy),
    .flRst_o(flash_rp_n),
    .flOE_o(flash_oe_n),
    .flCE_o(flash_ce_n),
    .flWE_o(flash_we_n),
    .flAddr_o(flash_a),
    .flData_i(flash_data),
    .flByte_o(flash_byte_n),
    .flVpen_o(flash_vpen)
);
*/

/*
vga_ctrl vga_ctrl_ist(
    .clk(clkMain),
    .rst(rst),
    .devEnable_i(vgaEnable),
    .addr_i(addr),
    .writeEnable_i(vgaWriteEnable),
    .writeData_i(vgaWriteData),
    .writeByteSelect_i(byteSelect),
    .de_o(video_de),
    .rgb_o(video_pixel),
    .hs_o(video_hsync),
    .vs_o(video_vsync)
);
*/

serial_ctrl serial_ctrl_ist(
    .clk(clkMain),
    .rst(rst),
    .enable_i(comEnable),
    .readEnable_i(comReadEnable),
    .mode_i(addr[2]),
    .dataSave_i(comDataSave),
    .dataLoad_o(comDataLoad),
    .int_o(comInt),
    .rxdReady_i(rxdReady),
    .rxdData_i(rxdData),
    .txdBusy_i(txdBusy),
    .txdStart_o(txdStart),
    .txdData_o(txdData)
);

/*
wire usbTriStateWrite;
usb_ctrl usb_ctrl_ist(
    .clk(clkMain),
    .rst(rst),
    .devEnable_i(usbEnable),
    .addr_i(addr),
    .readEnable_i(usbReadEnable),
    .writeEnable_i(usbWriteEnable),
    .busy_o(usbBusy),
    .int_o(usbInt),
    .triStateWrite_o(usbTriStateWrite),
    .usbA0_o(sl811_a0),
    .usbWE_o(sl811_we_n),
    .usbRD_o(sl811_rd_n),
    .usbCS_o(sl811_cs_n),
    .usbRst_o(sl811_rst_n),
    .usbDACK_o(sl811_dack),
    .usbInt_i(sl811_int)
);
assign sl811_data = usbTriStateWrite ? usbWriteData[7:0] : 8'hzz;
assign usbReadData = {24'b0, sl811_data};
*/

boot_ctrl boot_ctrl_ist(
    .addr_i(addr),
    .readData_o(bootDataLoad)
);

lattice_ram_ctrl lattice_ram_ctrl_ist(
    .clk(clkMain),
    .rst(rst),
    .devEnable_i(ltcEnable),
    .readEnable_i(ltcReadEnable),
    .addr_i(addr),
    .readData_o(ltcDataLoad),
    .busy_o(ltcBusy)
);

/*
wire ethTriStateWrite;
eth_ctrl eth_ctrl_ist(
    .clk(clkMain),
    .rst(rst),
    .enable_i(ethEnable),
    .readEnable_i(ethReadEnable),
    .addr_i(addr),
    .writeBusy_o(ethWriteBusy),
    .int_o(ethInt),
    .triStateWrite_o(ethTriStateWrite),

    .ethInt_i(dm9k_int),
    .ethCmd_o(dm9k_cmd),
    .ethWE_o(dm9k_we_n),
    .ethRD_o(dm9k_rd_n),
    .ethCS_o(dm9k_cs_n),
    .ethRst_o(dm9k_rst_n)
);
assign dm9k_data = ethTriStateWrite ? ethDataSave[15:0] : 16'hzzzz;
assign ethDataLoad = {16'b0, dm9k_data};
*/

seg7_ctrl seg7_ctrl_ist(
    .clk(clkMain),
    .rst(rst),
    .we_i(numEnable),
    .data_i(numData),
    .cs_n_o(num_cs_n),
    .lights_o(num_a_g)
);

reg[15:0] ledHold;
assign led_n = ~ledHold;
always@(posedge clkMain) begin
    if (rst == 1) begin
        ledHold <= 0;
    end else begin
        if (ledEnable)
            ledHold <= ledData;
    end
end

endmodule
