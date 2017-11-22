-makelib ies/xil_defaultlib -sv \
  "D:/Xilinx/Vivado/2017.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
-endlib
-makelib ies/xpm \
  "D:/Xilinx/Vivado/2017.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib ies/xil_defaultlib \
  "../../../../thinpad_top.srcs/sources_1/ip/clk_ctrl/clk_ctrl_clk_wiz.v" \
  "../../../../thinpad_top.srcs/sources_1/ip/clk_ctrl/clk_ctrl.v" \
-endlib
-makelib ies/xil_defaultlib \
  glbl.v
-endlib

