module lease_cache_2way_tracker #(
	parameter POLICY 	= "",
	parameter STRUCTURE = "",
	parameter INIT_DONE = 1'b1, 						// when coming out of reset will not stall core if logic high, 
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
localparam BW_CACHE_ADDR_PART 	= `CLOG2(CACHE_BLOCK_CAPACITY); 		// [set|group]
localparam BW_CACHE_ADDR_FULL 	= BW_CACHE_ADDR_PART + `BW_BLOCK; 		// [set|group|word]
localparam BW_GRP 				= BW_CACHE_ADDR_PART - 1; 				// (sub two for the set)			
localparam BW_TAG 				= `BW_WORD_ADDR - BW_GRP - `BW_BLOCK; 	// [tag|set|group|word]


// internal memories and signals
// -----------------------------------------------------------------------------------------------
wire 	[BW_TAG-1:0] 		req_tag;
wire 	[BW_GRP-1:0]		req_group;
wire 	[`BW_BLOCK-1:0]		req_word;

assign req_tag 		= core_add_i[`BW_WORD_ADDR-1:BW_GRP+`BW_BLOCK]; 	
assign req_group 	= core_add_i[BW_GRP-1+`BW_BLOCK:`BW_BLOCK];
assign req_word 	= core_add_i[`BW_BLOCK-1:0];


// tag lookup and operations
// -----------------------------------------------------------------------------------------------
wire 								rw_cam;			// from controller
wire 	[BW_CACHE_ADDR_PART-1:0] 	add_cache2cam;	// [set|group]
wire 	[BW_CACHE_ADDR_PART-1:0] 	add_cam2cache;	// [set|group]
wire 	[BW_TAG-1:0] 				tag_cam2cache;
wire 								hit_cam;

tag_memory_2way #(
	.CACHE_BLOCK_CAPACITY 	(CACHE_BLOCK_CAPACITY)
) tag_mem_inst (	
	.clock_i 		(clock_bus_i[1] 	), 
	.resetn_i 		(resetn_i 			), 
	.wren_i 		(rw_cam 			),
	.rmen_i 		(1'b0 				),
 	.tag_i 			(req_tag 			), 
 	.group_i 		(req_group 			), 
 	.addr_i 		(add_cache2cam 		),
	.addr_o 		(add_cam2cache 		), 
	.tag_o 			(tag_cam2cache 		),
	.hit_o 			(hit_cam 			)
);


// cache memory
// -----------------------------------------------------------------------------------------------
wire 								rw_cache; 
wire 	[BW_CACHE_ADDR_FULL-1:0]	add_cache;				// [tag|word]
wire 	[31:0]						data_toCache; 			// hit - from core, miss - from buffer
wire 	[31:0]	 					data_fromCache;
wire 	[31:0]						core_no_swap_data_bus; 	// data from the controller
wire 								swap_flag; 				// when 1: route data from controller, not cache

bram_32b_8kB cache_mem(
	.address 		(add_cache 			),
	.clock 			(clock_bus_i[1] 	), 
	.data 			(data_toCache 		),
	.wren 			(rw_cache 			), 
	.q 				(data_fromCache 	)
);

// if controller sets the swap flag (item is in cache) - then route directly from cache memory
// otherwise use the value provided by the cache controller (for lease cache arch the item is not cacheable -
// i.e. zero lease
assign core_data_o = (!swap_flag) ? core_no_swap_data_bus : data_fromCache;


// performance controller
// -----------------------------------------------------------------------------------------------
wire 	hit_flag,  											// performance metric flags set by controller
		miss_flag, 
		wb_flag,
		expired_flag, 										// expired and defaulted only used by lease cache variants
		defaulted_flag;

wire [CACHE_BLOCK_CAPACITY-1:0] flag_expired_0_bus,
								flag_expired_1_bus,
								flag_expired_2_bus;
wire 							tracker_stall_flag;



cache_performance_controller_tracker_2 #(
	.CACHE_STRUCTURE	(STRUCTURE 			), 
	.CACHE_REPLACEMENT 	(POLICY				) 
) perf_cont_inst(
	.clock_i 			(!clock_bus_i[1] 	),
	.clock_memory_i 	(clock_bus_i[0] 	),
	.resetn_i 			(resetn_i 			),
	.request_i 			(core_req_i 		),
	.hit_i 				(hit_flag 			), 				// logic high when there is a cache hit
	.miss_i 			(miss_flag 	 		), 				// logic high when there is the initial cache miss
	.writeback_i 		(wb_flag 	 		), 				// logic high when the cache writes a block back to externa memory
	.expired_i			(expired_flag 		), 				// logic high when lease cache replaces an expired block
	
	.defaulted_i 		(defaulted_flag 	), 				// logic high when lease cache renews using a default lease value
	.comm_i 			(comm_i 			), 				// configuration signal
	.comm_o 			(comm_o 			), 				// return value of comm_i
	//.expired_flags_i 	(expired_flags 		),
	.expired_flags_0_i 	(flag_expired_0_bus ),
	.expired_flags_1_i 	(flag_expired_1_bus ),
	.expired_flags_2_i 	(flag_expired_2_bus ),
	.stall_o 			(tracker_stall_flag	)
);


// cache controller
// -----------------------------------------------------------------------------------------------

lease_cache_2way_controller_tracker #(
	.POLICY 				(POLICY 				), 		// for lease cache generates versions that cache zero lease misses, or not (default is not)
	.INIT_DONE 				(INIT_DONE 				),
	.CACHE_BLOCK_CAPACITY 	(CACHE_BLOCK_CAPACITY 	)
) cache_contr_inst(

	// system
	.clock_i 				(clock_bus_i[0] 		), 		// 180 deg phase
	.clock_lease_i 			(clock_bus_i[1] 		), 		// 270 deg phase
	.resetn_i 				(resetn_i 				),
	.enable_i 				(en_i 					),

	// core/hart signals
	.core_req_i 			(core_req_i 			),
	.core_ref_addr_i 		(core_ref_add_i 		),
	.core_rw_i 				(core_rw_i 				),
	.core_tag_i 			(req_tag 				),
	.core_grp_i 			(req_group 				),
	.core_word_i 			(req_word 				),
	.core_data_i 			(core_data_i 			),
	.core_done_o 			(core_done_o 			),
	.core_hit_o 			(hit_o 					),
	.core_data_o 			(core_no_swap_data_bus 	), 		// when not caching something, the controller will route the data on a load

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
	.flag_writeback_o 		(wb_flag 				),
	.flag_expired_o 		(expired_flag 			),
	.flag_defaulted_o 		(defaulted_flag 		),
	.flag_swap_o 			(swap_flag 		 		),

	.flag_expired_0_o 		(flag_expired_0_bus 	),
	.flag_expired_1_o 		(flag_expired_1_bus 	),
	.flag_expired_2_o 		(flag_expired_2_bus 	)

);

endmodule