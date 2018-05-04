vlib work
vlog -incr +incdir+../../thinpad_top/thinpad_top.srcs/sources_1/ip/clk_wiz ../../thinpad_top/thinpad_top.srcs/sources_1/ip/clk_wiz/clk_wiz_clk_wiz.v ../../thinpad_top/thinpad_top.srcs/sources_1/ip/clk_wiz/clk_wiz.v
vcom -2008 ../../src/ddr3_ctrl.vhd ../../src/ddr3_ctrl_100.vhd
vcom -2008 ddr3_high_throughput_test_top.vhd ddr3_sim_test_top.vhd 

vlog -incr ../../thinpad_top/thinpad_top.srcs/sources_1/ip/mig_ddr3/mig_ddr3/user_design/rtl/mig_ddr3.v
vlog -incr ../../thinpad_top/thinpad_top.srcs/sources_1/ip/mig_ddr3/mig_ddr3/user_design/rtl/mig_ddr3_mig_sim.v
vlog -incr ../../thinpad_top/thinpad_top.srcs/sources_1/ip/mig_ddr3/mig_ddr3/user_design/rtl/clocking/*.v
vlog -incr ../../thinpad_top/thinpad_top.srcs/sources_1/ip/mig_ddr3/mig_ddr3/user_design/rtl/axi/*.v
vlog -incr ../../thinpad_top/thinpad_top.srcs/sources_1/ip/mig_ddr3/mig_ddr3/user_design/rtl/controller/*.v
vlog -incr ../../thinpad_top/thinpad_top.srcs/sources_1/ip/mig_ddr3/mig_ddr3/user_design/rtl/ecc/*.v
vlog -incr ../../thinpad_top/thinpad_top.srcs/sources_1/ip/mig_ddr3/mig_ddr3/user_design/rtl/ip_top/*.v
vlog -incr ../../thinpad_top/thinpad_top.srcs/sources_1/ip/mig_ddr3/mig_ddr3/user_design/rtl/phy/*.v
vlog -incr ../../thinpad_top/thinpad_top.srcs/sources_1/ip/mig_ddr3/mig_ddr3/user_design/rtl/ui/*.v
vlog -sv +define+x1Gb +define+sg125 +define+x16 ../../thinpad_top/thinpad_top.srcs/sources_1/ip/mig_ddr3/mig_ddr3/example_design/sim/ddr3_model.sv
vlog -incr $env(XILINX_VIVADO)/data/verilog/src/glbl.v

vsim -t fs -novopt +notimingchecks -L unisims_ver -L secureip -L simprims_ver -L unimacro_ver -L xpm work.ddr3_sim_test_top glbl

add wave sim:/ddr3_sim_test_top/top_ist/*
#add wave sim:/ddr3_sim_test_top/top_ist/ddr3_ctrl_ist/*
radix hex

run 120us
view wave