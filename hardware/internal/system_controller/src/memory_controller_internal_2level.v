`define 	MEM_ACCESS_cacheL1I 	1'b0
`define 	MEM_ACCESS_cacheL1D 	1'b1

module memory_controller_internal_2level(

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

	// L1 cache
	//instruction cache
	// i/o to/from processor
	output 				cacheL1I_core_req_o, cacheL1I_core_rw_o, 	// to cache
	output 		[23:0]	cacheL1I_core_add_o, 
	output 		[31:0]	cacheL1I_core_data_o,
	input 				cacheL1I_core_done_i, 					// from cache
	input 		[31:0]	cacheL1I_core_data_i,				

// i/o to/from internal memory controller
	output 				cacheL1I_uc_ready_o, cacheL1I_uc_write_ready_o, cacheL1I_uc_read_ready_o,
	output 		[31:0]	cacheL1I_uc_data_o,
	input 				cacheL1I_hit_i, cacheL1I_req_i, cacheL1I_reqBlock_i, cacheL1I_rw_i, cacheL1I_read_i, cacheL1I_write_i,
	input 		[23:0]	cacheL1I_add_i,
	input 		[31:0]	cacheL1I_data_i,
	// data cache
	// i/o to/from processor
	output 				cacheL1D_core_req_o, cacheL1D_core_rw_o, 	// to cache
	output 		[23:0]	cacheL1D_core_add_o, 
	output 		[31:0]	cacheL1D_core_data_o,
	input 				cacheL1D_core_done_i, 					// from cache
	input 		[31:0]	cacheL1D_core_data_i,				

	// i/o to/from internal memory controller
	output 				cacheL1D_uc_ready_o, cacheL1D_uc_write_ready_o, cacheL1D_uc_read_ready_o,
	output 		[31:0]	cacheL1D_uc_data_o,
	input 				cacheL1D_hit_i, cacheL1D_req_i, cacheL1D_reqBlock_i, cacheL1D_rw_i, cacheL1D_read_i, cacheL1D_write_i,
	input 		[23:0]	cacheL1D_add_i,
	input 		[31:0]	cacheL1D_data_i,
	//L2 cache
	// i/o to/from L1
	output 				cacheL2_L1_req_o, cacheL2_L1_rw_o, 
	output 		[23:0]	cacheL2_L1_add_o, 
	output 		[31:0]	cacheL2_L1_data_o,
	input 		[31:0]	cacheL2_L1_data_i,
	input 				cacheL2_L1_ready_i,cacheL2_L1_valid_i,

	
	// i/o to/from internal memory controller
	output 				cacheL2_uc_ready_o, cacheL2_uc_write_ready_o, cacheL2_uc_read_ready_o,
	output 		[31:0]	cacheL2_uc_data_o,
	input 				cacheL2_hit_i, cacheL2_req_i, cacheL2_reqBlock_i, cacheL2_rw_i, cacheL2_read_i, cacheL2_write_i,
	input 		[23:0]	cacheL2_add_i,
	input 		[31:0]	cacheL2_data_i,
	input   L2_read_ack_i,
	output  L2_ready_read_o,
	output  L2_ready_write_o

);

// check for exceptions
// -----------------------------------------------------------------------
assign exceptions_o[0] = (core_add0_i[0] != 1'b0) ? 1'b1 : 1'b0;			// hword alignment 
assign exceptions_o[1] = (core_add0_i[1:0] != 2'b00) ? 1'b1 : 1'b0;		// hword alignment 
assign exceptions_o[2] = (core_add1_i[0] != 1'b0) ? 1'b1 : 1'b0;			// hword alignment 
assign exceptions_o[3] = (core_add1_i[1:0] != 2'b00) ? 1'b1 : 1'b0;		// hword alignment 


// memory controller comm buffer
// -----------------------------------------------------------------------
wire 			req_toMem, reqBlock_toMem, rw_toMem, write_en_L1, read_ack_L1, ready_write, ready_read,L1_ready_read, L1_ready_write;
wire 			req_toL2,  rw_toL2, write_en_Mem, read_ack_Mem, Mem_ready_write, Mem_ready_read;		 
wire 	[23:0] 	add_toL2, add_toMem;
wire 	[31:0]	data_fromMem, data_toMem, data_fromL2, data_toL2;
//buffer between main memory and l2
txrx_buffer buf0(

	// system i/o
	.clock_bus_i({clock_bus_i[2],clock_bus_i[0]}), .reset_i(reset_i), .exception_bus_o(exceptions_o[7:4]),

	// L2 controller side
	.req_i(req_toMem), .reqBlock_i(reqBlock_toMem), .rw_i(rw_toMem), .add_i(add_toMem),
	.write_en(write_en_Mem), .read_ack(read_ack_Mem), .data_i(data_toMem), .ready_write_o(ready_write), .ready_read_o(ready_read), .data_o(data_fromMem),

	//SRAM
	.mem_req_o(mem_req_o), .mem_reqBlock_o(mem_reqBlock_o), .mem_clear_o(mem_clear_o), .mem_rw_o(mem_rw_o), .mem_add_o(mem_add_o), 
	.mem_data_o(mem_data_o), .mem_done_i(mem_done_i), .mem_ready_i(mem_ready_i), .mem_valid_i(mem_valid_i), .mem_data_i(mem_data_i)
);
//buffer between l2 and l1
txrx_buffer_L2_L1 buf1(

	// system i/o
	.clock_bus_i({clock_bus_i[2],clock_bus_i[0]}), .reset_i(reset_i), .exception_bus_o(exceptions_o[7:4]),

	// L1 controller side
	.req_i(req_toL2),  .rw_i(rw_toL2), .add_i(add_toL2),
	.write_en(write_en_L1), .read_ack(read_ack_L1), .data_i(data_toL2), .ready_write_o(L1_ready_write), .ready_read_o(L1_ready_read), .data_o(data_fromL2),

	// L2 controller side
	.cacheL2_L1_req_o(cacheL2_L1_req_o),  .cacheL2_L1_rw_o(cacheL2_L1_rw_o), .cacheL2_L1_add_o(cacheL2_L1_add_o), 
	.cacheL2_L1_data_o(cacheL2_L1_data_o), .cacheL2_L1_ready_i(cacheL2_L1_ready_i), .cacheL2_L1_data_i(cacheL2_L1_data_i), .cacheL2_L1_valid_i(cacheL2_L1_valid_i),
	.L2_read_ack_i(L2_read_ack_i), .L2_ready_read_o(L2_ready_read_o), .L2_ready_write_o(L2_ready_write_o)
);




// cache assignments
// -----------------------------------------------------------------------

// processor ports
// -------------------------
assign cacheL1I_core_req_o = core_req0_i;
assign cacheL1I_core_rw_o = core_rw0_i;
assign cacheL1I_core_add_o = core_add0_i[25:2];		// convert byte address to word address
assign cacheL1I_core_data_o = core_data0_i;
assign core_data0_o = cacheL1I_core_data_i;
assign core_done0_o = cacheL1I_core_done_i ;

assign cacheL1D_core_req_o = core_req1_i;
assign cacheL1D_core_rw_o = core_rw1_i;
assign cacheL1D_core_add_o = core_add1_i[25:2];		// convert byte address to word address
assign cacheL1D_core_data_o = core_data1_i;
assign core_data1_o = cacheL1D_core_data_i;
assign core_done1_o = cacheL1D_core_done_i ;

// memory controller ports
// ----------------------------
reg 	mem_access;							// who has access

wire clock_cntrl_i;
assign clock_cntrl_i = ~clock_bus_i[1];

always @(posedge clock_cntrl_i) begin
	if (!reset_i) begin
		mem_access = `MEM_ACCESS_cacheL1I; 	// by default inst cache has access but not enabled until out of reset
	end
	else begin
		//instruction cache has access by default. 
		//if instruction cache has no operation in progress and data cache is a miss then data cache gains access.
		//if data cache operation has started, then data cache retains control
		if (cacheL1I_core_done_i & !cacheL1D_core_done_i) begin
			mem_access = `MEM_ACCESS_cacheL1D; 	// by default inst cache has access 
		end
		else if (!cacheL1I_core_done_i & mem_access ==`MEM_ACCESS_cacheL1D & !cacheL1D_core_done_i)begin
			mem_access = `MEM_ACCESS_cacheL1D; 	// by default inst cache has access 
		end
		else begin
			mem_access = `MEM_ACCESS_cacheL1I; 	// by default inst cache has access 
		end
	end
end


// memory controller ports (to cache L1)
assign cacheL1I_uc_ready_o 		= (mem_access == `MEM_ACCESS_cacheL1I) ? cacheL2_L1_ready_i	: 1'b0;
assign cacheL1I_uc_write_ready_o 	= (mem_access == `MEM_ACCESS_cacheL1I) ? L1_ready_write 	: 1'b0;
assign cacheL1I_uc_read_ready_o 	= (mem_access == `MEM_ACCESS_cacheL1I) ? L1_ready_read 	: 1'b0;
assign cacheL1I_uc_data_o 		= (mem_access == `MEM_ACCESS_cacheL1I) ? data_fromL2 : 'b0;

assign cacheL1D_uc_ready_o 		= (mem_access == `MEM_ACCESS_cacheL1D) ? cacheL2_L1_ready_i 	: 1'b0;
assign cacheL1D_uc_write_ready_o 	= (mem_access == `MEM_ACCESS_cacheL1D) ? L1_ready_write 	: 1'b0;
assign cacheL1D_uc_read_ready_o 	= (mem_access == `MEM_ACCESS_cacheL1D) ? L1_ready_read 	: 1'b0;
assign cacheL1D_uc_data_o 		= (mem_access == `MEM_ACCESS_cacheL1D) ? data_fromL2 : 'b0;

// memory controller ports (to cache l2)
assign cacheL2_uc_ready_o 		= mem_ready_i;
assign cacheL2_uc_write_ready_o 	= ready_write;
assign cacheL2_uc_read_ready_o 	= ready_read;
assign cacheL2_uc_data_o 		= data_fromMem;

// memory controller ports (cacheL1 -> buffer)
assign req_toL2 				= (mem_access == `MEM_ACCESS_cacheL1I) ? cacheL1I_req_i 		: cacheL1D_req_i;
assign rw_toL2 				= (mem_access == `MEM_ACCESS_cacheL1I) ? cacheL1I_rw_i 			: cacheL1D_rw_i;
assign write_en_L1 				= (mem_access == `MEM_ACCESS_cacheL1I) ? cacheL1I_write_i 		: cacheL1D_write_i;
assign read_ack_L1 				= (mem_access == `MEM_ACCESS_cacheL1I) ? cacheL1I_read_i 		: cacheL1D_read_i;
assign data_toL2 				= (mem_access == `MEM_ACCESS_cacheL1I) ? cacheL1I_data_i 		: cacheL1D_data_i;
assign add_toL2 				= (mem_access == `MEM_ACCESS_cacheL1I) ? cacheL1I_add_i 		: cacheL1D_add_i;


// memory controller ports (cacheL2 -> buffer)
assign req_toMem 				= cacheL2_req_i;
assign reqBlock_toMem 			= cacheL2_reqBlock_i ;
assign rw_toMem 				= cacheL2_rw_i;
assign write_en_Mem 				= cacheL2_write_i;
assign read_ack_Mem 				= cacheL2_read_i;
assign data_toMem 				= cacheL2_data_i;
assign add_toMem 				= cacheL2_add_i;

endmodule