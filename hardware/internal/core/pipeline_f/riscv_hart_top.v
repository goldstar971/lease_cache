module riscv_hart_top(

	// system
	input 	[2:0]	clock_bus_i, 
	input 			reset_i,
	output 	[3:0]	exception_bus_o,
	output 	[31:0]	inst_addr_o,
	output 	[31:0] 	inst_word_o,

	// i/o to internal memory controller
	output 	 		mem_req0_o, 
	output 			mem_rw0_o,
	output 	[31:0]	mem_add0_o, 
	output 	[31:0] 	mem_data0_o,
	input 	[31:0]	mem_data0_i, 
	input 			mem_done0_i,

	output 	 		mem_req1_o, 
	output 			mem_rw1_o,
	output 	[31:0]	mem_add1_o, 
	output 	[31:0]	mem_data1_o,
	input 	[31:0]	mem_data1_i, 
	input 			mem_done1_i,

	// i/o to peripheral controller
	output 			per_req_o, 
	output 			per_rw_o,
	output 	[31:0]	per_add_o, 
	output 	[31:0]	per_data_o,
	input 	[31:0]	per_data_i

);

// compatability assignments
assign mem_data0_o 		= 'b0;
assign mem_rw0_o 		= 1'b0;
//assign inst_addr_o 		= 'b0;
assign inst_word_o 		= 'b0;
assign exception_bus_o  = 'b0;


// internal port mapping signals
// --------------------------------------------------------
wire [31:0]	hart_data_data_i;
wire 		hart_data_done;
wire 		hart_data_req;
wire 		hart_data_rw;
wire [31:0]	hart_data_add;
wire [31:0]	hart_data_data_o;


//floating point unit PLL
//---------------------------------------------------------
//wire clk_100MHZ;




// riscv core 
// --------------------------------------------------------
riscv_hart_6stage_pipeline hart_inst(

	// system
	.clock_bus_i 	(clock_bus_i),
	.reset_i 			(reset_i 		 	),

	// internal memory system (inst references)
	.inst_data_i 		(mem_data0_i		), 
	.inst_done_i 		(mem_done0_i 		),
	.inst_req_o 		(mem_req0_o 		), 	
	.inst_addr_o 		(mem_add0_o 		), 
	
	// internal memory system (data references)
	.data_data_i 		(hart_data_data_i 	), 
	.data_done_i 		(hart_data_done 	),
	.data_req_o 		(hart_data_req 		), 
	.data_wren_o 		(hart_data_rw 		),
	.data_addr_o 		(hart_data_add 		), 
	.data_data_o 		(hart_data_data_o 	),
	.data_ref_addr_o 	(inst_addr_o 		)		// misleading name - need to clean it up
);

port_switch peripheral_switch_inst(

	// core/hart ports
	.core_req_i 		(hart_data_req 		),
	.core_wren_i 		(hart_data_rw 		),
	.core_addr_i 		(hart_data_add 		),
	.core_data_i 		(hart_data_data_o 	),
	.core_done_o 		(hart_data_done 	),
	.core_data_o 		(hart_data_data_i 	),

	// internal memory ports
	.memory_done_i 		(mem_done1_i 		),
	.memory_data_i 		(mem_data1_i 		),
	.memory_req_o 		(mem_req1_o 		),
	.memory_wren_o 		(mem_rw1_o 			),
	.memory_addr_o 		(mem_add1_o 		),
	.memory_data_o 		(mem_data1_o 		),

	// peripheral ports
	.peripheral_data_i	(per_data_i			),
	.peripheral_req_o 	(per_req_o 			),
	.peripheral_wren_o 	(per_rw_o 			),
	.peripheral_addr_o 	(per_add_o 			),
	.peripheral_data_o 	(per_data_o 		)	

);

endmodule