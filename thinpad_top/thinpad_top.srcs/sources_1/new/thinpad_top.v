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
assign base_ram_be_n=4'b0; // keep ByteEnable zero if you don't know what it is

//Extension memory signals
inout wire[31:0] ext_ram_data;
output wire[19:0] ext_ram_addr;
output wire[3:0] ext_ram_be_n;
output wire ext_ram_ce_n;
output wire ext_ram_oe_n;
output wire ext_ram_we_n;
assign ext_ram_be_n=4'b0; // keep ByteEnable zero if you don't know what it is

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

/* =========== Demo code begin =========== */

// 7-Segment display decoder
reg[7:0] number;
SEG7_LUT segL(.oSEG1({leds[23:22],leds[19:17],leds[20],leds[21],leds[16]}), .iDIG(number[3:0]));
SEG7_LUT segH(.oSEG1({leds[31:30],leds[27:25],leds[28],leds[29],leds[24]}), .iDIG(number[7:4]));

//LED & DIP switches test
reg[23:0] counter;
reg[15:0] led_bits;
always@(posedge clk_in) begin
    if(touch_btn[5])begin //reset
        counter<=0;
        led_bits[15:0] <= dip_sw[15:0]^dip_sw[31:16];
        number <= 0;
    end
    else begin
        counter<= counter+1;
        if(&counter)begin
            led_bits[15:0] <= {led_bits[14:0],led_bits[15]};
            number <= number + 1;
        end
    end
end
assign leds[15:0] = led_bits;

//Ext serial port receive and transmit, 115200 baudrate, no parity
wire [7:0] RxD_data;
wire RxD_data_ready;
async_receiver #(.ClkFrequency(11059200),.Baud(115200)) 
    uart_r(.clk(clk_uart_in),.RxD(rxd),.RxD_data_ready(RxD_data_ready),.RxD_data(RxD_data));
async_transmitter #(.ClkFrequency(11059200),.Baud(115200)) 
    uart_t(.clk(clk_uart_in),.TxD(txd),.TxD_start(RxD_data_ready),.TxD_data(RxD_data)); //transmit data back

//VGA display pattern generation
wire [2:0] red,green;
wire [1:0] blue;
assign video_pixel = {red,green,blue};
assign video_clk = clk_in;
vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    .clk(clk_in), 
    .hdata(red),
    .vdata({blue,green}),
    .hsync(video_hsync),
    .vsync(video_vsync),
    .data_enable(video_de)
);
/* =========== Demo code end =========== */

endmodule
