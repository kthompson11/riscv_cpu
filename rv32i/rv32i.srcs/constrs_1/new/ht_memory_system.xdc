set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk_100_mhz]
create_clock -period 10.000 -name ASDF -waveform {0.000 5.000} -add [get_ports clk_100_mhz]

set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports reset]
set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33} [get_ports uart_tx]
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS33} [get_ports uart_rx]

set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33} [get_ports compare_error]









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
connect_debug_port u_ila_0/clk [get_nets [list mem_sys/ram_controller/u_mig_7series_0_mig/u_ddr3_infrastructure/CLK]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 28 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {mem_sys/ram_addr[0]} {mem_sys/ram_addr[1]} {mem_sys/ram_addr[2]} {mem_sys/ram_addr[3]} {mem_sys/ram_addr[4]} {mem_sys/ram_addr[5]} {mem_sys/ram_addr[6]} {mem_sys/ram_addr[7]} {mem_sys/ram_addr[8]} {mem_sys/ram_addr[9]} {mem_sys/ram_addr[10]} {mem_sys/ram_addr[11]} {mem_sys/ram_addr[12]} {mem_sys/ram_addr[13]} {mem_sys/ram_addr[14]} {mem_sys/ram_addr[15]} {mem_sys/ram_addr[16]} {mem_sys/ram_addr[17]} {mem_sys/ram_addr[18]} {mem_sys/ram_addr[19]} {mem_sys/ram_addr[20]} {mem_sys/ram_addr[21]} {mem_sys/ram_addr[22]} {mem_sys/ram_addr[23]} {mem_sys/ram_addr[24]} {mem_sys/ram_addr[25]} {mem_sys/ram_addr[26]} {mem_sys/ram_addr[27]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 3 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {mem_sys/ram_cmd[0]} {mem_sys/ram_cmd[1]} {mem_sys/ram_cmd[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 128 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {mem_sys/ram_rd_data[0]} {mem_sys/ram_rd_data[1]} {mem_sys/ram_rd_data[2]} {mem_sys/ram_rd_data[3]} {mem_sys/ram_rd_data[4]} {mem_sys/ram_rd_data[5]} {mem_sys/ram_rd_data[6]} {mem_sys/ram_rd_data[7]} {mem_sys/ram_rd_data[8]} {mem_sys/ram_rd_data[9]} {mem_sys/ram_rd_data[10]} {mem_sys/ram_rd_data[11]} {mem_sys/ram_rd_data[12]} {mem_sys/ram_rd_data[13]} {mem_sys/ram_rd_data[14]} {mem_sys/ram_rd_data[15]} {mem_sys/ram_rd_data[16]} {mem_sys/ram_rd_data[17]} {mem_sys/ram_rd_data[18]} {mem_sys/ram_rd_data[19]} {mem_sys/ram_rd_data[20]} {mem_sys/ram_rd_data[21]} {mem_sys/ram_rd_data[22]} {mem_sys/ram_rd_data[23]} {mem_sys/ram_rd_data[24]} {mem_sys/ram_rd_data[25]} {mem_sys/ram_rd_data[26]} {mem_sys/ram_rd_data[27]} {mem_sys/ram_rd_data[28]} {mem_sys/ram_rd_data[29]} {mem_sys/ram_rd_data[30]} {mem_sys/ram_rd_data[31]} {mem_sys/ram_rd_data[32]} {mem_sys/ram_rd_data[33]} {mem_sys/ram_rd_data[34]} {mem_sys/ram_rd_data[35]} {mem_sys/ram_rd_data[36]} {mem_sys/ram_rd_data[37]} {mem_sys/ram_rd_data[38]} {mem_sys/ram_rd_data[39]} {mem_sys/ram_rd_data[40]} {mem_sys/ram_rd_data[41]} {mem_sys/ram_rd_data[42]} {mem_sys/ram_rd_data[43]} {mem_sys/ram_rd_data[44]} {mem_sys/ram_rd_data[45]} {mem_sys/ram_rd_data[46]} {mem_sys/ram_rd_data[47]} {mem_sys/ram_rd_data[48]} {mem_sys/ram_rd_data[49]} {mem_sys/ram_rd_data[50]} {mem_sys/ram_rd_data[51]} {mem_sys/ram_rd_data[52]} {mem_sys/ram_rd_data[53]} {mem_sys/ram_rd_data[54]} {mem_sys/ram_rd_data[55]} {mem_sys/ram_rd_data[56]} {mem_sys/ram_rd_data[57]} {mem_sys/ram_rd_data[58]} {mem_sys/ram_rd_data[59]} {mem_sys/ram_rd_data[60]} {mem_sys/ram_rd_data[61]} {mem_sys/ram_rd_data[62]} {mem_sys/ram_rd_data[63]} {mem_sys/ram_rd_data[64]} {mem_sys/ram_rd_data[65]} {mem_sys/ram_rd_data[66]} {mem_sys/ram_rd_data[67]} {mem_sys/ram_rd_data[68]} {mem_sys/ram_rd_data[69]} {mem_sys/ram_rd_data[70]} {mem_sys/ram_rd_data[71]} {mem_sys/ram_rd_data[72]} {mem_sys/ram_rd_data[73]} {mem_sys/ram_rd_data[74]} {mem_sys/ram_rd_data[75]} {mem_sys/ram_rd_data[76]} {mem_sys/ram_rd_data[77]} {mem_sys/ram_rd_data[78]} {mem_sys/ram_rd_data[79]} {mem_sys/ram_rd_data[80]} {mem_sys/ram_rd_data[81]} {mem_sys/ram_rd_data[82]} {mem_sys/ram_rd_data[83]} {mem_sys/ram_rd_data[84]} {mem_sys/ram_rd_data[85]} {mem_sys/ram_rd_data[86]} {mem_sys/ram_rd_data[87]} {mem_sys/ram_rd_data[88]} {mem_sys/ram_rd_data[89]} {mem_sys/ram_rd_data[90]} {mem_sys/ram_rd_data[91]} {mem_sys/ram_rd_data[92]} {mem_sys/ram_rd_data[93]} {mem_sys/ram_rd_data[94]} {mem_sys/ram_rd_data[95]} {mem_sys/ram_rd_data[96]} {mem_sys/ram_rd_data[97]} {mem_sys/ram_rd_data[98]} {mem_sys/ram_rd_data[99]} {mem_sys/ram_rd_data[100]} {mem_sys/ram_rd_data[101]} {mem_sys/ram_rd_data[102]} {mem_sys/ram_rd_data[103]} {mem_sys/ram_rd_data[104]} {mem_sys/ram_rd_data[105]} {mem_sys/ram_rd_data[106]} {mem_sys/ram_rd_data[107]} {mem_sys/ram_rd_data[108]} {mem_sys/ram_rd_data[109]} {mem_sys/ram_rd_data[110]} {mem_sys/ram_rd_data[111]} {mem_sys/ram_rd_data[112]} {mem_sys/ram_rd_data[113]} {mem_sys/ram_rd_data[114]} {mem_sys/ram_rd_data[115]} {mem_sys/ram_rd_data[116]} {mem_sys/ram_rd_data[117]} {mem_sys/ram_rd_data[118]} {mem_sys/ram_rd_data[119]} {mem_sys/ram_rd_data[120]} {mem_sys/ram_rd_data[121]} {mem_sys/ram_rd_data[122]} {mem_sys/ram_rd_data[123]} {mem_sys/ram_rd_data[124]} {mem_sys/ram_rd_data[125]} {mem_sys/ram_rd_data[126]} {mem_sys/ram_rd_data[127]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 128 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {mem_sys/ram_wdf_data[0]} {mem_sys/ram_wdf_data[1]} {mem_sys/ram_wdf_data[2]} {mem_sys/ram_wdf_data[3]} {mem_sys/ram_wdf_data[4]} {mem_sys/ram_wdf_data[5]} {mem_sys/ram_wdf_data[6]} {mem_sys/ram_wdf_data[7]} {mem_sys/ram_wdf_data[8]} {mem_sys/ram_wdf_data[9]} {mem_sys/ram_wdf_data[10]} {mem_sys/ram_wdf_data[11]} {mem_sys/ram_wdf_data[12]} {mem_sys/ram_wdf_data[13]} {mem_sys/ram_wdf_data[14]} {mem_sys/ram_wdf_data[15]} {mem_sys/ram_wdf_data[16]} {mem_sys/ram_wdf_data[17]} {mem_sys/ram_wdf_data[18]} {mem_sys/ram_wdf_data[19]} {mem_sys/ram_wdf_data[20]} {mem_sys/ram_wdf_data[21]} {mem_sys/ram_wdf_data[22]} {mem_sys/ram_wdf_data[23]} {mem_sys/ram_wdf_data[24]} {mem_sys/ram_wdf_data[25]} {mem_sys/ram_wdf_data[26]} {mem_sys/ram_wdf_data[27]} {mem_sys/ram_wdf_data[28]} {mem_sys/ram_wdf_data[29]} {mem_sys/ram_wdf_data[30]} {mem_sys/ram_wdf_data[31]} {mem_sys/ram_wdf_data[32]} {mem_sys/ram_wdf_data[33]} {mem_sys/ram_wdf_data[34]} {mem_sys/ram_wdf_data[35]} {mem_sys/ram_wdf_data[36]} {mem_sys/ram_wdf_data[37]} {mem_sys/ram_wdf_data[38]} {mem_sys/ram_wdf_data[39]} {mem_sys/ram_wdf_data[40]} {mem_sys/ram_wdf_data[41]} {mem_sys/ram_wdf_data[42]} {mem_sys/ram_wdf_data[43]} {mem_sys/ram_wdf_data[44]} {mem_sys/ram_wdf_data[45]} {mem_sys/ram_wdf_data[46]} {mem_sys/ram_wdf_data[47]} {mem_sys/ram_wdf_data[48]} {mem_sys/ram_wdf_data[49]} {mem_sys/ram_wdf_data[50]} {mem_sys/ram_wdf_data[51]} {mem_sys/ram_wdf_data[52]} {mem_sys/ram_wdf_data[53]} {mem_sys/ram_wdf_data[54]} {mem_sys/ram_wdf_data[55]} {mem_sys/ram_wdf_data[56]} {mem_sys/ram_wdf_data[57]} {mem_sys/ram_wdf_data[58]} {mem_sys/ram_wdf_data[59]} {mem_sys/ram_wdf_data[60]} {mem_sys/ram_wdf_data[61]} {mem_sys/ram_wdf_data[62]} {mem_sys/ram_wdf_data[63]} {mem_sys/ram_wdf_data[64]} {mem_sys/ram_wdf_data[65]} {mem_sys/ram_wdf_data[66]} {mem_sys/ram_wdf_data[67]} {mem_sys/ram_wdf_data[68]} {mem_sys/ram_wdf_data[69]} {mem_sys/ram_wdf_data[70]} {mem_sys/ram_wdf_data[71]} {mem_sys/ram_wdf_data[72]} {mem_sys/ram_wdf_data[73]} {mem_sys/ram_wdf_data[74]} {mem_sys/ram_wdf_data[75]} {mem_sys/ram_wdf_data[76]} {mem_sys/ram_wdf_data[77]} {mem_sys/ram_wdf_data[78]} {mem_sys/ram_wdf_data[79]} {mem_sys/ram_wdf_data[80]} {mem_sys/ram_wdf_data[81]} {mem_sys/ram_wdf_data[82]} {mem_sys/ram_wdf_data[83]} {mem_sys/ram_wdf_data[84]} {mem_sys/ram_wdf_data[85]} {mem_sys/ram_wdf_data[86]} {mem_sys/ram_wdf_data[87]} {mem_sys/ram_wdf_data[88]} {mem_sys/ram_wdf_data[89]} {mem_sys/ram_wdf_data[90]} {mem_sys/ram_wdf_data[91]} {mem_sys/ram_wdf_data[92]} {mem_sys/ram_wdf_data[93]} {mem_sys/ram_wdf_data[94]} {mem_sys/ram_wdf_data[95]} {mem_sys/ram_wdf_data[96]} {mem_sys/ram_wdf_data[97]} {mem_sys/ram_wdf_data[98]} {mem_sys/ram_wdf_data[99]} {mem_sys/ram_wdf_data[100]} {mem_sys/ram_wdf_data[101]} {mem_sys/ram_wdf_data[102]} {mem_sys/ram_wdf_data[103]} {mem_sys/ram_wdf_data[104]} {mem_sys/ram_wdf_data[105]} {mem_sys/ram_wdf_data[106]} {mem_sys/ram_wdf_data[107]} {mem_sys/ram_wdf_data[108]} {mem_sys/ram_wdf_data[109]} {mem_sys/ram_wdf_data[110]} {mem_sys/ram_wdf_data[111]} {mem_sys/ram_wdf_data[112]} {mem_sys/ram_wdf_data[113]} {mem_sys/ram_wdf_data[114]} {mem_sys/ram_wdf_data[115]} {mem_sys/ram_wdf_data[116]} {mem_sys/ram_wdf_data[117]} {mem_sys/ram_wdf_data[118]} {mem_sys/ram_wdf_data[119]} {mem_sys/ram_wdf_data[120]} {mem_sys/ram_wdf_data[121]} {mem_sys/ram_wdf_data[122]} {mem_sys/ram_wdf_data[123]} {mem_sys/ram_wdf_data[124]} {mem_sys/ram_wdf_data[125]} {mem_sys/ram_wdf_data[126]} {mem_sys/ram_wdf_data[127]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 16 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {mem_sys/ram_wdf_mask[0]} {mem_sys/ram_wdf_mask[1]} {mem_sys/ram_wdf_mask[2]} {mem_sys/ram_wdf_mask[3]} {mem_sys/ram_wdf_mask[4]} {mem_sys/ram_wdf_mask[5]} {mem_sys/ram_wdf_mask[6]} {mem_sys/ram_wdf_mask[7]} {mem_sys/ram_wdf_mask[8]} {mem_sys/ram_wdf_mask[9]} {mem_sys/ram_wdf_mask[10]} {mem_sys/ram_wdf_mask[11]} {mem_sys/ram_wdf_mask[12]} {mem_sys/ram_wdf_mask[13]} {mem_sys/ram_wdf_mask[14]} {mem_sys/ram_wdf_mask[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 32 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {address[0]} {address[1]} {address[2]} {address[3]} {address[4]} {address[5]} {address[6]} {address[7]} {address[8]} {address[9]} {address[10]} {address[11]} {address[12]} {address[13]} {address[14]} {address[15]} {address[16]} {address[17]} {address[18]} {address[19]} {address[20]} {address[21]} {address[22]} {address[23]} {address[24]} {address[25]} {address[26]} {address[27]} {address[28]} {address[29]} {address[30]} {address[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 32 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {read_data[0]} {read_data[1]} {read_data[2]} {read_data[3]} {read_data[4]} {read_data[5]} {read_data[6]} {read_data[7]} {read_data[8]} {read_data[9]} {read_data[10]} {read_data[11]} {read_data[12]} {read_data[13]} {read_data[14]} {read_data[15]} {read_data[16]} {read_data[17]} {read_data[18]} {read_data[19]} {read_data[20]} {read_data[21]} {read_data[22]} {read_data[23]} {read_data[24]} {read_data[25]} {read_data[26]} {read_data[27]} {read_data[28]} {read_data[29]} {read_data[30]} {read_data[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 32 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {write_data[0]} {write_data[1]} {write_data[2]} {write_data[3]} {write_data[4]} {write_data[5]} {write_data[6]} {write_data[7]} {write_data[8]} {write_data[9]} {write_data[10]} {write_data[11]} {write_data[12]} {write_data[13]} {write_data[14]} {write_data[15]} {write_data[16]} {write_data[17]} {write_data[18]} {write_data[19]} {write_data[20]} {write_data[21]} {write_data[22]} {write_data[23]} {write_data[24]} {write_data[25]} {write_data[26]} {write_data[27]} {write_data[28]} {write_data[29]} {write_data[30]} {write_data[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list clk_locked]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list compare_error_OBUF]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list mem_ready]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list op_done]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list op_start]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list op_type]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list mem_sys/ram_en]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list mem_sys/ram_rd_data_valid]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list mem_sys/ram_rdy]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 1 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list mem_sys/ram_wdf_rdy]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
set_property port_width 1 [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list mem_sys/ram_wdf_wren]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
