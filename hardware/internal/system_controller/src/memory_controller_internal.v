`define 	MEM_ACCESS_CACHE0 	1'b0
`define 	MEM_ACCESS_CACHE1 	1'b1

module memory_controller_internal(

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
	output 				cache0_core_req_o, cache0_core_rw_o, 	// to cache
	output 		[23:0]	cache0_core_add_o, 
	output 		[31:0]	cache0_core_data_o,
	input 				cache0_core_done_i, 					// from cache
	input 		[31:0]	cache0_core_data_i,				

	// i/o to/from internal memory controller
	output 				cache0_uc_en_o, cache0_uc_ready_o, cache0_uc_write_ready_o, cache0_uc_read_ready_o,
	output 		[31:0]	cache0_uc_data_o,
	input 				cache0_hit_i, cache0_req_i, cache0_reqBlock_i, cache0_rw_i, cache0_read_i, cache0_write_i,
	input 		[23:0]	cache0_add_i,
	input 		[31:0]	cache0_data_i,

	// i/o to/from processor
	output 				cache1_core_req_o, cache1_core_rw_o, 	// to cache
	output 		[23:0]	cache1_core_add_o, 
	output 		[31:0]	cache1_core_data_o,
	input 				cache1_core_done_i, 					// from cache
	input 		[31:0]	cache1_core_data_i,				

	// i/o to/from internal memory controller
	output 				cache1_uc_en_o, cache1_uc_ready_o, cache1_uc_write_ready_o, cache1_uc_read_ready_o,
	output 		[31:0]	cache1_uc_data_o,
	input 				cache1_hit_i, cache1_req_i, cache1_reqBlock_i, cache1_rw_i, cache1_read_i, cache1_write_i,
	input 		[23:0]	cache1_add_i,
	input 		[31:0]	cache1_data_i

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


// cache assignments
// -----------------------------------------------------------------------

// processor ports
// -------------------------
assign cache0_core_req_o = core_req0_i;
assign cache0_core_rw_o = core_rw0_i;
//assign cache0_core_rw_o = 1'b0;
assign cache0_core_add_o = core_add0_i[25:2];		// convert byte address to word address
assign cache0_core_data_o = core_data0_i;
assign core_data0_o = cache0_core_data_i;
assign core_done0_o = cache0_core_done_i & cache1_core_done_i;

assign cache1_core_req_o = core_req1_i;
assign cache1_core_rw_o = core_rw1_i;
assign cache1_core_add_o = core_add1_i[25:2];		// convert byte address to word address
assign cache1_core_data_o = core_data1_i;
assign core_data1_o = cache1_core_data_i;
assign core_done1_o = cache0_core_done_i & cache1_core_done_i;

// memory controller ports
// ----------------------------
reg 	mem_access;							// who has access
reg 	enable_cache0, enable_cache1; 		// to stall caches if other is a miss

wire clock_cntrl_i;
assign clock_cntrl_i = ~clock_bus_i[1];

always @(posedge clock_cntrl_i) begin
	if (!reset_i) begin
		mem_access = `MEM_ACCESS_CACHE0; 	// by default inst cache has access but not enabled until out of reset
		enable_cache0 = 1'b1; 				// instruction cache needs to be enabled at reset so it can catch the requested values
											// after this initial catch service priority can be whatever
		enable_cache1 = 1'b1;
	end
	else begin
		// arbitrate access based on cache activity
		if (!cache0_core_done_i & !cache1_core_done_i) begin
			mem_access = `MEM_ACCESS_CACHE0; 	// by default inst cache has access but not enabled until out of reset
			//enable_cache0 = 1'b1;
			//enable_cache1 = 1'b0;
		end
		else if (!cache0_core_done_i & cache1_core_done_i) begin
			mem_access = `MEM_ACCESS_CACHE0; 	// by default inst cache has access but not enabled until out of reset
			//enable_cache0 = 1'b1;
			//enable_cache1 = 1'b0;
		end
		else if (cache0_core_done_i & !cache1_core_done_i) begin
			mem_access = `MEM_ACCESS_CACHE1; 	// by default inst cache has access but not enabled until out of reset
			//enable_cache0 = 1'b0;
			//enable_cache1 = 1'b1;
		end
		else begin
			mem_access = `MEM_ACCESS_CACHE1; 	// by default inst cache has access but not enabled until out of reset
			//enable_cache0 = 1'b1;
			//enable_cache1 = 1'b1;
		end
	end
end

/*reg 	mem_access;						// who has access
reg 	enable_cache0, enable_cache1;	// to stall caches if other is a miss

always @(*) begin
	// memory accesses
	//if 		(!cache0_hit_i & !cache1_hit_i) mem_access = `MEM_ACCESS_CACHE0;
	if 		(!cache0_hit_i & !cache1_hit_i) mem_access = `MEM_ACCESS_CACHE1; 		// priority to lease cache to bring in leases
	else if (!cache0_hit_i & cache1_hit_i) mem_access = `MEM_ACCESS_CACHE0;
	else if (cache0_hit_i & !cache1_hit_i) mem_access = `MEM_ACCESS_CACHE1;
	else mem_access = `MEM_ACCESS_CACHE1; 		

	// enables
	if 		(!cache0_hit_i & !cache1_hit_i) begin
		enable_cache0 = 1'b1; 
		enable_cache1 = 1'b0;
	end
	else if (!cache0_hit_i & cache1_hit_i) begin
		enable_cache0 = 1'b1; 
		enable_cache1 = 1'b0;
	end
	else if (cache0_hit_i & !cache1_hit_i)  begin
		enable_cache0 = 1'b0; 
		enable_cache1 = 1'b1;
	end
	else begin
		enable_cache0 = 1'b1; 
		enable_cache1 = 1'b1;
	end
end*/

// memory controller ports (to cache)
assign cache0_uc_en_o 			= enable_cache0;
assign cache0_uc_ready_o 		= (mem_access == `MEM_ACCESS_CACHE0) ? mem_ready_i 	: 1'b0;
assign cache0_uc_write_ready_o 	= (mem_access == `MEM_ACCESS_CACHE0) ? ready_write 	: 1'b0;
assign cache0_uc_read_ready_o 	= (mem_access == `MEM_ACCESS_CACHE0) ? ready_read 	: 1'b0;
assign cache0_uc_data_o 		= (mem_access == `MEM_ACCESS_CACHE0) ? data_fromMem : 'b0;

assign cache1_uc_en_o 			= enable_cache1;
assign cache1_uc_ready_o 		= (mem_access == `MEM_ACCESS_CACHE1) ? mem_ready_i 	: 1'b0;
assign cache1_uc_write_ready_o 	= (mem_access == `MEM_ACCESS_CACHE1) ? ready_write 	: 1'b0;
assign cache1_uc_read_ready_o 	= (mem_access == `MEM_ACCESS_CACHE1) ? ready_read 	: 1'b0;
assign cache1_uc_data_o 		= (mem_access == `MEM_ACCESS_CACHE1) ? data_fromMem : 'b0;

// memory controller ports (cache -> buffer)
assign req_toMem 				= (mem_access == `MEM_ACCESS_CACHE0) ? cache0_req_i 		: cache1_req_i;
assign reqBlock_toMem 			= (mem_access == `MEM_ACCESS_CACHE0) ? cache0_reqBlock_i 	: cache1_reqBlock_i;
assign rw_toMem 				= (mem_access == `MEM_ACCESS_CACHE0) ? cache0_rw_i 			: cache1_rw_i;
assign write_en 				= (mem_access == `MEM_ACCESS_CACHE0) ? cache0_write_i 		: cache1_write_i;
assign read_ack 				= (mem_access == `MEM_ACCESS_CACHE0) ? cache0_read_i 		: cache1_read_i;
assign add_toMem 				= (mem_access == `MEM_ACCESS_CACHE0) ? cache0_add_i 		: cache1_add_i;
assign data_toMem 				= (mem_access == `MEM_ACCESS_CACHE0) ? cache0_data_i 		: cache1_data_i;


endmodule