module port_switch(

	// core/hart ports
	input 			core_req_i,
	input 			core_wren_i,
	input 	[31:0]	core_addr_i,
	input 	[31:0]	core_data_i,
	output 			core_done_o,
	output 	[31:0]	core_data_o,

	// internal memory ports
	input 			memory_done_i,
	input 	[31:0]	memory_data_i,
	output 			memory_req_o,
	output 			memory_wren_o,
	output 	[31:0]	memory_addr_o,
	output 	[31:0]	memory_data_o,

	// peripheral ports
	//input 			peripheral_done_i,
	input 	[31:0]	peripheral_data_i,
	output 			peripheral_req_o,
	output 			peripheral_wren_o,
	output 	[31:0]	peripheral_addr_o,
	output 	[31:0]	peripheral_data_o 	

);

assign core_done_o 		= (!core_addr_i[26]) ? memory_done_i : 1'b1;
assign core_data_o 		= (!core_addr_i[26]) ? memory_data_i : peripheral_data_i;

assign memory_req_o 	= (!core_addr_i[26]) ? core_req_i : 1'b0;
assign memory_wren_o 	= (!core_addr_i[26]) ? core_wren_i : 1'b0;
assign memory_addr_o 	= (!core_addr_i[26]) ? core_addr_i : 'b0;
assign memory_data_o 	= (!core_addr_i[26]) ? core_data_i : 'b0;

assign peripheral_req_o 	= (core_addr_i[26]) ? core_req_i : 1'b0;
assign peripheral_wren_o 	= (core_addr_i[26]) ? core_wren_i : 1'b0;
assign peripheral_addr_o 	= (core_addr_i[26]) ? core_addr_i : 'b0;
assign peripheral_data_o 	= (core_addr_i[26]) ? core_data_i : 'b0;


endmodule