set_property INTERNAL_VREF 0.675 [get_iobanks 34]

set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk_100_mhz]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk_100_mhz]

set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports reset]

set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33} [get_ports compare_error]
set_property -dict {PACKAGE_PIN J5 IOSTANDARD LVCMOS33} [get_ports cs_port]







create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list ram_controller/u_mig_7series_0_mig/u_ddr3_infrastructure/CLK]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 16 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {ram_wdf_mask[0]} {ram_wdf_mask[1]} {ram_wdf_mask[2]} {ram_wdf_mask[3]} {ram_wdf_mask[4]} {ram_wdf_mask[5]} {ram_wdf_mask[6]} {ram_wdf_mask[7]} {ram_wdf_mask[8]} {ram_wdf_mask[9]} {ram_wdf_mask[10]} {ram_wdf_mask[11]} {ram_wdf_mask[12]} {ram_wdf_mask[13]} {ram_wdf_mask[14]} {ram_wdf_mask[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 128 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {ram_rd_data[0]} {ram_rd_data[1]} {ram_rd_data[2]} {ram_rd_data[3]} {ram_rd_data[4]} {ram_rd_data[5]} {ram_rd_data[6]} {ram_rd_data[7]} {ram_rd_data[8]} {ram_rd_data[9]} {ram_rd_data[10]} {ram_rd_data[11]} {ram_rd_data[12]} {ram_rd_data[13]} {ram_rd_data[14]} {ram_rd_data[15]} {ram_rd_data[16]} {ram_rd_data[17]} {ram_rd_data[18]} {ram_rd_data[19]} {ram_rd_data[20]} {ram_rd_data[21]} {ram_rd_data[22]} {ram_rd_data[23]} {ram_rd_data[24]} {ram_rd_data[25]} {ram_rd_data[26]} {ram_rd_data[27]} {ram_rd_data[28]} {ram_rd_data[29]} {ram_rd_data[30]} {ram_rd_data[31]} {ram_rd_data[32]} {ram_rd_data[33]} {ram_rd_data[34]} {ram_rd_data[35]} {ram_rd_data[36]} {ram_rd_data[37]} {ram_rd_data[38]} {ram_rd_data[39]} {ram_rd_data[40]} {ram_rd_data[41]} {ram_rd_data[42]} {ram_rd_data[43]} {ram_rd_data[44]} {ram_rd_data[45]} {ram_rd_data[46]} {ram_rd_data[47]} {ram_rd_data[48]} {ram_rd_data[49]} {ram_rd_data[50]} {ram_rd_data[51]} {ram_rd_data[52]} {ram_rd_data[53]} {ram_rd_data[54]} {ram_rd_data[55]} {ram_rd_data[56]} {ram_rd_data[57]} {ram_rd_data[58]} {ram_rd_data[59]} {ram_rd_data[60]} {ram_rd_data[61]} {ram_rd_data[62]} {ram_rd_data[63]} {ram_rd_data[64]} {ram_rd_data[65]} {ram_rd_data[66]} {ram_rd_data[67]} {ram_rd_data[68]} {ram_rd_data[69]} {ram_rd_data[70]} {ram_rd_data[71]} {ram_rd_data[72]} {ram_rd_data[73]} {ram_rd_data[74]} {ram_rd_data[75]} {ram_rd_data[76]} {ram_rd_data[77]} {ram_rd_data[78]} {ram_rd_data[79]} {ram_rd_data[80]} {ram_rd_data[81]} {ram_rd_data[82]} {ram_rd_data[83]} {ram_rd_data[84]} {ram_rd_data[85]} {ram_rd_data[86]} {ram_rd_data[87]} {ram_rd_data[88]} {ram_rd_data[89]} {ram_rd_data[90]} {ram_rd_data[91]} {ram_rd_data[92]} {ram_rd_data[93]} {ram_rd_data[94]} {ram_rd_data[95]} {ram_rd_data[96]} {ram_rd_data[97]} {ram_rd_data[98]} {ram_rd_data[99]} {ram_rd_data[100]} {ram_rd_data[101]} {ram_rd_data[102]} {ram_rd_data[103]} {ram_rd_data[104]} {ram_rd_data[105]} {ram_rd_data[106]} {ram_rd_data[107]} {ram_rd_data[108]} {ram_rd_data[109]} {ram_rd_data[110]} {ram_rd_data[111]} {ram_rd_data[112]} {ram_rd_data[113]} {ram_rd_data[114]} {ram_rd_data[115]} {ram_rd_data[116]} {ram_rd_data[117]} {ram_rd_data[118]} {ram_rd_data[119]} {ram_rd_data[120]} {ram_rd_data[121]} {ram_rd_data[122]} {ram_rd_data[123]} {ram_rd_data[124]} {ram_rd_data[125]} {ram_rd_data[126]} {ram_rd_data[127]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 28 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {ram_addr[0]} {ram_addr[1]} {ram_addr[2]} {ram_addr[3]} {ram_addr[4]} {ram_addr[5]} {ram_addr[6]} {ram_addr[7]} {ram_addr[8]} {ram_addr[9]} {ram_addr[10]} {ram_addr[11]} {ram_addr[12]} {ram_addr[13]} {ram_addr[14]} {ram_addr[15]} {ram_addr[16]} {ram_addr[17]} {ram_addr[18]} {ram_addr[19]} {ram_addr[20]} {ram_addr[21]} {ram_addr[22]} {ram_addr[23]} {ram_addr[24]} {ram_addr[25]} {ram_addr[26]} {ram_addr[27]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 128 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {ram_wdf_data[0]} {ram_wdf_data[1]} {ram_wdf_data[2]} {ram_wdf_data[3]} {ram_wdf_data[4]} {ram_wdf_data[5]} {ram_wdf_data[6]} {ram_wdf_data[7]} {ram_wdf_data[8]} {ram_wdf_data[9]} {ram_wdf_data[10]} {ram_wdf_data[11]} {ram_wdf_data[12]} {ram_wdf_data[13]} {ram_wdf_data[14]} {ram_wdf_data[15]} {ram_wdf_data[16]} {ram_wdf_data[17]} {ram_wdf_data[18]} {ram_wdf_data[19]} {ram_wdf_data[20]} {ram_wdf_data[21]} {ram_wdf_data[22]} {ram_wdf_data[23]} {ram_wdf_data[24]} {ram_wdf_data[25]} {ram_wdf_data[26]} {ram_wdf_data[27]} {ram_wdf_data[28]} {ram_wdf_data[29]} {ram_wdf_data[30]} {ram_wdf_data[31]} {ram_wdf_data[32]} {ram_wdf_data[33]} {ram_wdf_data[34]} {ram_wdf_data[35]} {ram_wdf_data[36]} {ram_wdf_data[37]} {ram_wdf_data[38]} {ram_wdf_data[39]} {ram_wdf_data[40]} {ram_wdf_data[41]} {ram_wdf_data[42]} {ram_wdf_data[43]} {ram_wdf_data[44]} {ram_wdf_data[45]} {ram_wdf_data[46]} {ram_wdf_data[47]} {ram_wdf_data[48]} {ram_wdf_data[49]} {ram_wdf_data[50]} {ram_wdf_data[51]} {ram_wdf_data[52]} {ram_wdf_data[53]} {ram_wdf_data[54]} {ram_wdf_data[55]} {ram_wdf_data[56]} {ram_wdf_data[57]} {ram_wdf_data[58]} {ram_wdf_data[59]} {ram_wdf_data[60]} {ram_wdf_data[61]} {ram_wdf_data[62]} {ram_wdf_data[63]} {ram_wdf_data[64]} {ram_wdf_data[65]} {ram_wdf_data[66]} {ram_wdf_data[67]} {ram_wdf_data[68]} {ram_wdf_data[69]} {ram_wdf_data[70]} {ram_wdf_data[71]} {ram_wdf_data[72]} {ram_wdf_data[73]} {ram_wdf_data[74]} {ram_wdf_data[75]} {ram_wdf_data[76]} {ram_wdf_data[77]} {ram_wdf_data[78]} {ram_wdf_data[79]} {ram_wdf_data[80]} {ram_wdf_data[81]} {ram_wdf_data[82]} {ram_wdf_data[83]} {ram_wdf_data[84]} {ram_wdf_data[85]} {ram_wdf_data[86]} {ram_wdf_data[87]} {ram_wdf_data[88]} {ram_wdf_data[89]} {ram_wdf_data[90]} {ram_wdf_data[91]} {ram_wdf_data[92]} {ram_wdf_data[93]} {ram_wdf_data[94]} {ram_wdf_data[95]} {ram_wdf_data[96]} {ram_wdf_data[97]} {ram_wdf_data[98]} {ram_wdf_data[99]} {ram_wdf_data[100]} {ram_wdf_data[101]} {ram_wdf_data[102]} {ram_wdf_data[103]} {ram_wdf_data[104]} {ram_wdf_data[105]} {ram_wdf_data[106]} {ram_wdf_data[107]} {ram_wdf_data[108]} {ram_wdf_data[109]} {ram_wdf_data[110]} {ram_wdf_data[111]} {ram_wdf_data[112]} {ram_wdf_data[113]} {ram_wdf_data[114]} {ram_wdf_data[115]} {ram_wdf_data[116]} {ram_wdf_data[117]} {ram_wdf_data[118]} {ram_wdf_data[119]} {ram_wdf_data[120]} {ram_wdf_data[121]} {ram_wdf_data[122]} {ram_wdf_data[123]} {ram_wdf_data[124]} {ram_wdf_data[125]} {ram_wdf_data[126]} {ram_wdf_data[127]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 3 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {ram_cmd[0]} {ram_cmd[1]} {ram_cmd[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list clk_locked]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list compare_error_OBUF]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list ram_en]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list ram_init_calib_complete]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list ram_rd_data_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list ram_rdy]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list ram_wdf_end]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list ram_wdf_rdy]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list ram_wdf_wren]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
