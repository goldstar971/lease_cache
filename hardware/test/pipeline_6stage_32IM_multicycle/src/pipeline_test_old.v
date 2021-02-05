module pipeline_test(

	input 			clock_i,
	input 			reset_i,
	output 			flag_done_o
);

// control signals
wire 		bram_clock;
assign 		bram_clock = ~clock_i;

// embedded memory signals
wire [31:0]	hart_inst_data_i;
wire 		hart_inst_done;
wire 		hart_inst_req;
wire 		hart_inst_rw;
wire [31:0]	hart_inst_add;
wire [31:0]	hart_inst_data_o;

wire [31:0]	hart_data_data_i;
wire 		hart_data_done;
wire 		hart_data_req;
wire 		hart_data_rw;
wire [31:0]	hart_data_add;
wire [31:0]	hart_data_data_o;

wire 		hart_per_req;
wire 		hart_per_rw;
wire [31:0]	hart_per_add;
wire [31:0]	hart_per_data_o;

assign hart_inst_done = 1'b1;
assign hart_data_done = 1'b1;

assign flag_done_o = ((hart_per_add == 32'h04000104) & (hart_per_rw) & (hart_per_data_o == 32'h00000001)) ? 1'b1: 1'b0;

// riscv core 
// --------------------------------------------------------
riscv_hart_6stage_pipeline hart_inst(

	// system
	.clock_i 		(clock_i 			),
	.reset_i 		(reset_i 		 	),

	// internal memory system (inst references)
	.mem_data0_i 	(hart_inst_data_i	), 
	.mem_done0_i 	(hart_inst_done 	),
	.mem_req0_o 	(hart_inst_req 		), 
	.mem_rw0_o 		(hart_inst_rw 		),	
	.mem_add0_o 	(hart_inst_add 		), 
	.mem_data0_o 	(hart_inst_data_o 	),
	
	// internal memory system (data references)
	.mem_data1_i 	(hart_data_data_i 	), 
	.mem_done1_i 	(hart_data_done 	),
	.mem_req1_o 	(hart_data_req 		), 
	.mem_rw1_o 		(hart_data_rw 		),
	.mem_add1_o 	(hart_data_add 		), 
	.mem_data1_o 	(hart_data_data_o 	),
	
	// peripheral system
	.per_req_o 		(hart_per_req 		), 
	.per_rw_o 		(hart_per_rw 		),
	.per_add_o 		(hart_per_add 		), 
	.per_data_o 	(hart_per_data_o 	),
	.per_data_i 	('b0 				)
);


// memory dummys (brams) - just checking for correct program evaluations
// memory file: test.mif
bram_32b_256kB inst_bram (
	.address 		(hart_inst_add[17:2]),
	.clock 			(bram_clock 		),
	.data 			(hart_inst_data_o	),
	.wren 			(hart_inst_rw 		),
	.q 				(hart_inst_data_i	)
);
bram_32b_256kB data_bram (
	.address 		(hart_data_add[17:2]),
	.clock 			(bram_clock 		),
	.data 			(hart_data_data_o	),
	.wren 			(hart_data_rw 		),
	.q 				(hart_data_data_i	)
);

endmodule