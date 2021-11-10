`include "../include/top.h"


module top(

	// DDR3 pins
	output	[13:0]	ddr3b_a,
	output	[2:0]		ddr3b_ba,
	output 				ddr3b_casn,
	output 				ddr3b_clk_n,
	output 				ddr3b_clk_p,
	output 				ddr3b_cke,
	output 				ddr3b_csn,
	output	[7:0] 		ddr3b_dm,
	output 				ddr3b_odt,
	output 				ddr3b_rasn,
	output 				ddr3b_resetn,
	output 				ddr3b_wen,
	inout	[63:0] 		ddr3b_dq,
	inout	[7:0] 		ddr3b_dqs_n,
	inout 	[7:0] 		ddr3b_dqs_p,

	// operational and debugging pins
	input 				user_pb, 				// pll reset
	output 	[7:0] 		user_led, 			// status LEDs
	input 				clkin_r_p,        	// base clock for DDR3 (100 Mhz)
	input 				cpu_resetn,       	// top level reset (reset controller, jtag-uart, & ddr3)
	input 				rzqin_1_5v        	// on chip termination
);

// clock generation
// -------------------------------------------------------------------------------------------------------
wire [5:0]	clock_gen_bus;
wire 		pll_locked;

double_speed pll_reset(
	.refclk			(clkin_r_p			), 
	.rst 			(~user_pb 			), 
	.outclk_0 		(clock_gen_bus[0] 	), 	// 40 Mhz
	.outclk_1 		(clock_gen_bus[1]	), 	// 80 Mhz
	.outclk_2 		(clock_gen_bus[2]	),  // 80 Mhz, 180deg phase
	.outclk_3 		(clock_gen_bus[3]	),  // 40 Mhz, 90deg phase
	.outclk_4 		(clock_gen_bus[4]	),  // 40 Mhz, 180deg phase
	.outclk_5 		(clock_gen_bus[5]	),  // 40 Mhz, 270deg phase
	.locked 		(pll_locked 		)
);

assign user_led[7] = !pll_locked;
assign user_led[6:5] =2'b11;
assign user_led[4] = !comm_toCore[24];

// internal hardware system (core, cache)
// -------------------------------------------------------------------------------------------------------

// general buses

wire 	[31:0]	comm_toCore, comm_fromCache0, comm_fromCache1;

// internal system <-> external system buses
wire 			req_fromCore, reqBlock_fromCore, clear_fromCore, rw_fromCore, ready_toCore, done_toCore, valid_toCore;
wire 	[`BW_WORD_ADDR-1:0] 	add_fromCore;
wire 	[31:0]	data_toCore, data_fromCore;

// internal system <-> peripheral system buses
wire 			req_core2per, rw_core2per;
wire 	[31:0]	add_core2per;
wire 	[31:0]	data_core2per, data_per2core;  	
wire 	[31:0] 	phase_bus;
wire  [191:0] cycle_counts_o;

`ifdef MULTI_LEVEL_CACHE
wire [31:0] comm_fromCacheL2;
internal_system_2_multi_level riscv_sys (

	// general ports
	.clock_bus_i 	({clock_gen_bus[5:3],clock_gen_bus[0]}	), // [40-270, 40-180, 40-90, 40]
	.reset_i 		(cpu_system_reset),
	.phase_i (phase_bus),
	.exception_o 	(), 
	.comm_i 		(comm_toCore 		), 
	.comm_cacheL1I_o 	(comm_fromCache0 	), 
	.comm_cacheL1D_o 	(comm_fromCache1 	),
	.comm_cacheL2_o (comm_fromCacheL2   ),
	.cpc_metric_switch_i   (sel_cpc     ),
	.rate_shift_seed_i(rate_shift_seed),

	// external system
	.mem_req_o 		(req_fromCore 		), 
	.mem_reqBlock_o (reqBlock_fromCore	), 
	.mem_clear_o 	(clear_fromCore		), 
	.mem_rw_o 		(rw_fromCore		), 
	.mem_add_o 		(add_fromCore		), 	// [29:0] ? < ---------------------------------------------------------------------------------
	.mem_data_o 	(data_fromCore		), 
	.mem_data_i 	(data_toCore		), 
	.mem_ready_i	(ready_toCore		), 
	.mem_done_i 	(done_toCore		), 
	.mem_valid_i 	(valid_toCore		),

	// peripheral system
	.per_req_o 		(req_core2per		), 
	.per_rw_o 		(rw_core2per		), 
	.per_add_o 		(add_core2per		), 
	.per_data_o 	(data_core2per		), 
	.per_data_i 	(data_per2core		),
	.cycle_counts_o (cycle_counts_o  )
);
`else
internal_system_2 riscv_sys (

	// general ports
	.clock_bus_i 	({clock_gen_bus[5:3],clock_gen_bus[0]}	), // [40-270, 40-180, 40-90, 40]
	.reset_i 		(cpu_system_reset 		),
	.phase_i (phase_bus),
	.exception_o 	(), 
	.comm_i 		(comm_toCore 		), 
	.comm_cache0_o 	(comm_fromCache0 	), 
	.comm_cache1_o 	(comm_fromCache1 	),
	.cpc_metric_switch_i   (sel_cpc     ),
	.rate_shift_seed_i(rate_shift_seed),

	// external system
	.mem_req_o 		(req_fromCore 		), 
	.mem_reqBlock_o (reqBlock_fromCore	), 
	.mem_clear_o 	(clear_fromCore		), 
	.mem_rw_o 		(rw_fromCore		), 
	.mem_add_o 		(add_fromCore		), 	// [26:0] ? < ---------------------------------------------------------------------------------
	.mem_data_o 	(data_fromCore		), 
	.mem_data_i 	(data_toCore		), 
	.mem_ready_i	(ready_toCore		), 
	.mem_done_i 	(done_toCore		), 
	.mem_valid_i 	(valid_toCore		),

	// peripheral system
	.per_req_o 		(req_core2per		), 
	.per_rw_o 		(rw_core2per		), 
	.per_add_o 		(add_core2per		), 
	.per_data_o 	(data_core2per		), 
	.per_data_i 	(data_per2core		),
	.cycle_counts_o (cycle_counts_o  )
);
`endif


// external hardware system (comm, ddr3)
// -------------------------------------------------------------------------------------------------------

// external system <-> peripheral system buses
wire 			req_toPer1, rw_toPer1;
wire 	[`BW_BYTE_ADDR:0]	add_toPer1;
wire 	[31:0]	data_toPer1, data_fromPer1;
wire [1:0] sel_cpc;
wire [15:0] rate_shift_seed;

external_memory_system_2 system_ext_inst(

	// ddr3 hardware pins
	.ddr3b_a 		(ddr3b_a 			),
	.ddr3b_ba 		(ddr3b_ba 			),
	.ddr3b_casn 	(ddr3b_casn 		),
	.ddr3b_clk_n 	(ddr3b_clk_n 		),
	.ddr3b_clk_p 	(ddr3b_clk_p 		),
	.ddr3b_cke 		(ddr3b_cke 			),
	.ddr3b_csn 		(ddr3b_csn 			),
	.ddr3b_dm 		(ddr3b_dm 			),
	.ddr3b_odt 		(ddr3b_odt 			),
	.ddr3b_rasn 	(ddr3b_rasn 		),
	.ddr3b_resetn 	(ddr3b_resetn 		),
	.ddr3b_wen 		(ddr3b_wen 			),
	.ddr3b_dq 		(ddr3b_dq 			),
	.ddr3b_dqs_n 	(ddr3b_dqs_n		),
	.ddr3b_dqs_p 	(ddr3b_dqs_p		),

	// termination, operation, and debugging pins
	.user_led 		(user_led[3:0]		),
	.clkin_r_p 		(clkin_r_p			),
	.cpu_resetn 	(cpu_resetn			),
	.rzqin_1_5v 	(rzqin_1_5v			),
	.clock_bus_i 	({clock_gen_bus[2:1],clock_gen_bus[4],clock_gen_bus[0]} ), 		//	 80 Mhz 180deg, 80 Mhz,phase 40 Mhz 180deg phase, 40 Mhz

	// internal system ports
	.int_req_i 		(req_fromCore 		),
	.int_reqBlock_i (reqBlock_fromCore	),
	.int_rw_i 		(rw_fromCore 		),
	.int_add_i 		(add_fromCore 		),
	.int_data_i 	(data_fromCore 		),
	.int_clear_i 	(clear_fromCore 	),
	.int_ready_o 	(ready_toCore 		),
	.int_done_o 	(done_toCore 		),
	.int_valid_o 	(valid_toCore 		),
	.int_data_o 	(data_toCore 		),

	// peripheral system ports
	.per_req_o 		(req_toPer1			),
	.per_rw_o		(rw_toPer1			),
	.per_add_o 		(add_toPer1			), 	// [29:0] - byte addressible
	.per_data_o 	(data_toPer1		),
	.per_data_i 	(data_fromPer1		)
);

// peripheral i/o's system
// -------------------------------------------------------------------------------------------------------

wire cpu_system_reset;
peripheral_system_3 per_sys_inst(

	// system ports
	.clock_i 		(clock_gen_bus[0]	), 	// 40 Mhz, 180 deg phase
	.cpu_resetn_i 		(cpu_resetn 		), 

	
	// internal system
	.req_core_i 	(req_core2per		), 
	.rw_core_i 		(rw_core2per		), 
	.add_core_i 	(add_core2per		), 	// [29:0]
	.data_core_i 	(data_core2per		),
	.data_core_o 	(data_per2core 		),
	.cycle_counts_i (cycle_counts_o),

	// external system
	.req_cs_i 		(req_toPer1 		), 
	.rw_cs_i 		(rw_toPer1			), 
	.add_cs_i 		(add_toPer1 		),	// [29:0]
	.data_cs_i 		(data_toPer1 		),
	.data_cs_o 		(data_fromPer1 		),

	// periphery ports - used for communication/control of cache
		.phase_o(phase_bus),
	.comm_cache0_i 	(comm_fromCache0	), 
	.comm_cache1_i 	(comm_fromCache1	),
	`ifdef MULTI_LEVEL_CACHE
	.comm_cacheL2_i (comm_fromCacheL2),
	`else 
	.comm_cacheL2_i (),
	`endif
	.metric_sel_o       (sel_cpc),
	.shift_sample_rate_o      (rate_shift_seed),

	.comm_o 		(comm_toCore		),
	.reset_system_o (cpu_system_reset)
);


endmodule
