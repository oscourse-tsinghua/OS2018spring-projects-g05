// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.2 (win64) Build 1909853 Thu Jun 15 18:39:09 MDT 2017
// Date        : Thu Nov 23 18:23:34 2017
// Host        : LAPTOP-FKIVSI39 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               D:/docs/projects/nCore/thinpad_top/thinpad_top.srcs/sources_1/ip/clk_ctrl/clk_ctrl_stub.v
// Design      : clk_ctrl
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tfgg676-2L
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_ctrl(clk_out1, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_out1,clk_in1" */;
  output clk_out1;
  input clk_in1;
endmodule
