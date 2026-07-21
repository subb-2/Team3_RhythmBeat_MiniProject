set_property SRC_FILE_INFO {cfile:c:/Users/kccistc/Downloads/0715_mini_Project_final/0715_mini_Project_final.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_board.xdc rfile:../0715_mini_Project_final.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_board.xdc id:1 order:EARLY used_in_board:yes scoped_inst:U_VGAcam/clk_div/inst prop_thru_buffer:yes} [current_design]
set_property SRC_FILE_INFO {cfile:c:/Users/kccistc/Downloads/0715_mini_Project_final/0715_mini_Project_final.gen/sources_1/ip/clk_wiz_0/clk_wiz_0.xdc rfile:../0715_mini_Project_final.gen/sources_1/ip/clk_wiz_0/clk_wiz_0.xdc id:2 order:EARLY scoped_inst:U_VGAcam/clk_div/inst} [current_design]
set_property SRC_FILE_INFO {cfile:c:/Users/kccistc/Downloads/0715_mini_Project_final/0715_mini_Project_final.gen/sources_1/ip/clk_wiz_0/clk_wiz_0.xdc rfile:../0715_mini_Project_final.gen/sources_1/ip/clk_wiz_0/clk_wiz_0.xdc id:3 order:EARLY scoped_inst:instance_name/inst} [current_design]
current_instance U_VGAcam/clk_div/inst
set_property src_info {type:SCOPED_XDC file:1 line:3 export:INPUT save:INPUT read:READ} [current_design]
set_property BOARD_PIN {clk} [get_ports clk_in1]
set_property src_info {type:SCOPED_XDC file:2 line:57 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter [get_clocks -of_objects [get_ports clk_in1]] 0.1
current_instance
current_instance instance_name/inst
set_property src_info {type:SCOPED_XDC file:3 line:57 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter [get_clocks -of_objects [get_ports clk_in1]] 0.1
