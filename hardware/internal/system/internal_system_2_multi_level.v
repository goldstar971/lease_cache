// define cache types in top.h
// -----------------------------------------------------------------------------------------------------

module internal_system_2_multi_level(

	// general ports
	input 	[3:0]	clock_bus_i, // [3,2,1,0] = [20/270,20/180,20/90,20/0]
	input 			reset_i,
	output 	[11:0]	exception_o,
	input 	[31:0]	comm_i, 
	`ifdef DATA_POLICY_DLEASE
		input 	[31:0] 	phase_i,
	`endif
	output 	[31:0]	comm_cacheL1I_o, 
	output 	[31:0]	comm_cacheL1D_o,
	output  [31:0]  comm_cacheL2_o,
	input    [1:0]  cpc_metric_switch_i,
	
	// external system
	output 			mem_req_o, 
	output 			mem_reqBlock_o, 
	output 			mem_clear_o, 
	output 			mem_rw_o,
	output 	[23:0]	mem_add_o, 		// word addressible
	output 	[31:0]	mem_data_o,
	input 	[31:0]	mem_data_i,
	input 			mem_done_i, 
	input 			mem_ready_i, 
	input 			mem_valid_i,

	// peripheral system - reduced bus
	output 			per_req_o, 
	output 			per_rw_o,
	output	[31:0]	per_add_o, 		// byte addressible
	output 	[31:0]	per_data_o, 
	input 	[31:0]	per_data_i		
);


// riscv core
// --------------------------------------------------------------------
wire 		req0_core2mc, rw0_core2mc, done0_mc2core;
wire [31:0]	add0_core2mc, data0_core2mc, data0_mc2core;	
wire 		req1_core2mc, rw1_core2mc, done1_mc2core;
wire [31:0]	add1_core2mc, data1_core2mc, data1_mc2core;
wire [3:0]	core_exceptions;

wire [31:0]  				core_inst_addr; 	// core address assumes 2GB space, byte addressible
wire [`BW_WORD_ADDR-1:0] 	core_inst_addr_word;// word addressible, limited to max address space width

assign core_inst_addr_word = core_inst_addr[`BW_WORD_ADDR+1:2];


`RISCV_HART_INST core0(

	// system
	.clock_i 		(clock_bus_i[0]			), 
	.reset_i 		(reset_i				), 
	.exception_bus_o(core_exceptions 		), 
	.inst_addr_o 	(core_inst_addr 		), 
	.inst_word_o 	(),

	// instruction references - to memory controller
	.mem_req0_o 	(req0_core2mc 			), 
	.mem_rw0_o 		(rw0_core2mc 			), 
	.mem_add0_o 	(add0_core2mc 			), 
	.mem_data0_o 	(data0_core2mc 			), 
	.mem_data0_i 	(data0_mc2core 			), 
	.mem_done0_i 	(done0_mc2core 			),

	// data references - to memory controller
	.mem_req1_o 	(req1_core2mc 			), 
	.mem_rw1_o 		(rw1_core2mc 			), 
	.mem_add1_o 	(add1_core2mc 			), 
	.mem_data1_o 	(data1_core2mc 			), 
	.mem_data1_i 	(data1_mc2core 			), 
	.mem_done1_i 	(done1_mc2core 			),

	// peripheral system
	.per_req_o 		(per_req_o 				), 
	.per_rw_o 		(per_rw_o 				), 
	.per_add_o 		(per_add_o 				), 
	.per_data_o 	(per_data_o 			),
	.per_data_i 	(per_data_i 			)

);


// data cache
// ---------------------------------------------------------------------------------------------------------------
// core <-> cache
wire 				core_reqToCacheL2, core_rwToCacheL2, core_doneFromCacheL2;
wire 		[23:0]	core_addToCacheL2;
wire 		[31:0]	core_dataToCacheL2, core_dataFromCacheL2; 

// cache <-> memory controller
wire 				mci_enableToCacheL2, mci_readyToCacheL2, mci_writeReadyToCacheL2, mci_readReadyToCacheL2;
wire 		[31:0]	mci_dataToCacheL2, mci_dataFromCacheL2;
wire 		[23:0]	mci_addFromCacheL2;
wire 				mci_hitFromCacheL2, mci_reqFromCacheL2, mci_reqBlockFromCacheL2, mci_rwFromCacheL2, mci_writeFromCacheL2, mci_readFromCacheL2;
	
`L2_CACHE_INST #( 
	.POLICY 				(`L2_CACHE_POLICY 		), 
	.STRUCTURE 				(`INST_CACHE_STRUCTURE 		),
	.INIT_DONE 				(`INST_CACHE_INIT 			), 
	.CACHE_BLOCK_CAPACITY 	(`L2_CACHE_BLOCK_CAPACITY	)
) L2_combined_cache(
	// system 
	.clock_bus_i 			(clock_bus_i[3:2] 			), 
	.resetn_i 				(reset_i 					),
	.comm_i 				(comm_i 					), 
	.comm_o 				(comm_cacheL2_o 				),

	// core/hart					
	.core_req_i 			(core_reqToCacheL2 			), 
	.core_ref_add_i			(24'b0						), 	// only used in lease data cache
	.core_rw_i 				(core_rwToCacheL2 			), 
	.core_add_i 			(core_addToCacheL2 			), 
	.core_data_i 			(core_dataToCacheL2 			),
	.core_done_o 			(core_doneFromCacheL2 		), 
	.core_data_o 			(core_dataFromCacheL2 		),

	// memory controller	
	.en_i 					(mci_enableToCacheL2			), 
	.ready_req_i 			(mci_readyToCacheL2 			), 
	.ready_write_i 			(mci_writeReadyToCacheL2		), 
	.ready_read_i			(mci_readReadyToCacheL2 		), 
	.data_i 				(mci_dataToCacheL2 			), 
	.hit_o 					(mci_hitFromCacheL2 			), 
	.req_o 					(mci_reqFromCacheL2 			), 
	.req_block_o			(mci_reqBlockFromCacheL2 	), 
	.rw_o 					(mci_rwFromCacheL2 			), 
	.write_o 				(mci_writeFromCacheL2 		), 
	.read_o 				(mci_readFromCacheL2 		), 
	.add_o 					(mci_addFromCacheL2 			), 
	.data_o 				(mci_dataFromCacheL2 		)
);



// data cache
// ---------------------------------------------------------------------------------------------------------------
// core <-> cache
wire 				core_reqToCacheL1I, core_rwToCacheL1I, core_doneFromCacheL1I;
wire 		[23:0]	core_addToCacheL1I;
wire 		[31:0]	core_dataToCacheL1I, core_dataFromCacheL1I; 

// cache <-> memory controller
wire 				mci_enableToCacheL1I, mci_readyToCacheL1I, mci_writeReadyToCacheL1I, mci_readReadyToCacheL1I;
wire 		[31:0]	mci_dataToCacheL1I, mci_dataFromCacheL1I;
wire 		[23:0]	mci_addFromCacheL1I;
wire 				mci_hitFromCacheL1I, mci_reqFromCacheL1I, mci_reqBlockFromCacheL1I, mci_rwFromCacheL1I, mci_writeFromCacheL1I, mci_readFromCacheL1I;
	
`INSTRUCTION_CACHE_INST #( 
	.POLICY 				(`INST_CACHE_POLICY 		), 
	.STRUCTURE 				(`INST_CACHE_STRUCTURE 		),
	.INIT_DONE 				(`INST_CACHE_INIT 			), 
	.CACHE_BLOCK_CAPACITY 	(`INST_CACHE_BLOCK_CAPACITY	)
) inst_cache(
	// system 
	.clock_bus_i 			(clock_bus_i[3:2] 			), 
	.resetn_i 				(reset_i 					),
	.comm_i 				(comm_i 					), 
	.comm_o 				(comm_cacheL1I_o 				),

	// core/hart					
	.core_req_i 			(core_reqToCacheL1I 			), 
	.core_ref_add_i			(24'b0						), 	// only used in lease data cache
	.core_rw_i 				(core_rwToCacheL1I 			), 
	.core_add_i 			(core_addToCacheL1I 			), 
	.core_data_i 			(core_dataToCacheL1I 			),
	.core_done_o 			(core_doneFromCacheL1I 		), 
	.core_data_o 			(core_dataFromCacheL1I 		),

	// memory controller	
	.en_i 					(mci_enableToCacheL1I			), 
	.ready_req_i 			(mci_readyToCacheL1I 			), 
	.ready_write_i 			(mci_writeReadyToCacheL1I		), 
	.ready_read_i			(mci_readReadyToCacheL1I 		), 
	.data_i 				(mci_dataToCacheL1I 			), 
	.hit_o 					(mci_hitFromCacheL1I 			), 
	.req_o 					(mci_reqFromCacheL1I 			), 
	.req_block_o			(mci_reqBlockFromCacheL1I 	), 
	.rw_o 					(mci_rwFromCacheL1I 			), 
	.write_o 				(mci_writeFromCacheL1I 		), 
	.read_o 				(mci_readFromCacheL1I 		), 
	.add_o 					(mci_addFromCacheL1I 			), 
	.data_o 				(mci_dataFromCacheL1I 		)
);

// data cache
// ---------------------------------------------------------------------------------------------------------------
// core <-> cache
wire 				core_reqToCacheL1D, core_rwToCacheL1D, core_doneFromCacheL1D;
wire 		[23:0]	core_addToCacheL1D;
wire 		[31:0]	core_dataToCacheL1D, core_dataFromCacheL1D; 

// cache <-> memory controller
wire 				mci_enableToCacheL1D, mci_readyToCacheL1D, mci_writeReadyToCacheL1D, mci_readReadyToCacheL1D;
wire 		[31:0]	mci_dataToCacheL1D, mci_dataFromCacheL1D;
wire 		[23:0]	mci_addFromCacheL1D;
wire 				mci_hitFromCacheL1D, mci_reqFromCacheL1D, mci_reqBlockFromCacheL1D, mci_rwFromCacheL1D, mci_writeFromCacheL1D, mci_readFromCacheL1D;


`DATA_CACHE_INST #(
	.POLICY 		 		(`DATA_CACHE_POLICY 		), 
	.STRUCTURE 				(`DATA_CACHE_STRUCTURE 		),
	.INIT_DONE 				(`DATA_CACHE_INIT 			), 
	.CACHE_BLOCK_CAPACITY 	(`DATA_CACHE_BLOCK_CAPACITY	)
) data_cache(

	// system 
	.clock_bus_i 			(clock_bus_i[3:2] 			), 
	.resetn_i 				(reset_i 					),
	.comm_i 				(comm_i 					), 
	.comm_o 				(comm_cacheL1D_o 			),
	.PC_i             (core_inst_addr               ),  
	`ifdef DATA_POLICY_DLEASE
		.phase_i          (phase_i                   ),
	`endif
	.metric_sel_i    (cpc_metric_switch_i           ),
	// core/hart					
	.core_req_i 			(core_reqToCacheL1D 			), 
	.core_ref_add_i			(core_inst_addr_word		), 	// only used in lease data cache
	.core_rw_i 				(core_rwToCacheL1D 			), 
	.core_add_i 			(core_addToCacheL1D 			), 
	.core_data_i 			(core_dataToCacheL1D 			),
	.core_done_o 			(core_doneFromCacheL1D 		), 
	.core_data_o 			(core_dataFromCacheL1D 		),

	// memory controller	
	.en_i 					(mci_enableToCacheL1D			), 
	.ready_req_i 			(mci_readyToCacheL1D 			), 
	.ready_write_i 			(mci_writeReadyToCacheL1D		), 
	.ready_read_i			(mci_readReadyToCacheL1D 		), 
	.data_i 				(mci_dataToCacheL1D 			), 
	.hit_o 					(mci_hitFromCacheL1D 			), 
	.req_o 					(mci_reqFromCacheL1D 			), 
	.req_block_o			(mci_reqBlockFromCacheL1D 	), 
	.rw_o 					(mci_rwFromCacheL1D 			), 
	.write_o 				(mci_writeFromCacheL1D 		), 
	.read_o 				(mci_readFromCacheL1D 		), 
	.add_o 					(mci_addFromCacheL1D 			), 
	.data_o 				(mci_dataFromCacheL1D 		)
);



// memory controller
// --------------------------------------------------------------------
wire [7:0]	int_mem_exceptions; 

memory_controller_internal_2stage mem_cont_int(

	// general i/o
	.clock_bus_i(clock_bus_i[3:1]), .reset_i(reset_i), .exceptions_o(int_mem_exceptions),

	// i/o - core
	.core_req0_i(req0_core2mc), .core_rw0_i(rw0_core2mc), .core_add0_i(add0_core2mc), .core_data0_i(data0_core2mc), 
	.core_data0_o(data0_mc2core), .core_done0_o(done0_mc2core),

	.core_req1_i(req1_core2mc), .core_rw1_i(rw1_core2mc), .core_add1_i(add1_core2mc), .core_data1_i(data1_core2mc), 
	.core_data1_o(data1_mc2core), .core_done1_o(done1_mc2core),

	// i/o - external controller
	.mem_req_o(mem_req_o), .mem_reqBlock_o(mem_reqBlock_o), .mem_clear_o(mem_clear_o), .mem_rw_o(mem_rw_o), .mem_add_o(mem_add_o), .mem_data_o(mem_data_o),
	.mem_data_i(mem_data_i), .mem_done_i(mem_done_i), .mem_ready_i(mem_ready_i), .mem_valid_i(mem_valid_i),

	// i/o cache 0
	.CacheL1I_core_req_o(core_reqToCacheL1I), .CacheL1I_core_rw_o(core_rwToCacheL1I), .CacheL1I_core_add_o(core_addToCacheL1I), .CacheL1I_core_data_o(core_dataToCacheL1I),
	.CacheL1I_core_done_i(core_doneFromCacheL1I), .CacheL1I_core_data_i(core_dataFromCacheL1I),				

	.CacheL1I_uc_en_o(mci_enableToCacheL1I), .CacheL1I_uc_ready_o(mci_readyToCacheL1I), .CacheL1I_uc_write_ready_o(mci_writeReadyToCacheL1I), .CacheL1I_uc_read_ready_o(mci_readReadyToCacheL1I),.CacheL1I_uc_data_o(mci_dataToCacheL1I),
	.CacheL1I_hit_i(mci_hitFromCacheL1I), .CacheL1I_req_i(mci_reqFromCacheL1I), .CacheL1I_reqBlock_i(mci_reqBlockFromCacheL1I), .CacheL1I_rw_i(mci_rwFromCacheL1I), .CacheL1I_write_i(mci_writeFromCacheL1I), .CacheL1I_read_i(mci_readFromCacheL1I),
	.CacheL1I_add_i(mci_addFromCacheL1I), .CacheL1I_data_i(mci_dataFromCacheL1I),

	// i/o to cache 1
	.CacheL1D_core_req_o(core_reqToCacheL1D), .CacheL1D_core_rw_o(core_rwToCacheL1D), .CacheL1D_core_add_o(core_addToCacheL1D), .CacheL1D_core_data_o(core_dataToCacheL1D),
	.CacheL1D_core_done_i(core_doneFromCacheL1D), .CacheL1D_core_data_i(core_dataFromCacheL1D),				

	.CacheL1D_uc_en_o(mci_enableToCacheL1D), .CacheL1D_uc_ready_o(mci_readyToCacheL1D), .CacheL1D_uc_write_ready_o(mci_writeReadyToCacheL1D), .CacheL1D_uc_read_ready_o(mci_readReadyToCacheL1D),.CacheL1D_uc_data_o(mci_dataToCacheL1D),
	.CacheL1D_hit_i(mci_hitFromCacheL1D), .CacheL1D_req_i(mci_reqFromCacheL1D), .CacheL1D_reqBlock_i(mci_reqBlockFromCacheL1D), .CacheL1D_rw_i(mci_rwFromCacheL1D), .CacheL1D_write_i(mci_writeFromCacheL1D), .CacheL1D_read_i(mci_readFromCacheL1D),
	.CacheL1D_add_i(mci_addFromCacheL1D), .CacheL1D_data_i(mci_dataFromCacheL1D)

);

// exception assignments
// --------------------------------------------------------------------
assign exception_o = {int_mem_exceptions, core_exceptions};


endmodule