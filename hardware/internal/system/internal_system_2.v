// define cache types in top.h
// -----------------------------------------------------------------------------------------------------

module internal_system_2(

	// general ports
	input 	[3:0]	clock_bus_i, // [3,2,1,0] = [40/270,40/180,40/90,40/0]
	input 			reset_i,
	output 	[11:0]	exception_o,
	input 	[31:0]	comm_i, 
		input 	[31:0] 	phase_i,
	output 	[31:0]	comm_cache0_o, 
	output 	[31:0]	comm_cache1_o,
	input    [1:0]    cpc_metric_switch_i,
	input    [15:0]    rate_shift_seed_i,
	
	// external system
	output 			mem_req_o, 
	output 			mem_reqBlock_o, 
	output 			mem_clear_o, 
	output 			mem_rw_o,
	output 	[`BW_WORD_ADDR-1:0]	mem_add_o, 		// word addressible
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
	input 	[31:0]	per_data_i,
	output   [191:0]  cycle_counts_o		
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

assign core_inst_addr_word = core_inst_addr[`BW_BYTE_ADDR-1:2];


`RISCV_HART_INST core0(

	// system
	.clock_bus_i 		({clock_bus_i[3],clock_bus_i[1],clock_bus_i[0]}			), 
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
	.per_data_i 	(per_data_i 			),
	.cycle_counts_o(cycle_counts_o		)

);


// data cache
// ---------------------------------------------------------------------------------------------------------------
// core <-> cache
wire 				core_reqToCache0, core_rwToCache0, core_doneFromCache0;
wire 		[`BW_WORD_ADDR-1:0]	core_addToCache0;
wire 		[31:0]	core_dataToCache0, core_dataFromCache0; 

// cache <-> memory controller
wire 				mci_enableToCache0, mci_readyToCache0, mci_writeReadyToCache0, mci_readReadyToCache0;
wire 		[31:0]	mci_dataToCache0, mci_dataFromCache0;
wire 		[`BW_WORD_ADDR-1:0]	mci_addFromCache0;
wire 				mci_hitFromCache0, mci_reqFromCache0, mci_reqBlockFromCache0, mci_rwFromCache0, mci_writeFromCache0, mci_readFromCache0;
	
`INSTRUCTION_CACHE_INST#( 
	.POLICY 				(`INST_CACHE_POLICY 		), 
	.STRUCTURE 				(`INST_CACHE_STRUCTURE 		),
	.INIT_DONE 				(`INST_CACHE_INIT 			), 
	.CACHE_BLOCK_CAPACITY 	(`INST_CACHE_BLOCK_CAPACITY	),
	.CACHE_SET_SIZE         (`INST_CACHE_SET_SIZE),
	.CACHE_TYPE             (`MIN_DATA_COLLECTION)
) inst_cache(
	// system 
	.clock_bus_i 			(clock_bus_i[3:2] 			), 
	.resetn_i 				(reset_i 					),
	.comm_i 				(comm_i 					), 
	.comm_o 				(comm_cache0_o 				),
	.phase_i          		(phase_i                   ),
	.metric_sel_i          (cpc_metric_switch_i           ),
	.rate_shift_seed_i     (rate_shift_seed_i),
	// core/hart					
	.core_req_i 			(core_reqToCache0 			), 
	.core_ref_add_i			(core_inst_addr_word		), 	// only used in lease data cache
	.core_rw_i 				(core_rwToCache0 			), 
	.core_add_i 			(core_addToCache0 			), 
	.core_data_i 			(core_dataToCache0 			),
	.core_done_o 			(core_doneFromCache0 		), 
	.core_data_o 			(core_dataFromCache0 		),

	// memory controller	
	.en_i 					(mci_enableToCache0			), 
	.ready_req_i 			(mci_readyToCache0 			), 
	.ready_write_i 			(mci_writeReadyToCache0		), 
	.ready_read_i			(mci_readReadyToCache0 		), 
	.data_i 				(mci_dataToCache0 			), 
	.hit_o 					(mci_hitFromCache0 			), 
	.req_o 					(mci_reqFromCache0 			), 
	.req_block_o			(mci_reqBlockFromCache0 	), 
	.rw_o 					(mci_rwFromCache0 			), 
	.write_o 				(mci_writeFromCache0 		), 
	.read_o 				(mci_readFromCache0 		), 
	.add_o 					(mci_addFromCache0 			), 
	.data_o 				(mci_dataFromCache0 		)
);

// data cache
// ---------------------------------------------------------------------------------------------------------------
// core <-> cache
wire 				core_reqToCache1, core_rwToCache1, core_doneFromCache1;
wire 		[`BW_WORD_ADDR-1:0]	core_addToCache1;
wire 		[31:0]	core_dataToCache1, core_dataFromCache1; 

// cache <-> memory controller
wire 				mci_enableToCache1, mci_readyToCache1, mci_writeReadyToCache1, mci_readReadyToCache1;
wire 		[31:0]	mci_dataToCache1, mci_dataFromCache1;
wire 		[`BW_WORD_ADDR-1:0]	mci_addFromCache1;
wire 				mci_hitFromCache1, mci_reqFromCache1, mci_reqBlockFromCache1, mci_rwFromCache1, mci_writeFromCache1, mci_readFromCache1;

`DATA_CACHE_INST #(
	.POLICY 		 		(`DATA_CACHE_POLICY 		), 
	.STRUCTURE 				(`DATA_CACHE_STRUCTURE 		),
	.INIT_DONE 				(`DATA_CACHE_INIT 			), 
	.CACHE_BLOCK_CAPACITY 	(`DATA_CACHE_BLOCK_CAPACITY	),
	.CACHE_SET_SIZE         (`DATA_CACHE_SET_SIZE),
	.CACHE_TYPE             (`MAX_DATA_COLLECTION)
) data_cache(

	// system 
	.clock_bus_i 			(clock_bus_i[3:2] 			), 
	.resetn_i 				(reset_i 					),
	.comm_i 				(comm_i 					), 
	.comm_o 				(comm_cache1_o 				),
	.PC_i             (core_inst_addr               ),  
		.phase_i          (phase_i                   ),
	.metric_sel_i    (cpc_metric_switch_i           ),
	.rate_shift_seed_i     (rate_shift_seed_i),
	// core/hart					
	.core_req_i 			(core_reqToCache1 			), 
	.core_ref_add_i			(core_inst_addr_word		), 	// only used in lease data cache
	.core_rw_i 				(core_rwToCache1 			), 
	.core_add_i 			(core_addToCache1 			), 
	.core_data_i 			(core_dataToCache1 			),
	.core_done_o 			(core_doneFromCache1 		), 
	.core_data_o 			(core_dataFromCache1 		),

	// memory controller	
	.en_i 					(mci_enableToCache1			), 
	.ready_req_i 			(mci_readyToCache1 			), 
	.ready_write_i 			(mci_writeReadyToCache1		), 
	.ready_read_i			(mci_readReadyToCache1 		), 
	.data_i 				(mci_dataToCache1 			), 
	.hit_o 					(mci_hitFromCache1 			), 
	.req_o 					(mci_reqFromCache1 			), 
	.req_block_o			(mci_reqBlockFromCache1 	), 
	.rw_o 					(mci_rwFromCache1 			), 
	.write_o 				(mci_writeFromCache1 		), 
	.read_o 				(mci_readFromCache1 		), 
	.add_o 					(mci_addFromCache1 			), 
	.data_o 				(mci_dataFromCache1 		)
);


// memory controller
// --------------------------------------------------------------------
wire [7:0]	int_mem_exceptions; 

memory_controller_internal mem_cont_int(

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
	.cache0_core_req_o(core_reqToCache0), .cache0_core_rw_o(core_rwToCache0), .cache0_core_add_o(core_addToCache0), .cache0_core_data_o(core_dataToCache0),
	.cache0_core_done_i(core_doneFromCache0), .cache0_core_data_i(core_dataFromCache0),				

	.cache0_uc_en_o(mci_enableToCache0), .cache0_uc_ready_o(mci_readyToCache0), .cache0_uc_write_ready_o(mci_writeReadyToCache0), .cache0_uc_read_ready_o(mci_readReadyToCache0),.cache0_uc_data_o(mci_dataToCache0),
	.cache0_hit_i(mci_hitFromCache0), .cache0_req_i(mci_reqFromCache0), .cache0_reqBlock_i(mci_reqBlockFromCache0), .cache0_rw_i(mci_rwFromCache0), .cache0_write_i(mci_writeFromCache0), .cache0_read_i(mci_readFromCache0),
	.cache0_add_i(mci_addFromCache0), .cache0_data_i(mci_dataFromCache0),

	// i/o to cache 1
	.cache1_core_req_o(core_reqToCache1), .cache1_core_rw_o(core_rwToCache1), .cache1_core_add_o(core_addToCache1), .cache1_core_data_o(core_dataToCache1),
	.cache1_core_done_i(core_doneFromCache1), .cache1_core_data_i(core_dataFromCache1),				

	.cache1_uc_en_o(mci_enableToCache1), .cache1_uc_ready_o(mci_readyToCache1), .cache1_uc_write_ready_o(mci_writeReadyToCache1), .cache1_uc_read_ready_o(mci_readReadyToCache1),.cache1_uc_data_o(mci_dataToCache1),
	.cache1_hit_i(mci_hitFromCache1), .cache1_req_i(mci_reqFromCache1), .cache1_reqBlock_i(mci_reqBlockFromCache1), .cache1_rw_i(mci_rwFromCache1), .cache1_write_i(mci_writeFromCache1), .cache1_read_i(mci_readFromCache1),
	.cache1_add_i(mci_addFromCache1), .cache1_data_i(mci_dataFromCache1)

);

// exception assignments
// --------------------------------------------------------------------
assign exception_o = {int_mem_exceptions, core_exceptions};


endmodule
