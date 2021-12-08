module cache_n_set_L2_all #(
	parameter POLICY 	= "",
	parameter STRUCTURE = "",
	parameter INIT_DONE = 1'b1, 				// when coming out of reset will not stall core if logic high, 
												// if logic low will stall until out-of-reset operations are complete
	parameter CACHE_BLOCK_CAPACITY = 0,
	parameter CACHE_SET_SIZE=0
)(

	// system
	input 	[1:0]					clock_bus_i, 		// clock[0] = 180deg (controller clock)
														// clock[1] = 270deg (write clock)
	input 							resetn_i, 			
	input 	[31:0]					comm_i, 			// generic comm port in
	input   [1:0]                   metric_sel_i,
	input    [18:0]        rate_shift_seed_i,
	input[31:0] phase_i,
	
	output 	[31:0]					comm_o,				// specific comm port out

	// L1
	input 							L1_req_i,  		// 1: valid request 
	input 	[`BW_WORD_ADDR-1:0] 	core_ref_add_i, 	// address of the requesting instruction (only used in lease data caches)
	input 							L1_rw_i, 			// 1: write, 0: read
	input 	[`BW_WORD_ADDR-1:0] 	L1_add_i, 		// address of mem. request from core
	input 	[31:0]					L1_data_i,
	input 							L2_ready_read_i,
	input                           L2_ready_write_i,
	output                          L1_valid_o,
	output 							L1_done_o, 		// driven high when a cache operation is serviced
	output 	[31:0]					L1_data_o,
	output  L2_read_ack_o,
	

	//tracker and sampler
	output                          stall_o, 
	// internal memory controller
	input 							en_i,  				// logic high if mem. controller enables cache
	input 							ready_req_i,  		// buffer signal (1: can accept a request)
	input 							ready_write_i,  	// buffer signal (1: can be written to)
	input 							ready_read_i, 		// buffer signal (1: can be read from)
	input 	[31:0]					data_i,  			// data being read in from buffer (interfaced to external system)
	input    [31:0]            PC_i,
	output 							hit_o, 
	output 							req_o, 
	output 							req_block_o, 
	output 							rw_o, 
	`ifdef L2_POLICY_DLEASE
		output swap_flag_o,
	`endif
	output 							write_o,  			// drive high when writing to buffer
	output 							read_o, 			// drive high when reading from buffer
	output 	[`BW_WORD_ADDR-1:0]		add_o, 				// address of mem. request from cache
	output 	[31:0]					data_o  			// data being written to buffer (interfaced to external system)



);

// parameterizations
// -----------------------------------------------------------------------------------------------
localparam BW_CACHE_ADDR_PART 	= `CLOG2(CACHE_BLOCK_CAPACITY);  		// [grp]
localparam BW_CACHE_ADDR_FULL 	= BW_CACHE_ADDR_PART + `BW_BLOCK;		// [grp|word]			 
localparam BW_GRP               = `CLOG2(CACHE_SET_SIZE);
localparam BW_SET               =  BW_CACHE_ADDR_PART-BW_GRP;  
localparam BW_TAG 				= `BW_WORD_ADDR - `BW_BLOCK-BW_SET;


//delay req_i and rw_i from L1 one clock cycle so that tag lookup can have an entire clock cycle to complete
reg L1_rw_reg, L1_req_reg;
reg [31:0] phase_reg;
always@(posedge clock_bus_i[0])begin
	if(!resetn_i)begin
		L1_req_reg<=1'b0;
		L1_rw_reg<=1'b0;
		phase_reg<='b0;
	end
	else begin
		if(cache_contr_enable)begin
			L1_req_reg<=L1_req_i;
			L1_rw_reg<=L1_rw_i;
			phase_reg<=phase_i;
		end
		else begin
			L1_req_reg<=L1_req_reg;
			L1_rw_reg<=L1_rw_reg;
			phase_reg<=phase_reg;
		end
	end
end






// internal memories and signals
// -----------------------------------------------------------------------------------------------
wire 	[BW_TAG-1:0] 		req_tag;
wire 	[`BW_BLOCK-1:0]		req_word;

assign req_tag 		= L1_add_i[`BW_WORD_ADDR-1:`BW_BLOCK+BW_SET];	 // extract tag from L1 request
assign req_word 	= L1_add_i[`BW_BLOCK-1:0];				// extract word address from L1 request
generate if(CACHE_SET_SIZE!=CACHE_BLOCK_CAPACITY) begin
	wire [BW_SET-1:0] req_set;
	assign req_set    = L1_add_i[`BW_BLOCK+BW_SET-1:`BW_BLOCK];
end
else begin
wire req_set;
	assign req_set =1'b0;
end
endgenerate


// tag lookup and operations
// -----------------------------------------------------------------------------------------------
wire 								rw_cam;
wire 	[BW_CACHE_ADDR_PART-1:0] 	add_cache2cam; 			// address to be written to/looked up
wire 	[BW_CACHE_ADDR_PART-1:0] 	add_cam2cache; 			// given a tag, returns the address of that tag in cache
wire 	[BW_TAG-1:0] 				tag_cam2cache;			// given an address, returns the tag stored at that location
wire 								hit_cam; 				// 1: cache lookup hit

tag_memory_n_set_L2 #(
	.CACHE_BLOCK_CAPACITY 	(CACHE_BLOCK_CAPACITY),
	.CACHE_SET_SIZE         (CACHE_SET_SIZE)
) cache_tag_lookup_inst (
	.clock_bus_i 		(clock_bus_i 	), 					// write edge
	.resetn_i 		(resetn_i 			), 					// reset active low 		
	.wren_i 		(rw_cam 	 		), 					// write enable (write new entry)
	.tag_i 			(req_tag 			), 					// primary input (tag -> cache location)
	.set_i          (req_set),
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

L2_cache cache_mem(
	.address 		(add_cache 			),
	.clock 			(clock_bus_i[1] 	), 
	.data 			(data_toCache 		),
	.wren 			(rw_cache 			), 
	.q 				(data_fromCache 	)
);


// if controller sets the swap flag (item is in cache) - then route directly from cache memory
// otherwise use the value provided by the cache controller (for lease cache arch the item is not cacheable -
// i.e. zero lease
// if no_swap == 1 (do not allocate in cache) transaction is handled by controller (single word operation)
// if no_swap == 0 then transaction is handled passively by logic (block operation)

generate if (POLICY==`ID_CACHE_DLEASE )begin
		wire 	[31:0]						L1_no_swap_data_bus; 	// data from the controller
		wire 								swap_flag; 				// when 1: route data from controller, not cache
		assign L1_data_o = (!swap_flag) ? L1_no_swap_data_bus : data_fromCache;
		assign swap_flag_o=swap_flag;
end
else begin
		assign L1_data_o = data_fromCache;
end
endgenerate





// performance controller
// -----------------------------------------------------------------------------------------------
wire 	hit_flag,  											// performance metric flags set by controller
		miss_flag, 
		wb_flag,
		expired_flag,
		defaulted_flag,
		expired_multi_flag,
		rand_evict_flag;
`ifdef TRACKER
		wire [CACHE_BLOCK_CAPACITY-1:0] flag_expired_0_bus,
								flag_expired_1_bus,
								flag_expired_2_bus;
`endif

wire 							cpc_stall_flag;
		
`ifdef SAMPLER
wire    [BW_TAG+BW_SET-1:0]req_tag_sampler;
assign req_tag_sampler =L1_add_i[`BW_WORD_ADDR-1:`BW_BLOCK];
`endif

	cache_performance_controller_all_L2 #(
		.CACHE_STRUCTURE	(STRUCTURE 			), 
		.CACHE_REPLACEMENT 	(POLICY				),
		.CACHE_BLOCK_CAPACITY 	(CACHE_BLOCK_CAPACITY 	)
	) perf_cont_inst(
		.clock_i 			(clock_bus_i),
		.resetn_i 			(resetn_i 			),
		.select_data_record (metric_sel_i),
		.rate_shift_seed_i       (rate_shift_seed_i),
		.req_i          (L1_req_reg         ),
		`ifdef SAMPLER
		.pc_ref_i           (PC_i),
		.phase_i             (phase_i),
		.tag_ref_i			(req_tag_sampler    ), 				// regardless of set, sample fully associative tags
		`endif
		.hit_i 				(hit_flag 			), 				// logic high when there is an intial cache hit
		.miss_i 			(miss_flag 	 		), 				// logic high when there is the initial cache miss
		.writeback_i 		(wb_flag 	 		), 				// logic high when the L2 cache writes a block back to external memory
		.expired_i			(expired_flag 		), 				// logic high when lease cache replaces an expired block
		.expired_multi_i 	(expired_multi_flag ), 				// logic high when there are multiple expired cache lines when lease cache replaces a block
		.rand_evict_i       (rand_evict_flag),					// logic high when there are no expired cache lines when lease cache replaces a block
		.defaulted_i 		(defaulted_flag 	), 				// logic high when lease cache renews using a default lease value
		
		.comm_i 			(comm_i 			), 				// configuration signal
		.comm_o 			(comm_o 			), 				// return value of comm_i
		`ifdef L2_POLICY_DLEASE	
			.swap_i(swap_flag),		
		`endif 
		`ifdef TRACKER
		.expired_flags_0_i 	(flag_expired_0_bus ),
		.expired_flags_1_i 	(flag_expired_1_bus ),
		.expired_flags_2_i 	(flag_expired_2_bus ),
		`endif
		.stall_o 			(cpc_stall_flag	)
	);

wire L1_done_bus, cache_contr_enable;

assign cache_contr_enable = !cpc_stall_flag;

assign L1_done_o = L1_done_bus & cache_contr_enable;
assign stall_o   =cache_contr_enable; //core can unstall if L1 is done, even if L2 is not since any subsequent miss won't be serviced until L2 finishes
											//so use CPC_stall_falg instead of L2 done flag to stall core

// cache controller
// -----------------------------------------------------------------------------------------------


`L2_CACHE_CONTROLLER #(
	.POLICY 				(POLICY 				),
	.INIT_DONE 				(INIT_DONE 				),
	.CACHE_BLOCK_CAPACITY 	(CACHE_BLOCK_CAPACITY 	),
	.CACHE_SET_SIZE         (CACHE_SET_SIZE)
) cache_contr_inst(

	// system
	.clock_i 				(clock_bus_i[0] 		), 		// 180 deg phase
	`ifdef L2_POLICY_DLEASE
		.phase_i             (phase_reg),
		.clock_lease_i      (clock_bus_i[1]), 		// 270 deg phase
	`endif
	.resetn_i 				(resetn_i 				),
	.enable_i 				(cache_contr_enable 					),

	// L1/L2 signals
	.L1_req_i 			(L1_req_reg 			),
	.L1_ref_addr_i 		(core_ref_add_i 		),
	.L1_rw_i 				(L1_rw_reg 				),
	.L1_tag_i 			(req_tag 				),
	.L1_set_i           (req_set),
	.L1_word_i 			(req_word 				),
	.L1_data_i 			(L1_data_i 			),
	.L1_done_o 			(L1_done_bus 			),
	.L1_hit_o 			(hit_o 					),
	.L1_valid_o         (L1_valid_o),
	.L2_ready_read_i (L2_ready_read_i),
	.L2_ready_write_i(L2_ready_write_i),
	.L2_read_ack_o(L2_read_ack_o),
	`ifdef L2_POLICY_DLEASE
		.L1_data_o 		(L1_no_swap_data_bus 	), 
	`endif



	// tag memory signals
	.cam_hit_i 				(hit_cam 				),
	.cam_wren_o 			(rw_cam 				),
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



	// performance ports
	.flag_hit_o 			(hit_flag 				),
	.flag_miss_o 			(miss_flag 				),
	.flag_writeback_o 		(wb_flag 				),


	`ifdef L2_POLICY_DLEASE	
	//more performance ports
		.flag_rand_evict_o      (rand_evict_flag),
		.flag_expired_o 		(expired_flag 			),
		.flag_expired_multi_o	(expired_multi_flag 	),
		.flag_defaulted_o 		(defaulted_flag 		),
		.flag_swap_o 			(swap_flag 		 		),
	//line tracking ports
	`endif
	`ifdef TRACKER
		.flag_expired_0_o 		(flag_expired_0_bus 	),
		.flag_expired_1_o 		(flag_expired_1_bus 	),
		.flag_expired_2_o 		(flag_expired_2_bus 	),

	`endif

	// command ports
	.mem_ready_i 			(ready_req_i 			),
	.mem_req_o 				(req_o 					),
	.mem_req_block_o 		(req_block_o 			),
	.mem_rw_o 				(rw_o 					),
	.mem_addr_o 			(add_o 					)


);



endmodule