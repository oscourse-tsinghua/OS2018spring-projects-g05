`default_nettype none

module thinpad_top(/*autoport*/
//inout
         base_ram_data,
         ext_ram_data,
         flash_data,
         sl811_data,
         dm9k_data,
//output
         uart_rdn,
         uart_wrn,
         base_ram_addr,
         base_ram_be_n,
         base_ram_ce_n,
         base_ram_oe_n,
         base_ram_we_n,
         ext_ram_addr,
         ext_ram_be_n,
         ext_ram_ce_n,
         ext_ram_oe_n,
         ext_ram_we_n,
         txd,
         flash_a,
         flash_rp_n,
         flash_vpen,
         flash_oe_n,
         flash_ce_n,
         flash_byte_n,
         flash_we_n,
         sl811_a0,
         sl811_we_n,
         sl811_rd_n,
         sl811_cs_n,
         sl811_rst_n,
         sl811_drq,
         dm9k_cmd,
         dm9k_we_n,
         dm9k_rd_n,
         dm9k_cs_n,
         dm9k_rst_n,
         leds,
         video_pixel,
         video_hsync,
         video_vsync,
         video_clk,
         video_de,
//input
         clk_in,
         clk_uart_in,
         uart_dataready,
         uart_tbre,
         uart_tsre,
         rxd,
         sl811_dack,
         sl811_int,
         dm9k_int,
         dip_sw,
         touch_btn);

input wire clk_in; //50MHz main clock input
input wire clk_uart_in; //11.0592MHz clock for UART

//UART controller signals
output wire uart_rdn;
output wire uart_wrn;
input wire uart_dataready;
input wire uart_tbre;
input wire uart_tsre;

//Base memory signals, a.k.a. RAM1
inout wire[31:0] base_ram_data; // [7:0] also connected to CPLD
output wire[19:0] base_ram_addr;
output wire[3:0] base_ram_be_n;
output wire base_ram_ce_n;
output wire base_ram_oe_n;
output wire base_ram_we_n;
//assign base_ram_be_n=4'b0; // keep ByteEnable zero if you don't know what it is

//Extension memory signals
inout wire[31:0] ext_ram_data;
output wire[19:0] ext_ram_addr;
output wire[3:0] ext_ram_be_n;
output wire ext_ram_ce_n;
output wire ext_ram_oe_n;
output wire ext_ram_we_n;
//assign ext_ram_be_n=4'b0; // keep ByteEnable zero if you don't know what it is

//Ext serial port signals
output wire txd;
input wire rxd;

//Flash memory, JS28F640
output wire [22:0]flash_a;
output wire flash_rp_n;
output wire flash_vpen;
output wire flash_oe_n;
inout wire [15:0]flash_data;
output wire flash_ce_n;
output wire flash_byte_n;
output wire flash_we_n;

//SL811 USB controller signals
output wire sl811_a0;
inout wire[7:0] sl811_data;
output wire sl811_we_n;
output wire sl811_rd_n;
output wire sl811_cs_n;
output wire sl811_rst_n;
input wire sl811_dack;
input wire sl811_int;
output wire sl811_drq;

//DM9000 Ethernet controller signals
output wire dm9k_cmd;
inout wire[15:0] dm9k_data;
output wire dm9k_we_n;
output wire dm9k_rd_n;
output wire dm9k_cs_n;
output wire dm9k_rst_n;
input wire dm9k_int;

//LED, SegDisp, DIP SW, and BTN1~6
output wire[31:0] leds; // leds[31:16] is SegDisp, leds[15:0] is LEDs
input wire[31:0] dip_sw;
input wire[5:0] touch_btn;

//Video output
output wire[7:0] video_pixel;
output wire video_hsync;
output wire video_vsync;
output wire video_clk;
output wire video_de;

/* =========== END OF PORT DECLARATION ============= */

wire rst;
assign rst = touch_btn[5];

wire clk25; // 25MHz clock
clk_ctrl clk_ctrl_ist(
    .reset(rst),
    .clk_in1(clk_in),
    .clk_out1(clk25)
);

wire devEnable, devWrite, devBusy;
wire[31:0] dataSave, dataLoad, addr;
wire[3:0] byteSelect;
wire[5:0] int;
wire timerInt;
assign int = {5'h0, timerInt};
cpu cpu_ist(
    .clk(clk25),
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

wire ramEnable, ramReadEnable, ramWriteBusy;
wire[31:0] ramDataSave, ramDataLoad;

wire flashEnable, flashReadEnable, flashBusy;
wire[31:0] flashDataLoad;

devctrl devctrl_ist(
    .devEnable_i(devEnable),
    .devWrite_i(devWrite),
    .devBusy_o(devBusy),
    .devDataSave_i(dataSave),
    .devDataLoad_o(dataLoad),
    .devPhysicalAddr_i(addr),

    .ramEnable_o(ramEnable),
    .ramReadEnable_o(ramReadEnable),
    .ramDataSave_o(ramDataSave),
    .ramDataLoad_i(ramDataLoad),
    .ramWriteBusy_i(ramWriteBusy),

    .flashEnable_o(flashEnable),
    .flashReadEnable_o(flashReadEnable),
    .flashDataLoad_i(flashDataLoad),
    .flashBusy_i(flashBusy)
);

sram_ctrl base_sram_ctrl(
    .clk(clk25),
    .rst(rst),
    .enable_i(ramEnable),
    .readEnable_i(ramReadEnable),
    .addr_i(addr),
    .byteSelect_i(byteSelect),
    .dataSave_i(ramDataSave),
    .dataLoad_o(ramDataLoad),
    .busy_o(ramWriteBusy),
    .data_io(base_ram_data),
    .addr_o(base_ram_addr),
    .be_n_o(base_ram_be_n),
    .ce_n_o(base_ram_ce_n),
    .oe_n_o(base_ram_oe_n),
    .we_n_o(base_ram_we_n)
);

flash_ctrl flash_ctrl_ist(
    .clk(clk25),
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

/* sram_ctrl Test 1: Alternatively write and read
 * 1. Press and release rst
 * 2. LED should show 0xAAAA pattern
 */
/*
reg[15:0] count, correct, testDataSave;
reg reading;
assign addr = count;
assign ramEnable = 1;
assign ramReadEnable = reading;
assign byteSelect = 4'hf;
assign leds[15:0] = correct;
assign ramDataSave = {16'h0, testDataSave};
always@(posedge clk25) begin
    if (rst) begin
        count <= 0;
        correct <= 0;
        reading <= 0;
    end else begin
        if (count < 16'haaaa || reading == 0) begin
            if (reading == 0) begin
                testDataSave <= count;
            end else begin
                if (ramDataLoad[15:0] == count)
                    correct <= correct + 1;
                count <= count + 1;
            end
            reading <= ~reading;
        end
    end
end
*/

/* sram_ctrl Test 2: Load arbitary data
 * 1. Upload RAM initializing file
 * 2. Press and release reset
 * 3. Set the switches and watch the LEDs
 */
/*
assign ramEnable = 1;
assign ramReadEnable = 1;
assign byteSelect = 4'hf;
assign addr = dip_sw;
assign leds[15:0] = ramDataLoad[15:0];
*/

endmodule
