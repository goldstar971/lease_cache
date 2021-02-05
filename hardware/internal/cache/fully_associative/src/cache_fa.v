module cache_fa #(
	parameter POLICY 	= "",
	parameter STRUCTURE = "",
	parameter INIT_DONE = 1'b1, 				// when coming out of reset will not stall core if logic high, 
												// if logic low will stall until out-of-reset operations are complete
	parameter CACHE_BLOCK_CAPACITY = 0

)(

	// system
	input 	[1:0]					clock_bus_i, 		// clock[0] = 180deg (controller clock)
														// clock[1] = 270deg (write clock)
	input 							resetn_i, 			
	input 	[31:0]					comm_i, 			// generic comm port in
	output 	[31:0]					comm_o,				// specific comm port out

	// core/hart
	input 							core_req_i,  		// 1: valid request 
	input 	[`BW_WORD_ADDR-1:0] 	core_ref_add_i, 	// address of the requesting instruction (only used in lease data caches)
	input 							core_rw_i, 			// 1: write, 0: read
	input 	[`BW_WORD_ADDR-1:0] 	core_add_i, 		// address of mem. request from core
	input 	[31:0]					core_data_i,
	output 							core_done_o, 		// driven high when a cache operation is serviced
	output 	[31:0]					core_data_o,

	// internal memory controller
	input 							en_i,  				// logic high if mem. controller enables cache
	input 							ready_req_i,  		// buffer signal (1: can accept a request)
	input 							ready_write_i,  	// buffer signal (1: can be written to)
	input 							ready_read_i, 		// buffer signal (1: can be read from)
	input 	[31:0]					data_i,  			// data being read in from buffer (interfaced to external system)
	output 							hit_o, 
	output 							req_o, 
	output 							req_block_o, 
	output 							rw_o, 
	output 							write_o,  			// drive high when writing to buffer
	output 							read_o, 			// drive high when reading from buffer
	output 	[`BW_WORD_ADDR-1:0]		add_o, 				// address of mem. request from cache
	output 	[31:0]					data_o  			// data being written to buffer (interfaced to external system)

);

// parameterizations
// -----------------------------------------------------------------------------------------------
localparam BW_CACHE_ADDR_PART 	= `CLOG2(CACHE_BLOCK_CAPACITY);  		// [grp]
localparam BW_CACHE_ADDR_FULL 	= BW_CACHE_ADDR_PART + `BW_BLOCK;		// [grp|word]			 
localparam BW_TAG 				= `BW_WORD_ADDR - `BW_BLOCK;  


// internal memories and signals
// -----------------------------------------------------------------------------------------------
wire 	[BW_TAG-1:0] 		req_tag;
wire 	[`BW_BLOCK-1:0]		req_word;

assign req_tag 		= core_add_i[`BW_WORD_ADDR-1:`BW_BLOCK];	 // extract tag from core request
assign req_word 	= core_add_i[`BW_BLOCK-1:0];				// extract word address from core request


// tag lookup and operations
// -----------------------------------------------------------------------------------------------
wire 								rw_cam;
wire 	[BW_CACHE_ADDR_PART-1:0] 	add_cache2cam; 			// address to be written to/looked up
wire 	[BW_CACHE_ADDR_PART-1:0] 	add_cam2cache; 			// given a tag, returns the address of that tag in cache
wire 	[BW_TAG-1:0] 				tag_cam2cache;			// given an address, returns the tag stored at that location
wire 								hit_cam; 				// 1: cache lookup hit

tag_memory_fa #(
	.CACHE_BLOCK_CAPACITY 	(CACHE_BLOCK_CAPACITY)
) cache_tag_lookup_inst (
	.clock_i 		(clock_bus_i[1] 	), 					// write edge
	.resetn_i 		(resetn_i 			), 					// reset active low 		
	.wren_i 		(rw_cam 	 		), 					// write enable (write new entry)
	.rmen_i 		(1'b0 				), 					// remove enable (invalidate entry) 	
	.tag_i 			(req_tag 			), 					// primary input (tag -> cache location)
	.add_i 			(add_cache2cam 	 	), 					// add -> tag (part of absolute memory address) - used for replacement
	.add_o 			(add_cam2cache 		), 					// primary output (cache location <- tag)
	.tag_o 			(tag_cam2cache 		),					// tag <- add
	.hit_o 			(hit_cam 			) 					// logic high if lookup hit
);


// cache memory
// -----------------------------------------------------------------------------------------------
wire 								rw_cache; 
wire 	[BW_CACHE_ADDR_FULL-1:0]	add_cache;				// [tag|word]
wire 	[31:0]						data_toCache; 			// hit - from core, miss - from buffer
wire 	[31:0]	 					data_fromCache;

bram_32b_8kB cache_mem(
	.address 		(add_cache 			),
	.clock 			(clock_bus_i[1] 	), 
	.data 			(data_toCache 		),
	.wren 			(rw_cache 			), 
	.q 				(data_fromCache 	)
);

//assign core_data_o = data_fromCache;
// if no_swap == 1 (do not allocate in cache) transaction is handled by controller (single word operation)
// if no_swap == 0 then transaction is handled passively by logic (block operation)
assign core_data_o = data_fromCache;

/*generate
	if (POLICY == `ID_CACHE_LEASE_DUAL) begin
		wire [31:0]	core_no_swap_data_bus;
		wire 		no_swap_flag;
		assign core_data_o = (no_swap_flag == 1'b1) ? core_no_swap_data_bus : data_fromCache;
	end
	else begin
		assign core_data_o = data_fromCache;
	end
endgenerate*/



// performance controller
// -----------------------------------------------------------------------------------------------
wire 	hit_flag,  											// performance metric flags set by controller
		miss_flag, 
		wb_flag,
		expired_flag,
		defaulted_flag,
		expired_multi_flag;
		
generate
	if ((POLICY != `ID_CACHE_LEASE) & (POLICY != `ID_CACHE_LEASE_DUAL)) begin
		assign expired_flag = 1'b0;
		assign defaulted_flag = 1'b0;
		assign expired_multi_flag = 1'b0;
	end
endgenerate

`ifndef SAMPLER
	cache_performance_controller #(
		.CACHE_STRUCTURE	(STRUCTURE 			), 
		.CACHE_REPLACEMENT 	(POLICY				) 
	) perf_cont_inst(
		.clock_i 			(clock_bus_i[0] 	),
		.resetn_i 			(resetn_i 			),
		.hit_i 				(hit_flag 			), 				// logic high when there is a cache hit
		.miss_i 			(miss_flag 	 		), 				// logic high when there is the initial cache miss
		.writeback_i 		(wb_flag 	 		), 				// logic high when the cache writes a block back to externa memory
		.expired_i			(expired_flag 		), 				// logic high when lease cache replaces an expired block
		.expired_multi_i 	(expired_multi_flag ), 
		.defaulted_i 		(defaulted_flag 	), 				// logic high when lease cache renews using a default lease value
		.comm_i 			(comm_i 			), 				// configuration signal
		.comm_o 			(comm_o 			) 				// return value of comm_i
	);
`else
	cache_performance_controller_sampler #(
		.CACHE_STRUCTURE	(STRUCTURE 			), 
		.CACHE_REPLACEMENT 	(POLICY				) 
	) perf_cont_inst(
		.clock_bus 			(clock_bus_i 	 	), 				// clock[0] = 180deg, clock[1] = 270deg
		.resetn_i 			(resetn_i 			),
		.hit_i 				(hit_flag 			), 				// logic high when there is a cache hit
		.miss_i 			(miss_flag 	 		), 				// logic high when there is the initial cache miss
		.writeback_i 		(wb_flag 	 		), 				// logic high when the cache writes a block back to externa memory
		
		

		
		.comm_i 			(comm_i 			), 				// configuration signal
		.comm_o 			(comm_o 			) 				// return value of comm_i
	);
`endif


// cache controller
// -----------------------------------------------------------------------------------------------

generate 
	if (	(POLICY == `ID_CACHE_RANDOM 	) | 
			(POLICY == `ID_CACHE_FIFO		) |
			(POLICY == `ID_CACHE_LRU 		) |
			(POLICY == `ID_CACHE_MRU 		) |
			(POLICY == `ID_CACHE_PLRU 		) |
			(POLICY == `ID_CACHE_SRRIP 		) 
	) begin

cache_fa_controller #(
	.POLICY 				(POLICY 				),
	.INIT_DONE 				(INIT_DONE 				),
	.CACHE_BLOCK_CAPACITY 	(CACHE_BLOCK_CAPACITY 	)
) cache_contr_inst(

	// system
	.clock_i 				(clock_bus_i[0] 		), 		// 180 deg phase
	.resetn_i 				(resetn_i 				),
	.enable_i 				(en_i 					),

	// core/hart signals
	.core_req_i 			(core_req_i 			),
	.core_ref_addr_i 		(core_ref_add_i 		),
	.core_rw_i 				(core_rw_i 				),
	.core_tag_i 			(req_tag 				),
	.core_word_i 			(req_word 				),
	.core_data_i 			(core_data_i 			),
	.core_done_o 			(core_done_o 			),
	.core_hit_o 			(hit_o 					),

	// tag memory signals
	.cam_hit_i 				(hit_cam 				),
	.cam_wren_o 			(rw_cam 				),
	.cam_rmen_o 			(),
	.cam_tag_i 				(tag_cam2cache 	 		),
	.cam_addr_i 			(add_cam2cache 			),
	.cam_addr_o 			(add_cache2cam 			),

	// cache memory signals
	.cache_mem_data_i 		(data_fromCache 		),
	.cache_mem_add_o 		(add_cache 				),
	.cache_mem_rw_o 		(rw_cache 				),
	.cache_mem_data_o 		(data_toCache 			),

	// data buffer signals
	.buffer_read_ready_i 	(ready_read_i 			),
	.buffer_data_i 			(data_i 				),
	.buffer_read_ack_o 		(read_o 				),
	.buffer_write_ready_i 	(ready_write_i 			),
	.buffer_data_o 			(data_o 				),
	.buffer_write_ack_o 	(write_o 				),

	// command ports
	.mem_ready_i 			(ready_req_i 			),
	.mem_req_o 				(req_o 					),
	.mem_req_block_o 		(req_block_o 			),
	.mem_rw_o 				(rw_o 					),
	.mem_addr_o 			(add_o 					),

	// performance ports
	.flag_hit_o 			(hit_flag 				),
	.flag_miss_o 			(miss_flag 				),
	.flag_writeback_o 		(wb_flag 				)

);

	end
endgenerate


endmodule