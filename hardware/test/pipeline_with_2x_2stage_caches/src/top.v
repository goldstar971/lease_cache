`ifndef _TOP_V_
`define _TOP_V_

`include "../include/top.h"

module top #(
	parameter BW_CORE_ADDR_BYTE		= 32, 				// byte addressible input address
	parameter BW_USED_ADDR_BYTE 	= 26, 				// byte addressible converted address
	parameter BW_DATA_WORD 			= 32,  				// bits in a data word
	parameter BW_DATA_EXTERNAL_BUS 	= 512, 				// bits that can be transfered between this level cache and next
	parameter BW_CACHE_COMMAND 		= 3,
	parameter CACHE_WORDS_PER_BLOCK = 16, 				// words in a block
	parameter CACHE_CAPACITY_BLOCKS = 128, 				// cache capacity in blocks
	parameter CACHE_ASSOCIATIVITY 	= 0, 				// 0 = fully associative
														// 1 = direct mapped
														// 2 = two way set associative
														// 4 = four way set associative
														// 8 = eight way set associative
														// 16 = sixteen way set associative				
	parameter CACHE_POLICY 			= "",
	parameter BW_CONFIG_REGS 		= 32,
	parameter BW_RAM_ADDR_WORD 		= 16,
	parameter BW_USED_ADDR_WORD 	= BW_USED_ADDR_BYTE - 2
)(
	input 								clock_control_i, 	// core, level one cache controller, main memory arbiter controller
	input 								clock_rw_i, 		// buffer, tag lookup table, cache memory
	input 								resetn_i,
	output 								io_request_o, 		// i/o signal buses
	output 								io_wren_o,
	output 	[BW_CORE_ADDR_BYTE-1:0]		io_addr_o,
	output 	[BW_DATA_WORD-1:0] 			io_data_o,
	input  								io_valid_i,
	input  	[BW_DATA_WORD-1:0] 			io_data_i
);


// core pipeline
// -----------------------------------------------------------------------------------------------------------------------------------------------
wire 							core_stall_bus;

wire 							core_inst_req_flag;
wire 							core_inst_valid_flag;
wire 	[BW_CORE_ADDR_BYTE-1:0] core_inst_addr_bus;
wire 	[BW_DATA_WORD-1:0] 		core_inst_read_data_bus;

wire 							core_data_req_flag;
wire 							core_data_valid_flag;
wire 							core_data_wren_flag;
wire 	[BW_CORE_ADDR_BYTE-1:0] core_data_addr_bus;
wire 	[BW_DATA_WORD-1:0] 		core_data_read_data_bus,
								core_data_write_data_bus;

riscv_hart_6stage_pipeline_2stage_cache hart_inst(

	// system
	.clock_i 		(clock_control_i 			),
	.reset_i 		(resetn_i 		 			),
	.stall_i 		(core_stall_bus 			),

	// internal memory system (inst references)
	.inst_data_i 	(core_inst_read_data_bus	),  	// direct from $ memory
	.inst_valid_i 	(core_inst_valid_flag		), 		// from controller
	.inst_req_o 	(core_inst_req_flag 		), 	 	//
	.inst_addr_o 	(core_inst_addr_bus 		),  	//
	
	// internal memory system (data references)
	.data_data_i 	(core_data_read_data_bus 	),  	// from switch
	.data_valid_i 	(core_data_valid_flag		), 		// from switch
	.data_req_o 	(core_data_req_flag 		),  	//
	.data_wren_o 	(core_data_wren_flag 		), 		// 
	.data_addr_o 	(core_data_addr_bus 		),  	//
	.data_data_o 	(core_data_write_data_bus 	) 		//
);


// data orderer
// -----------------------------------------------------------------------------------------------------------------------------------------------
wire 						cache_data_req_flag;
wire 						cache_data_valid_flag;
wire 	[BW_DATA_WORD-1:0] 	cache_data_read_bus;

wire 						io_data_req_flag;
wire 						io_data_valid_flag;
wire 	[BW_DATA_WORD-1:0] 	io_data_read_bus;

memory_request_orderer #(
	.N_ENTRIES 			(4 							), 		// size of tracking buffer
	.BW_DATA 			(BW_DATA_WORD 				),
	.BW_ADDR 			(BW_CORE_ADDR_BYTE 			)
) data_request_handler (
	.clock_i			(clock_rw_i 				), 		// trigger for registering inputs
	.resetn_i 			(resetn_i 					),
	.hart_request_i		(core_data_req_flag 		), 		// only three signals needed to manage i/o requests
	.hart_wren_i 		(core_data_wren_flag 		),
	.hart_addr_i 		(core_data_addr_bus 		),
	.hart_valid_o 		(core_data_valid_flag 		), 		// mux of data cache and i/o load services
	.hart_data_o 		(core_data_read_data_bus	),

	.memory_request_o 	(cache_data_req_flag 		), 		// data cache signals
	.memory_data_i		(cache_data_read_bus 		),
	.memory_valid_i 	(cache_data_valid_flag		),

	.io_request_o 		(io_data_req_flag 			), 		// i/o signals
	.io_valid_i 		(io_data_valid_flag 		),
	.io_data_i 			(io_data_read_bus 			)
);

assign io_request_o 		= io_data_req_flag;
assign io_wren_o 			= core_data_wren_flag;
assign io_addr_o 			= core_data_addr_bus;
assign io_data_o 			= core_data_write_data_bus;
assign io_data_valid_flag 	= io_valid_i;
assign io_data_read_bus 	= io_data_i;

reg [31:0]	inst_ref_trace,
			data_ref_trace;
always @(posedge clock_control_i) begin
	if (!resetn_i) begin
		data_ref_trace <= 'b0;
		inst_ref_trace <= 'b0;
	end
	else begin
		if (core_inst_req_flag) 	inst_ref_trace <= inst_ref_trace + 1'b1;
		if (cache_data_req_flag) 	data_ref_trace <= data_ref_trace + 1'b1;
	end
end


// cache controller
// -----------------------------------------------------------------------------------------------------------------------------------------------

// inst cache
wire 								inst_stall_flag;
wire 								inst_write_in_bus;
wire  	[BW_CACHE_COMMAND-1:0] 		inst_command_in_bus;
wire 	[BW_USED_ADDR_WORD-1:0] 	inst_addr_in_bus;
wire  	[BW_DATA_EXTERNAL_BUS-1:0] 	inst_data_in_bus;
wire 								inst_full_in_bus; 
wire 								inst_write_out_bus;
wire  	[BW_CACHE_COMMAND-1:0] 		inst_command_out_bus;
wire 	[BW_USED_ADDR_WORD-1:0] 	inst_addr_out_bus;
wire  	[BW_DATA_EXTERNAL_BUS-1:0] 	inst_data_out_bus;
wire 								inst_full_out_bus; 

cache_level_1 #(
	.BW_CORE_ADDR_BYTE 		(BW_CORE_ADDR_BYTE 		), 		// byte addressible input address
	.BW_USED_ADDR_BYTE 		(BW_USED_ADDR_BYTE 		), 		// byte addressible converted address
	.BW_DATA_WORD 			(BW_DATA_WORD 			),  	// bits in a data word
	.BW_DATA_EXTERNAL_BUS 	(BW_DATA_EXTERNAL_BUS 	), 		// bits that can be transfered between this level cache and next
	.BW_CACHE_COMMAND 		(BW_CACHE_COMMAND 		),
	.CACHE_WORDS_PER_BLOCK 	(CACHE_WORDS_PER_BLOCK 	), 		// words in a block
	.CACHE_CAPACITY_BLOCKS 	(CACHE_CAPACITY_BLOCKS 	), 		// cache capacity in blocks
	.CACHE_ASSOCIATIVITY 	(CACHE_ASSOCIATIVITY 	),				
	.CACHE_POLICY 			(CACHE_POLICY 			),
	.BW_CONFIG_REGS 		(BW_CONFIG_REGS 		)
) inst_cache_level_1_inst (

	// control signals
	.clock_control_i 		(clock_control_i 		),
	.clock_rw_i 			(clock_rw_i 		 	),
	.resetn_i 		 		(resetn_i 			 	),
	.stall_i 				(1'b0 					), 		// stall caused by external hardware
	.stall_o 				(inst_stall_flag 		), 		// stall caused by this cache level

	// metric, control, and misc signals
	.config0_i 				('b0 					), 		// cache commands
	.config1_i 				('b0 					), 		// cache buffer addresses
	.status_o				( 						), 		// cache/components status 		
	.config0_o 				( 						), 		// cache buffer data

	// core/hart signals
	.core_request_i 	 	(core_inst_req_flag 	),	
	.core_wren_i 	 		(1'b0 					),
	.core_addr_i 	 		(core_inst_addr_bus 	),
	.core_data_i 	 		('b0 					),
	.core_valid_o 	 		(core_inst_valid_flag 	),
	.core_data_o 	 		(core_inst_read_data_bus),

	// next level memory signals - from next level
	.external_write_i 		(inst_write_in_bus 		),
	.external_command_i 	(inst_command_in_bus 	),
	.external_addr_i 		(inst_addr_in_bus 		),
	.external_data_i 		(inst_data_in_bus 		),
	.external_full_o 		(inst_full_in_bus 		),

	// next level memory signals - to next level
	.external_write_o 		(inst_write_out_bus		),
	.external_command_o 	(inst_command_out_bus 	),
	.external_addr_o 		(inst_addr_out_bus		),
	.external_data_o 		(inst_data_out_bus		),
	.external_full_i 		(inst_full_out_bus		)
);

// data cache
wire 								data_stall_flag;
wire 								data_write_in_bus;
wire  	[BW_CACHE_COMMAND-1:0] 		data_command_in_bus;
wire 	[BW_USED_ADDR_WORD-1:0] 	data_addr_in_bus;
wire  	[BW_DATA_EXTERNAL_BUS-1:0] 	data_data_in_bus;
wire 								data_full_in_bus; 
wire 								data_write_out_bus;
wire  	[BW_CACHE_COMMAND-1:0] 		data_command_out_bus;
wire 	[BW_USED_ADDR_WORD-1:0] 	data_addr_out_bus;
wire  	[BW_DATA_EXTERNAL_BUS-1:0] 	data_data_out_bus;
wire 								data_full_out_bus; 

cache_level_1 #(
	.BW_CORE_ADDR_BYTE 		(BW_CORE_ADDR_BYTE 		), 		// byte addressible input address
	.BW_USED_ADDR_BYTE 		(BW_USED_ADDR_BYTE 		), 		// byte addressible converted address
	.BW_DATA_WORD 			(BW_DATA_WORD 			),  	// bits in a data word
	.BW_DATA_EXTERNAL_BUS 	(BW_DATA_EXTERNAL_BUS 	), 		// bits that can be transfered between this level cache and next
	.BW_CACHE_COMMAND 		(BW_CACHE_COMMAND 		),
	.CACHE_WORDS_PER_BLOCK 	(CACHE_WORDS_PER_BLOCK 	), 		// words in a block
	.CACHE_CAPACITY_BLOCKS 	(CACHE_CAPACITY_BLOCKS 	), 		// cache capacity in blocks
	.CACHE_ASSOCIATIVITY 	(CACHE_ASSOCIATIVITY 	),				
	.CACHE_POLICY 			(CACHE_POLICY 			),
	.BW_CONFIG_REGS 		(BW_CONFIG_REGS 		)
) data_cache_level_1_inst (

	// control signals
	.clock_control_i 		(clock_control_i 		),
	.clock_rw_i 			(clock_rw_i 		 	),
	.resetn_i 		 		(resetn_i 			 	),
	.stall_i 				(1'b0 					), 		// stall caused by external hardware
	.stall_o 				(data_stall_flag 		), 		// stall caused by this cache level

	// metric, control, and misc signals
	.config0_i 				('b0 					), 		// cache commands
	.config1_i 				('b0 					), 		// cache buffer addresses
	.status_o				( 						), 		// cache/components status 		
	.config0_o 				( 						), 		// cache buffer data

	// core/hart signals
	.core_request_i 	 	(cache_data_req_flag 		),	
	.core_wren_i 	 		(core_data_wren_flag 		),
	.core_addr_i 	 		(core_data_addr_bus 		),
	.core_data_i 	 		(core_data_write_data_bus 	),
	.core_valid_o 	 		(cache_data_valid_flag 		),
	.core_data_o 	 		(cache_data_read_bus 		),

	// next level memory signals - from next level
	.external_write_i 		(data_write_in_bus 		),
	.external_command_i 	(data_command_in_bus 	),
	.external_addr_i 		(data_addr_in_bus 		),
	.external_data_i 		(data_data_in_bus 		),
	.external_full_o 		(data_full_in_bus 		),

	// next level memory signals - to next level
	.external_write_o 		(data_write_out_bus		),
	.external_command_o 	(data_command_out_bus 	),
	.external_addr_o 		(data_addr_out_bus		),
	.external_data_o 		(data_data_out_bus		),
	.external_full_i 		(data_full_out_bus		)
);

assign core_stall_bus = inst_stall_flag | data_stall_flag;


// external memory controller
// -----------------------------------------------------------------------------------------------------------------------------------------------
wire 						memory_wren;
wire [BW_RAM_ADDR_WORD-1:0] memory_addr;
wire [BW_DATA_WORD-1:0] 	memory_write_data;
wire [BW_DATA_WORD-1:0] 	memory_read_data;

test_memory_controller #(
	.BW_RAM_ADDR_WORD 		(BW_RAM_ADDR_WORD 		),
	.BW_USED_ADDR_BYTE 		(BW_USED_ADDR_BYTE 		), 		// byte addressible converted address
	.BW_DATA_WORD 			(BW_DATA_WORD 			),  	// bits in a data word
	.BW_DATA_EXTERNAL_BUS 	(BW_DATA_EXTERNAL_BUS 	), 		// bits that can be transfered between this level cache and next
	.BW_CACHE_COMMAND 		(BW_CACHE_COMMAND 		),
	.CACHE_WORDS_PER_BLOCK 	(CACHE_WORDS_PER_BLOCK 	), 		// words in a block
	.CACHE_CAPACITY_BLOCKS 	(CACHE_CAPACITY_BLOCKS 	), 		// cache capacity in blocks
	.CACHE_ASSOCIATIVITY 	(CACHE_ASSOCIATIVITY 	),				
	.CACHE_POLICY 			(CACHE_POLICY 			),
	.BW_CONFIG_REGS 		(BW_CONFIG_REGS 		)
) test_memory_controller_inst (

	// generics
	.clock_i 		 		(clock_control_i 		),
	.clock_rw_i 	 		(clock_rw_i 			),
	.resetn_i 		 		(resetn_i 				),

	// level one instruction cache
	.inst_write_o 			(inst_write_in_bus 	 	), 		// inst cache rx buffer <- next level controller
	.inst_command_o 		(inst_command_in_bus 	),
	.inst_addr_o 			(inst_addr_in_bus 		),
	.inst_data_o 			(inst_data_in_bus 		),
	.inst_full_i 			(inst_full_in_bus 		),
	.inst_write_i 			(inst_write_out_bus		), 		// inst cache <- next level controller rx buffer
	.inst_command_i 		(inst_command_out_bus 	),
	.inst_addr_i 			(inst_addr_out_bus	 	),
	.inst_data_i 			(inst_data_out_bus	 	),
	.inst_full_o 			(inst_full_out_bus		),

	// level one data cache
	.data_write_o 			(data_write_in_bus 	 	), 		// data cache rx buffer <- next level controller
	.data_command_o 		(data_command_in_bus 	),
	.data_addr_o 			(data_addr_in_bus 		),
	.data_data_o 			(data_data_in_bus 		),
	.data_full_i 			(data_full_in_bus 		),
	.data_write_i 			(data_write_out_bus		), 		// data cache <- next level controller rx buffer
	.data_command_i 		(data_command_out_bus 	),
	.data_addr_i 			(data_addr_out_bus	 	),
	.data_data_i 			(data_data_out_bus	 	),
	.data_full_o 			(data_full_out_bus		),

	// main memory									
	.main_wren_o 			(memory_wren 			),
	.main_addr_o 			(memory_addr 			),
	.main_data_o 			(memory_write_data 		),
	.main_data_i 			(memory_read_data 		)

);


// external memory
// -----------------------------------------------------------------------------------------------------------------------------------------------
memory_embedded #(
	.N_ENTRIES 				(2**BW_RAM_ADDR_WORD 	),
	.BW_DATA 				(BW_DATA_WORD 			),
	.DEBUG 					(0 						), 		// if 1 sets the BRAM to dual port so in memory content editor
	.INIT_PATH 				("test.mif" 			) 		// memory to initialize to
) synthetic_external_memory_inst (
	.clock_i 				(clock_rw_i 			),
	.wren_i 				(memory_wren 			),
	.addr_i 				(memory_addr 			),
	.data_i 				(memory_write_data 		),
	.data_o 				(memory_read_data 		)
);


endmodule

`endif