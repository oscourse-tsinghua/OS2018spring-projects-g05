#set_property SEVERITY {Warning} [get_drc_checks RTSTAT-2]

#set unused pins to be high impedence
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullnone [current_design]

#clock
set_property PACKAGE_PIN AC19 [get_ports clk_in]
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets clk_in]
create_clock -period 10.000 -name clk_in -waveform {0.000 5.000} [get_ports clk_in]

# FIXME: Out dated since we changed clk_ctrl to clk_wiz
#derived clock
#create_generated_clock -name clkMain [get_pins -hierarchical *mmcm_adv_inst/CLKOUT0] #    -source [get_pins -hierarchical *mmcm_adv_inst/CLKIN1] #    -master_clock clk_in

#reset
set_property PACKAGE_PIN Y3 [get_ports rst_n]

#LED
set_property PACKAGE_PIN K23 [get_ports {led_n[0]}]
set_property PACKAGE_PIN J21 [get_ports {led_n[1]}]
set_property PACKAGE_PIN H23 [get_ports {led_n[2]}]
set_property PACKAGE_PIN J19 [get_ports {led_n[3]}]
set_property PACKAGE_PIN G9 [get_ports {led_n[4]}]
set_property PACKAGE_PIN J26 [get_ports {led_n[5]}]
set_property PACKAGE_PIN J23 [get_ports {led_n[6]}]
set_property PACKAGE_PIN J8 [get_ports {led_n[7]}]
set_property PACKAGE_PIN H8 [get_ports {led_n[8]}]
set_property PACKAGE_PIN G8 [get_ports {led_n[9]}]
set_property PACKAGE_PIN F7 [get_ports {led_n[10]}]
set_property PACKAGE_PIN A4 [get_ports {led_n[11]}]
set_property PACKAGE_PIN A5 [get_ports {led_n[12]}]
set_property PACKAGE_PIN A3 [get_ports {led_n[13]}]
set_property PACKAGE_PIN D5 [get_ports {led_n[14]}]
set_property PACKAGE_PIN H7 [get_ports {led_n[15]}]

#led_rg 0/1
set_property PACKAGE_PIN G7 [get_ports {led_rg0[0]}]
set_property PACKAGE_PIN F8 [get_ports {led_rg0[1]}]
set_property PACKAGE_PIN B5 [get_ports {led_rg1[0]}]
set_property PACKAGE_PIN D6 [get_ports {led_rg1[1]}]

#NUM
set_property PACKAGE_PIN D3 [get_ports {num_cs_n[7]}]
set_property PACKAGE_PIN D25 [get_ports {num_cs_n[6]}]
set_property PACKAGE_PIN D26 [get_ports {num_cs_n[5]}]
set_property PACKAGE_PIN E25 [get_ports {num_cs_n[4]}]
set_property PACKAGE_PIN E26 [get_ports {num_cs_n[3]}]
set_property PACKAGE_PIN G25 [get_ports {num_cs_n[2]}]
set_property PACKAGE_PIN G26 [get_ports {num_cs_n[1]}]
set_property PACKAGE_PIN H26 [get_ports {num_cs_n[0]}]

set_property PACKAGE_PIN C3 [get_ports {num_a_g[0]}]
set_property PACKAGE_PIN E6 [get_ports {num_a_g[1]}]
set_property PACKAGE_PIN B2 [get_ports {num_a_g[2]}]
set_property PACKAGE_PIN B4 [get_ports {num_a_g[3]}]
set_property PACKAGE_PIN E5 [get_ports {num_a_g[4]}]
set_property PACKAGE_PIN D4 [get_ports {num_a_g[5]}]
set_property PACKAGE_PIN A2 [get_ports {num_a_g[6]}]
#set_property PACKAGE_PIN C4 :DP

#switch
set_property PACKAGE_PIN AC21 [get_ports {switch[7]}]
set_property PACKAGE_PIN AD24 [get_ports {switch[6]}]
set_property PACKAGE_PIN AC22 [get_ports {switch[5]}]
set_property PACKAGE_PIN AC23 [get_ports {switch[4]}]
set_property PACKAGE_PIN AB6 [get_ports {switch[3]}]
set_property PACKAGE_PIN W6 [get_ports {switch[2]}]
set_property PACKAGE_PIN AA7 [get_ports {switch[1]}]
set_property PACKAGE_PIN Y6 [get_ports {switch[0]}]

#btn_key
set_property PACKAGE_PIN V8 [get_ports {btn_key_col[0]}]
set_property PACKAGE_PIN V9 [get_ports {btn_key_col[1]}]
set_property PACKAGE_PIN Y8 [get_ports {btn_key_col[2]}]
set_property PACKAGE_PIN V7 [get_ports {btn_key_col[3]}]
set_property PACKAGE_PIN U7 [get_ports {btn_key_row[0]}]
set_property PACKAGE_PIN W8 [get_ports {btn_key_row[1]}]
set_property PACKAGE_PIN Y7 [get_ports {btn_key_row[2]}]
set_property PACKAGE_PIN AA8 [get_ports {btn_key_row[3]}]

#btn_step
set_property PACKAGE_PIN Y5 [get_ports {btn_step[0]}]
set_property PACKAGE_PIN V6 [get_ports {btn_step[1]}]

#SPI flash
set_property PACKAGE_PIN P20 [get_ports spi_clk]
set_property PACKAGE_PIN R20 [get_ports spi_cs_n]
set_property PACKAGE_PIN P19 [get_ports spi_do]
set_property PACKAGE_PIN N18 [get_ports spi_di]
# CAUTIOUS: DO menas MISO, DI means MOSI
# Please refer to the circuit diagram and double check

#Ethernet
set_property PACKAGE_PIN AB21 [get_ports eth_txclk]
set_property PACKAGE_PIN AA19 [get_ports eth_rxclk]
set_property PACKAGE_PIN AA15 [get_ports eth_txen]
set_property PACKAGE_PIN AF18 [get_ports {eth_txd[0]}]
set_property PACKAGE_PIN AE18 [get_ports {eth_txd[1]}]
set_property PACKAGE_PIN W15 [get_ports {eth_txd[2]}]
set_property PACKAGE_PIN W14 [get_ports {eth_txd[3]}]
set_property PACKAGE_PIN AB20 [get_ports eth_txerr]
set_property PACKAGE_PIN AE22 [get_ports eth_rxdv]
set_property PACKAGE_PIN V1 [get_ports {eth_rxd[0]}]
set_property PACKAGE_PIN V4 [get_ports {eth_rxd[1]}]
set_property PACKAGE_PIN V2 [get_ports {eth_rxd[2]}]
set_property PACKAGE_PIN V3 [get_ports {eth_rxd[3]}]
set_property PACKAGE_PIN W16 [get_ports eth_rxerr]
set_property PACKAGE_PIN Y15 [get_ports eth_coll]
set_property PACKAGE_PIN AF20 [get_ports eth_crs]
set_property PACKAGE_PIN W3 [get_ports eth_mdc]
set_property PACKAGE_PIN W1 [get_ports eth_mdio]
set_property PACKAGE_PIN AE26 [get_ports eth_rst_n]

#uart
set_property PACKAGE_PIN F23 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]
set_property PACKAGE_PIN H19 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]

#nand flash
#set_property PACKAGE_PIN V19 [get_ports NAND_CLE]
#set_property PACKAGE_PIN W20 [get_ports NAND_ALE]
#set_property PACKAGE_PIN AA25 [get_ports NAND_RDY]
#set_property PACKAGE_PIN AA24 [get_ports NAND_RD]
#set_property PACKAGE_PIN AB24 [get_ports NAND_CE]
#set_property PACKAGE_PIN AA22 [get_ports NAND_WR]
#set_property PACKAGE_PIN W19 [get_ports {NAND_DATA[7]}]
#set_property PACKAGE_PIN Y20 [get_ports {NAND_DATA[6]}]
#set_property PACKAGE_PIN Y21 [get_ports {NAND_DATA[5]}]
#set_property PACKAGE_PIN V18 [get_ports {NAND_DATA[4]}]
#set_property PACKAGE_PIN U19 [get_ports {NAND_DATA[3]}]
#set_property PACKAGE_PIN U20 [get_ports {NAND_DATA[2]}]
#set_property PACKAGE_PIN W21 [get_ports {NAND_DATA[1]}]
#set_property PACKAGE_PIN AC24 [get_ports {NAND_DATA[0]}]

#ejtag
#set_property PACKAGE_PIN J18 [get_ports EJTAG_TRST]
#set_property PACKAGE_PIN K18 [get_ports EJTAG_TCK]
#set_property PACKAGE_PIN K20 [get_ports EJTAG_TDI]
#set_property PACKAGE_PIN K22 [get_ports EJTAG_TMS]
#set_property PACKAGE_PIN K21 [get_ports EJTAG_TDO]


set_property IOSTANDARD LVCMOS33 [get_ports clk_in]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports {led_n[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_rg0[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_rg1[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {num_a_g[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {num_cs_n[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {switch[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn_key_col[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn_key_row[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn_step[*]}]

set_property IOSTANDARD LVCMOS33 [get_ports spi_do]
set_property IOSTANDARD LVCMOS33 [get_ports spi_di]
set_property IOSTANDARD LVCMOS33 [get_ports spi_cs_n]
set_property IOSTANDARD LVCMOS33 [get_ports spi_clk]

set_property IOSTANDARD LVCMOS33 [get_ports {eth_rxd[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {eth_txd[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports eth_rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports eth_txerr]
set_property IOSTANDARD LVCMOS33 [get_ports eth_txen]
set_property IOSTANDARD LVCMOS33 [get_ports eth_txclk]
set_property IOSTANDARD LVCMOS33 [get_ports eth_rxerr]
set_property IOSTANDARD LVCMOS33 [get_ports eth_coll]
set_property IOSTANDARD LVCMOS33 [get_ports eth_crs]
set_property IOSTANDARD LVCMOS33 [get_ports eth_mdc]
set_property IOSTANDARD LVCMOS33 [get_ports eth_mdio]
set_property IOSTANDARD LVCMOS33 [get_ports eth_rxclk]
set_property IOSTANDARD LVCMOS33 [get_ports eth_rxdv]

#set_property IOSTANDARD LVCMOS33 [get_ports NAND_CLE]
#set_property IOSTANDARD LVCMOS33 [get_ports NAND_ALE]
#set_property IOSTANDARD LVCMOS33 [get_ports NAND_RDY]
#set_property IOSTANDARD LVCMOS33 [get_ports NAND_RD]
#set_property IOSTANDARD LVCMOS33 [get_ports NAND_CE]
#set_property IOSTANDARD LVCMOS33 [get_ports NAND_WR]
#set_property IOSTANDARD LVCMOS33 [get_ports {NAND_DATA[7]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {NAND_DATA[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {NAND_DATA[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {NAND_DATA[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {NAND_DATA[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {NAND_DATA[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {NAND_DATA[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {NAND_DATA[0]}]

#set_property IOSTANDARD LVCMOS33 [get_ports EJTAG_TRST]
#set_property IOSTANDARD LVCMOS33 [get_ports EJTAG_TCK]
#set_property IOSTANDARD LVCMOS33 [get_ports EJTAG_TDI]
#set_property IOSTANDARD LVCMOS33 [get_ports EJTAG_TMS]
#set_property IOSTANDARD LVCMOS33 [get_ports EJTAG_TDO]
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets EJTAG_TCK_IBUF]

create_clock -period 40.000 -name eth_rxclk -waveform {0.000 20.000} [get_ports eth_rxclk]
create_clock -period 40.000 -name eth_txclk -waveform {0.000 20.000} [get_ports eth_txclk]

# FIXME
#set_false_path -from [get_clocks clk_in] -to [get_clocks clkMain]
#set_false_path -from [get_clocks eth_rxclk] -to [get_clocks clkMain]
#set_false_path -from [get_clocks eth_txclk] -to [get_clocks clkMain]
#set_false_path -from [get_clocks clkMain] -to [get_clocks eth_rxclk]
#set_false_path -from [get_clocks clkMain] -to [get_clocks eth_txclk]

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

connect_debug_port u_ila_0/probe3 [get_nets [list {cpu1_ist/datapath_ist/writeFPRegData_f7[0]} {cpu1_ist/datapath_ist/writeFPRegData_f7[1]} {cpu1_ist/datapath_ist/writeFPRegData_f7[2]} {cpu1_ist/datapath_ist/writeFPRegData_f7[3]} {cpu1_ist/datapath_ist/writeFPRegData_f7[4]} {cpu1_ist/datapath_ist/writeFPRegData_f7[5]} {cpu1_ist/datapath_ist/writeFPRegData_f7[6]} {cpu1_ist/datapath_ist/writeFPRegData_f7[7]} {cpu1_ist/datapath_ist/writeFPRegData_f7[8]} {cpu1_ist/datapath_ist/writeFPRegData_f7[9]} {cpu1_ist/datapath_ist/writeFPRegData_f7[10]} {cpu1_ist/datapath_ist/writeFPRegData_f7[11]} {cpu1_ist/datapath_ist/writeFPRegData_f7[12]} {cpu1_ist/datapath_ist/writeFPRegData_f7[13]} {cpu1_ist/datapath_ist/writeFPRegData_f7[14]} {cpu1_ist/datapath_ist/writeFPRegData_f7[15]} {cpu1_ist/datapath_ist/writeFPRegData_f7[16]} {cpu1_ist/datapath_ist/writeFPRegData_f7[17]} {cpu1_ist/datapath_ist/writeFPRegData_f7[18]} {cpu1_ist/datapath_ist/writeFPRegData_f7[19]} {cpu1_ist/datapath_ist/writeFPRegData_f7[20]} {cpu1_ist/datapath_ist/writeFPRegData_f7[21]} {cpu1_ist/datapath_ist/writeFPRegData_f7[22]} {cpu1_ist/datapath_ist/writeFPRegData_f7[23]} {cpu1_ist/datapath_ist/writeFPRegData_f7[24]} {cpu1_ist/datapath_ist/writeFPRegData_f7[25]} {cpu1_ist/datapath_ist/writeFPRegData_f7[26]} {cpu1_ist/datapath_ist/writeFPRegData_f7[27]} {cpu1_ist/datapath_ist/writeFPRegData_f7[28]} {cpu1_ist/datapath_ist/writeFPRegData_f7[29]} {cpu1_ist/datapath_ist/writeFPRegData_f7[30]} {cpu1_ist/datapath_ist/writeFPRegData_f7[31]} {cpu1_ist/datapath_ist/writeFPRegData_f7[32]} {cpu1_ist/datapath_ist/writeFPRegData_f7[33]} {cpu1_ist/datapath_ist/writeFPRegData_f7[34]} {cpu1_ist/datapath_ist/writeFPRegData_f7[35]} {cpu1_ist/datapath_ist/writeFPRegData_f7[36]} {cpu1_ist/datapath_ist/writeFPRegData_f7[37]} {cpu1_ist/datapath_ist/writeFPRegData_f7[38]} {cpu1_ist/datapath_ist/writeFPRegData_f7[39]} {cpu1_ist/datapath_ist/writeFPRegData_f7[40]} {cpu1_ist/datapath_ist/writeFPRegData_f7[41]} {cpu1_ist/datapath_ist/writeFPRegData_f7[42]} {cpu1_ist/datapath_ist/writeFPRegData_f7[43]} {cpu1_ist/datapath_ist/writeFPRegData_f7[44]} {cpu1_ist/datapath_ist/writeFPRegData_f7[45]} {cpu1_ist/datapath_ist/writeFPRegData_f7[46]} {cpu1_ist/datapath_ist/writeFPRegData_f7[47]} {cpu1_ist/datapath_ist/writeFPRegData_f7[48]} {cpu1_ist/datapath_ist/writeFPRegData_f7[49]} {cpu1_ist/datapath_ist/writeFPRegData_f7[50]} {cpu1_ist/datapath_ist/writeFPRegData_f7[51]} {cpu1_ist/datapath_ist/writeFPRegData_f7[52]} {cpu1_ist/datapath_ist/writeFPRegData_f7[53]} {cpu1_ist/datapath_ist/writeFPRegData_f7[54]} {cpu1_ist/datapath_ist/writeFPRegData_f7[55]} {cpu1_ist/datapath_ist/writeFPRegData_f7[56]} {cpu1_ist/datapath_ist/writeFPRegData_f7[57]} {cpu1_ist/datapath_ist/writeFPRegData_f7[58]} {cpu1_ist/datapath_ist/writeFPRegData_f7[59]} {cpu1_ist/datapath_ist/writeFPRegData_f7[60]} {cpu1_ist/datapath_ist/writeFPRegData_f7[61]} {cpu1_ist/datapath_ist/writeFPRegData_f7[62]} {cpu1_ist/datapath_ist/writeFPRegData_f7[63]}]]
connect_debug_port u_ila_0/probe7 [get_nets [list {cpu2_ist/datapath_ist/writeFPRegData_f7[0]} {cpu2_ist/datapath_ist/writeFPRegData_f7[1]} {cpu2_ist/datapath_ist/writeFPRegData_f7[2]} {cpu2_ist/datapath_ist/writeFPRegData_f7[3]} {cpu2_ist/datapath_ist/writeFPRegData_f7[4]} {cpu2_ist/datapath_ist/writeFPRegData_f7[5]} {cpu2_ist/datapath_ist/writeFPRegData_f7[6]} {cpu2_ist/datapath_ist/writeFPRegData_f7[7]} {cpu2_ist/datapath_ist/writeFPRegData_f7[8]} {cpu2_ist/datapath_ist/writeFPRegData_f7[9]} {cpu2_ist/datapath_ist/writeFPRegData_f7[10]} {cpu2_ist/datapath_ist/writeFPRegData_f7[11]} {cpu2_ist/datapath_ist/writeFPRegData_f7[12]} {cpu2_ist/datapath_ist/writeFPRegData_f7[13]} {cpu2_ist/datapath_ist/writeFPRegData_f7[14]} {cpu2_ist/datapath_ist/writeFPRegData_f7[15]} {cpu2_ist/datapath_ist/writeFPRegData_f7[16]} {cpu2_ist/datapath_ist/writeFPRegData_f7[17]} {cpu2_ist/datapath_ist/writeFPRegData_f7[18]} {cpu2_ist/datapath_ist/writeFPRegData_f7[19]} {cpu2_ist/datapath_ist/writeFPRegData_f7[20]} {cpu2_ist/datapath_ist/writeFPRegData_f7[21]} {cpu2_ist/datapath_ist/writeFPRegData_f7[22]} {cpu2_ist/datapath_ist/writeFPRegData_f7[23]} {cpu2_ist/datapath_ist/writeFPRegData_f7[24]} {cpu2_ist/datapath_ist/writeFPRegData_f7[25]} {cpu2_ist/datapath_ist/writeFPRegData_f7[26]} {cpu2_ist/datapath_ist/writeFPRegData_f7[27]} {cpu2_ist/datapath_ist/writeFPRegData_f7[28]} {cpu2_ist/datapath_ist/writeFPRegData_f7[29]} {cpu2_ist/datapath_ist/writeFPRegData_f7[30]} {cpu2_ist/datapath_ist/writeFPRegData_f7[31]} {cpu2_ist/datapath_ist/writeFPRegData_f7[32]} {cpu2_ist/datapath_ist/writeFPRegData_f7[33]} {cpu2_ist/datapath_ist/writeFPRegData_f7[34]} {cpu2_ist/datapath_ist/writeFPRegData_f7[35]} {cpu2_ist/datapath_ist/writeFPRegData_f7[36]} {cpu2_ist/datapath_ist/writeFPRegData_f7[37]} {cpu2_ist/datapath_ist/writeFPRegData_f7[38]} {cpu2_ist/datapath_ist/writeFPRegData_f7[39]} {cpu2_ist/datapath_ist/writeFPRegData_f7[40]} {cpu2_ist/datapath_ist/writeFPRegData_f7[41]} {cpu2_ist/datapath_ist/writeFPRegData_f7[42]} {cpu2_ist/datapath_ist/writeFPRegData_f7[43]} {cpu2_ist/datapath_ist/writeFPRegData_f7[44]} {cpu2_ist/datapath_ist/writeFPRegData_f7[45]} {cpu2_ist/datapath_ist/writeFPRegData_f7[46]} {cpu2_ist/datapath_ist/writeFPRegData_f7[47]} {cpu2_ist/datapath_ist/writeFPRegData_f7[48]} {cpu2_ist/datapath_ist/writeFPRegData_f7[49]} {cpu2_ist/datapath_ist/writeFPRegData_f7[50]} {cpu2_ist/datapath_ist/writeFPRegData_f7[51]} {cpu2_ist/datapath_ist/writeFPRegData_f7[52]} {cpu2_ist/datapath_ist/writeFPRegData_f7[53]} {cpu2_ist/datapath_ist/writeFPRegData_f7[54]} {cpu2_ist/datapath_ist/writeFPRegData_f7[55]} {cpu2_ist/datapath_ist/writeFPRegData_f7[56]} {cpu2_ist/datapath_ist/writeFPRegData_f7[57]} {cpu2_ist/datapath_ist/writeFPRegData_f7[58]} {cpu2_ist/datapath_ist/writeFPRegData_f7[59]} {cpu2_ist/datapath_ist/writeFPRegData_f7[60]} {cpu2_ist/datapath_ist/writeFPRegData_f7[61]} {cpu2_ist/datapath_ist/writeFPRegData_f7[62]} {cpu2_ist/datapath_ist/writeFPRegData_f7[63]}]]

