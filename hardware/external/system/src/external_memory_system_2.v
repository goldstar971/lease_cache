`include "../../../include/mem.h"
module external_memory_system_2(

	// ddr3 ports
	output      [13:0]      ddr3b_a,
	output      [2:0]       ddr3b_ba,
	output                  ddr3b_casn,
	output                  ddr3b_clk_n,
	output                  ddr3b_clk_p,
	output                  ddr3b_cke,
	output                  ddr3b_csn,
	output      [7:0]       ddr3b_dm,
	output                  ddr3b_odt,
	output                  ddr3b_rasn,
	output                  ddr3b_resetn,
	output                  ddr3b_wen,
    inout       [63:0]      ddr3b_dq,
	inout       [7:0]       ddr3b_dqs_n,
	inout       [7:0]      	ddr3b_dqs_p,

	// termination, operation, and debugging pins
	output 		[3:0]		user_led,
	input 					clkin_r_p,
	input 					cpu_resetn,
	input 					rzqin_1_5v,
	output 		[1:0]		reset_bus_o,

	// internal system ports
	input 		[3:0] 		clock_bus_i, 		// 20 Mhz, 20 Mhz 180deg phase, 40 Mhz, 40 Mhz 180deg phase
	input 					int_req_i,
	input 					int_reqBlock_i,
	input 					int_rw_i,
	input 		[`BW_WORD_ADDR-1:0] 		int_add_i, 			// word addressible (512MB total)
	input 		[31:0]		int_data_i,
	input 					int_clear_i,
	output 					int_ready_o,
	output 					int_done_o,
	output 					int_valid_o,
	output 		[31:0]		int_data_o,

	// peripheral system ports - reduced bus
	output 					per_req_o,
	output 					per_rw_o,
	output 		[`BW_BYTE_ADDR:0]		per_add_o,
	output 		[31:0]		per_data_o,
	input 		[31:0]		per_data_i	
);

// reset controller
// ---------------------------------------
wire 	[2:0]		system_reset_bus;
wire 				req_reset;
wire 	[1:0]		config_reset;

reset_controller_v2 rst_cont0(
	.clock 			(clock_bus_i[0]		), 
	.reset_i 		(cpu_resetn 		), 
	.reset_bus_o 	(system_reset_bus 	), 
	.req_i 			(req_reset 			), 
	.config_i 		(config_reset 		) 
);

assign reset_bus_o = system_reset_bus[2:1];

// jtag-uart controller
// ---------------------------------------
wire 			ready_toCOMM, done_toCOMM, valid_toCOMM;
wire 	[31:0]	data_toCOMM, data_fromCOMM;
wire 	[2:0] 	reqdev_fromCOMM;
wire 			req_fromCOMM, reqBlock_fromCOMM, rw_fromCOMM, clear_fromCOMM;
wire 	[`BW_BYTE_ADDR:0]	add_fromCOMM;

//comm_controller comm_cont0(
uart_system_2 uart_inst0(
	.clock_bus_i 	({clock_bus_i[3:2],clock_bus_i[0]}),
	.resetn_i 		(cpu_resetn 		),
	.ready_i 		(ready_toCOMM 		), 
	.done_i 		(done_toCOMM 		), 
	.valid_i 		(valid_toCOMM 		),
	.data_i 		(data_toCOMM 		),
	.reqdev_o 		(reqdev_fromCOMM 	),
	.req_o 			(req_fromCOMM 		),
	.req_block_o 	(reqBlock_fromCOMM 	),
	.rw_o 			(rw_fromCOMM 		),
	.add_o 			(add_fromCOMM 		),					// addresses are byte addressible (64MB mem, above that are peripherals)
	.data_o 		(data_fromCOMM 		),
	.clear_o 		(clear_fromCOMM 	),
	.exception_o 	()
);

// DDR3 controller
// ---------------------------------------
wire 			ready_fromDDR, done_fromDDR, valid_fromDDR;
wire 	[31:0]	data_fromDDR, data_toDDR;
wire 			req_toDDR, reqBlock_toDDR, rw_toDDR, clear_toDDR;
wire 	[`BW_BYTE_ADDR:0]	add_toDDR;

ddr3_memory_controller #(.TEST_MODE(0)) ddr3_inst(

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
	.user_led 		(user_led			), 	// [3:0]
	.clkin_r_p 		(clkin_r_p			),
	.cpu_resetn 	(cpu_resetn			),
	.rzqin_1_5v 	(rzqin_1_5v			),

	// external ports
	.clock_ext_i 	(clock_bus_i[0] 	),
	.req_i 			(req_toDDR 			),
	.reqBlock_i 	(reqBlock_toDDR		),
	.rw_i 			(rw_toDDR 			),
	.add_i 			(add_toDDR			), 	// i/o conv. hardware handles address translation [`BW_BYTE_ADDR:0] -> [28:2]
	.data_i 		(data_toDDR 		),
	.clear_i 		(clear_toDDR 		),
	.ready_o 		(ready_fromDDR 		),
	.done_o 		(done_fromDDR 		),
	.valid_o 		(valid_fromDDR 		),
	.data_o 		(data_fromDDR 		)
);


// external memory controller
// ---------------------------------------
external_memory_controller ext_cont(

	// general i/o
	.clock_i 		(clock_bus_i[1] 	), 
	.reset_i 		(cpu_resetn 		),

	// comm system
	.req0_i 		(req_fromCOMM 		), 
	.reqBlock0_i 	(reqBlock_fromCOMM 	), 
	.rw0_i 			(rw_fromCOMM 		), 
	.clear0_i 		(clear_fromCOMM 	), 
	.dev0_i 		(reqdev_fromCOMM 	), 
	.data0_i 		(data_fromCOMM 		), 
	.add0_i 		(add_fromCOMM 		), 	// [`BW_BYTE_ADDR:0]
	.data0_o 		(data_toCOMM 		), 
	.ready0_o 		(ready_toCOMM 		), 
	.done0_o 		(done_toCOMM 		), 
	.valid0_o 		(valid_toCOMM 		),

	// reset controller
	.req1_o 		(req_reset 			), 
	.config1_o 		(config_reset 		),

	// external memory
	.req3_o 		(req_toDDR 			), 
	.reqBlock3_o 	(reqBlock_toDDR 	), 
	.rw3_o 			(rw_toDDR 			), 
	.clear3_o 		(clear_toDDR 		), 
	.data3_o 		(data_toDDR 		), 
	.add3_o 		(add_toDDR 			),	// [`BW_BYTE_ADDR:0]
	.data3_i 		(data_fromDDR 		), 
	.ready3_i 		(ready_fromDDR 		), 
	.done3_i 		(done_fromDDR 		), 
	.valid3_i 		(valid_fromDDR 		),

	// peripherals
	.req2_o 		(per_req_o 			), 
	.rw2_o 			(per_rw_o 			), 
	.add2_o 		(per_add_o 			), 
	.data2_o 		(per_data_o 		), 
	.data2_i 		(per_data_i 		),

	// processor system
	.req_int_i 		(int_req_i 			), 
	.reqBlock_int_i	(int_reqBlock_i 	), 
	.rw_int_i 		(int_rw_i 			), 
	.clear_int_i 	(int_clear_i 		),
	.data_int_i 	(int_data_i 		), 
	.add_int_i 		(int_add_i 			),  // [`BW_WORD_ADDR-1:0]
	.data_int_o 	(int_data_o			), 
	.ready_int_o 	(int_ready_o		), 
	.done_int_o 	(int_done_o			), 
	.valid_int_o 	(int_valid_o		)

);

endmodule