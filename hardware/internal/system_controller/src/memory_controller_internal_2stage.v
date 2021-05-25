`define 	MEM_ACCESS_cacheL1I 	1'b0
`define 	MEM_ACCESS_cacheL1D 	1'b1

module memory_controller_internal_2stage(

	// general i/o
	input 		[2:0]	clock_bus_i, 		// clock[0] - 90deg phase, clock[1] - 180deg phase, clock[2] - 270deg phase 
	//input 				clock_cntrl_i, 		// clock - 0deg phase
	input 				reset_i, 
	output 		[7:0]	exceptions_o,

	// i/o - core
	input 				core_req0_i, core_rw0_i, 
	input 		[31:0]	core_add0_i, core_data0_i, 
	output 		[31:0]	core_data0_o,
	output 				core_done0_o,

	input 				core_req1_i, core_rw1_i, 
	input 		[31:0]	core_add1_i, core_data1_i, 
	output 		[31:0]	core_data1_o,
	output 				core_done1_o,

	// i/o - external controller - handled by comm buffer
	output 				mem_req_o, mem_reqBlock_o, mem_clear_o, mem_rw_o, 
	output 	 	[23:0]	mem_add_o, 
	output 	 	[31:0]	mem_data_o,
	input 				mem_done_i, mem_ready_i, mem_valid_i,
	input 		[31:0]	mem_data_i,

	// single cache
	// i/o to/from processor
	output 				cacheL1I_core_req_o, cacheL1I_core_rw_o, 	// to cache
	output 		[23:0]	cacheL1I_core_add_o, 
	output 		[31:0]	cacheL1I_core_data_o,
	input 				cacheL1I_core_done_i, 					// from cache
	input 		[31:0]	cacheL1I_core_data_i,				

	// i/o to/from l2
	output 				cacheL1I_uc_en_o, cacheL1I_uc_ready_o, cacheL1I_uc_write_ready_o, cacheL1I_uc_read_ready_o,
	output 		[31:0]	cacheL1I_uc_data_o,
	input 				cacheL1I_hit_i, cacheL1I_req_i, cacheL1I_reqBlock_i, cacheL1I_rw_i, cacheL1I_read_i, cacheL1I_write_i,
	input 		[23:0]	cacheL1I_add_i,
	input 		[31:0]	cacheL1I_data_i,

	// i/o to/from processor
	output 				cacheL1D_core_req_o, cacheL1D_core_rw_o, 	// to cache
	output 		[23:0]	cacheL1D_core_add_o, 
	output 		[31:0]	cacheL1D_core_data_o,
	input 				cacheL1D_core_done_i, 					// from cache
	input 		[31:0]	cacheL1D_core_data_i,				

	// i/o to/from l2
	output 				cacheL1D_uc_en_o, cacheL1D_uc_ready_o, cacheL1D_uc_write_ready_o, cacheL1D_uc_read_ready_o,
	output 		[31:0]	cacheL1D_uc_data_o,
	input 				cacheL1D_hit_i, cacheL1D_req_i, cacheL1D_reqBlock_i, cacheL1D_rw_i, cacheL1D_read_i, cacheL1D_write_i,
	input 		[23:0]	cacheL1D_add_i,
	input 		[31:0]	cacheL1D_data_i

	// i/o to/from L1
	output 				cacheL2_core_req_o, cacheL2_core_rw_o, 	// to cache
	output 		[23:0]	cacheL2_core_add_o, 
	output 		[31:0]	cacheL2_core_data_o,
	input 				cacheL2_core_done_i, 					// from cache
	input 		[31:0]	cacheL2_core_data_i,				

	// i/o to/from internal memory controller
	output 				cacheL2_uc_en_o, cacheL2_uc_ready_o, cacheL2_uc_write_ready_o, cacheL2_uc_read_ready_o,
	output 		[31:0]	cacheL2_uc_data_o,
	input 				cacheL2_hit_i, cacheL2_req_i, cacheL2_reqBlock_i, cacheL2_rw_i, cacheL2_read_i, cacheL2_write_i,
	input 		[23:0]	cacheL2_add_i,
	input 		[31:0]	cacheL2_data_i

);

// check for exceptions
// -----------------------------------------------------------------------
assign exceptions_o[0] = (core_add0_i[0] != 1'b0) ? 1'b1 : 1'b0;			// hword alignment 
assign exceptions_o[1] = (core_add0_i[1:0] != 2'b00) ? 1'b1 : 1'b0;		// hword alignment 
assign exceptions_o[2] = (core_add1_i[0] != 1'b0) ? 1'b1 : 1'b0;			// hword alignment 
assign exceptions_o[3] = (core_add1_i[1:0] != 2'b00) ? 1'b1 : 1'b0;		// hword alignment 


// memory controller comm buffer
// -----------------------------------------------------------------------
wire 			req_toMem, reqBlock_toMem, rw_toMem, write_en, read_ack, ready_write, ready_read;		 
wire 	[23:0] 	add_toMem;
wire 	[31:0]	data_fromMem, data_toMem;
//buffer between main memory and l2
txrx_buffer buf0(

	// system i/o
	.clock_bus_i({clock_bus_i[2],clock_bus_i[0]}), .reset_i(reset_i), .exception_bus_o(exceptions_o[7:4]),

	// controller side
	.req_i(req_toMem), .reqBlock_i(reqBlock_toMem), .rw_i(rw_toMem), .add_i(add_toMem),
	.write_en(write_en), .read_ack(read_ack), .data_i(data_toMem), .ready_write_o(ready_write), .ready_read_o(ready_read), .data_o(data_fromMem),

	// sdram side
	.mem_req_o(mem_req_o), .mem_reqBlock_o(mem_reqBlock_o), .mem_clear_o(mem_clear_o), .mem_rw_o(mem_rw_o), .mem_add_o(mem_add_o), 
	.mem_data_o(mem_data_o), .mem_done_i(mem_done_i), .mem_ready_i(mem_ready_i), .mem_valid_i(mem_valid_i), .mem_data_i(mem_data_i)
);
//buffer between l2 and l1
txrx_buffer buf1(

	// system i/o
	.clock_bus_i({clock_bus_i[2],clock_bus_i[0]}), .reset_i(reset_i), .exception_bus_o(exceptions_o[7:4]),

	// controller side
	.req_i(req_toMem), .reqBlock_i(reqBlock_toMem), .rw_i(rw_toMem), .add_i(add_toMem),
	.write_en(write_en), .read_ack(read_ack), .data_i(data_toMem), .ready_write_o(ready_write), .ready_read_o(ready_read), .data_o(data_fromMem),

	// sdram side
	.mem_req_o(mem_req_o), .mem_reqBlock_o(mem_reqBlock_o), .mem_clear_o(mem_clear_o), .mem_rw_o(mem_rw_o), .mem_add_o(mem_add_o), 
	.mem_data_o(mem_data_o), .mem_done_i(mem_done_i), .mem_ready_i(mem_ready_i), .mem_valid_i(mem_valid_i), .mem_data_i(mem_data_i)
);




// cache assignments
// -----------------------------------------------------------------------

// processor ports
// -------------------------
assign cacheL1I_core_req_o = core_req0_i;
assign cacheL1I_core_rw_o = core_rw0_i;
//assign cacheL1I_core_rw_o = 1'b0;
assign cacheL1I_core_add_o = core_add0_i[25:2];		// convert byte address to word address
assign cacheL1I_core_data_o = core_data0_i;
assign core_data0_o = cacheL1I_core_data_i;
assign core_done0_o = cacheL1I_core_done_i & cacheL1D_core_done_i;

assign cacheL1D_core_req_o = core_req1_i;
assign cacheL1D_core_rw_o = core_rw1_i;
assign cacheL1D_core_add_o = core_add1_i[25:2];		// convert byte address to word address
assign cacheL1D_core_data_o = core_data1_i;
assign core_data1_o = cacheL1D_core_data_i;
assign core_done1_o = cacheL1I_core_done_i & cacheL1D_core_done_i;

// memory controller ports
// ----------------------------
reg 	mem_access;							// who has access
reg 	enable_cacheL1I, enable_cacheL1D; 		// to stall caches if other is a miss

wire clock_cntrl_i;
assign clock_cntrl_i = ~clock_bus_i[1];

always @(posedge clock_cntrl_i) begin
	if (!reset_i) begin
		mem_access = `MEM_ACCESS_cacheL1I; 	// by default inst cache has access but not enabled until out of reset
		enable_cacheL1I = 1'b1; 				// instruction cache needs to be enabled at reset so it can catch the requested values
											// after this initial catch service priority can be whatever
		enable_cacheL1D = 1'b1;
	end
	else begin
		// arbitrate access based on cache activity
		if (!cacheL1I_core_done_i & !cacheL1D_core_done_i) begin
			mem_access = `MEM_ACCESS_cacheL1I; 	// by default inst cache has access but not enabled until out of reset
			//enable_cacheL1I = 1'b1;
			//enable_cacheL1D = 1'b0;
		end
		else if (!cacheL1I_core_done_i & cacheL1D_core_done_i) begin
			mem_access = `MEM_ACCESS_cacheL1I; 	// by default inst cache has access but not enabled until out of reset
			//enable_cacheL1I = 1'b1;
			//enable_cacheL1D = 1'b0;
		end
		else if (cacheL1I_core_done_i & !cacheL1D_core_done_i) begin
			mem_access = `MEM_ACCESS_cacheL1D; 	// by default inst cache has access but not enabled until out of reset
			//enable_cacheL1I = 1'b0;
			//enable_cacheL1D = 1'b1;
		end
		else begin
			mem_access = `MEM_ACCESS_cacheL1D; 	// by default inst cache has access but not enabled until out of reset
			//enable_cacheL1I = 1'b1;
			//enable_cacheL1D = 1'b1;
		end
	end
end


// memory controller ports (to cache)
assign cacheL1I_uc_en_o 			= enable_cacheL1I;
assign cacheL1I_uc_ready_o 		= (mem_access == `MEM_ACCESS_cacheL1I) ? mem_ready_i 	: 1'b0;
assign cacheL1I_uc_write_ready_o 	= (mem_access == `MEM_ACCESS_cacheL1I) ? ready_write 	: 1'b0;
assign cacheL1I_uc_read_ready_o 	= (mem_access == `MEM_ACCESS_cacheL1I) ? ready_read 	: 1'b0;
assign cacheL1I_uc_data_o 		= (mem_access == `MEM_ACCESS_cacheL1I) ? data_fromMem : 'b0;

assign cacheL1D_uc_en_o 			= enable_cacheL1D;
assign cacheL1D_uc_ready_o 		= (mem_access == `MEM_ACCESS_cacheL1D) ? mem_ready_i 	: 1'b0;
assign cacheL1D_uc_write_ready_o 	= (mem_access == `MEM_ACCESS_cacheL1D) ? ready_write 	: 1'b0;
assign cacheL1D_uc_read_ready_o 	= (mem_access == `MEM_ACCESS_cacheL1D) ? ready_read 	: 1'b0;
assign cacheL1D_uc_data_o 		= (mem_access == `MEM_ACCESS_cacheL1D) ? data_fromMem : 'b0;

// memory controller ports (cache -> buffer)
assign req_toMem 				= (mem_access == `MEM_ACCESS_cacheL1I) ? cacheL1I_req_i 		: cacheL1D_req_i;
assign reqBlock_toMem 			= (mem_access == `MEM_ACCESS_cacheL1I) ? cacheL1I_reqBlock_i 	: cacheL1D_reqBlock_i;
assign rw_toMem 				= (mem_access == `MEM_ACCESS_cacheL1I) ? cacheL1I_rw_i 			: cacheL1D_rw_i;
assign write_en 				= (mem_access == `MEM_ACCESS_cacheL1I) ? cacheL1I_write_i 		: cacheL1D_write_i;
assign read_ack 				= (mem_access == `MEM_ACCESS_cacheL1I) ? cacheL1I_read_i 		: cacheL1D_read_i;
assign add_toMem 				= (mem_access == `MEM_ACCESS_cacheL1I) ? cacheL1I_add_i 		: cacheL1D_add_i;
assign data_toMem 				= (mem_access == `MEM_ACCESS_cacheL1I) ? cacheL1I_data_i 		: cacheL1D_data_i;


endmodule