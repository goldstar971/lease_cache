// notes: run peripheral subsystem on same clock as core
// update peripherals on same edge that cache controller sees/services request

// addr[peripheral_bit] muxes requests to peripherals or cache
// internal cache state (registered peripheral bit) muxes the peripheral outputs to core

`include "top.h"

module pipeline_test(

	input 			clock_i,
	input 			reset_i,
	output 			flag_done_o
);

// control signals
wire 		bram_clock;
assign 		bram_clock = ~clock_i;

// embedded memory signals
wire [31:0]	hart_inst_data_i;
reg 		hart_inst_done_reg;
reg 		hart_inst_valid_reg;
wire 		hart_inst_req;
wire [31:0]	hart_inst_add;


reg 		hart_data_done_reg;
wire 		hart_data_req;
wire 		hart_data_rw;
wire [31:0]	hart_data_add;
wire [31:0]	hart_data_data_o;



// riscv core 
// ------------------------------------------------------------------------------------------------------------------------------
wire 		stall_bus;
wire [31:0]	hart_data_data_bus;
wire 		hart_data_valid_bus;

assign stall_bus = ~(hart_inst_done_reg & hart_data_done_reg);

riscv_hart_6stage_pipeline_2stage_cache hart_inst(

	// system
	.clock_i 		(clock_i 				),
	.reset_i 		(reset_i 		 		),
	.stall_i 		(stall_bus 				),

	// internal memory system (inst references)
	.inst_data_i 	(hart_inst_data_i		),  	// direct from $ memory
	.inst_valid_i 	(hart_inst_valid_reg	), 		// from controller
	.inst_req_o 	(hart_inst_req 			), 	 	//
	.inst_addr_o 	(hart_inst_add 			),  	//
	
	// internal memory system (data references)
	.data_data_i 	(hart_data_data_bus 	),  	// from switch
	.data_valid_i 	(hart_data_valid_bus	), 		// from switch
	.data_req_o 	(hart_data_req 			),  	//
	.data_wren_o 	(hart_data_rw 			), 		// 
	.data_addr_o 	(hart_data_add 			),  	//
	.data_data_o 	(hart_data_data_o 		) 		//
);




// data routing
// ------------------------------------------------------------------------------------------------------------------------------
wire 			per_req,
 				mem_req;
reg 			per_valid_reg,
				hart_data_valid_reg;
wire [31:0]		data_read_bus;
reg  [31:0]		per_data_reg;

memory_request_orderer #(
	.N_ENTRIES 			(4 					), 	// size of tracking buffer
	.BW_DATA 			(32 				),
	.BW_ADDR 			(32 				)
) data_request_handler (
	.clock_i			(!clock_i 			), 	// trigger for registering inputs
	.resetn_i 			(reset_i 			),
	.hart_request_i		(hart_data_req 		),
	.hart_wren_i 		(hart_data_rw 		),
	.hart_addr_i 		(hart_data_add 		),
	.hart_valid_o 		(hart_data_valid_bus),
	.hart_data_o 		(hart_data_data_bus	),

	.memory_request_o 	(mem_req 			),
	.memory_data_i		(data_read_bus 		),
	.memory_valid_i 	(hart_data_valid_reg),
	.io_request_o 		(per_req 			),
	.io_data_i 			(per_data_reg 		),
	.io_valid_i 		(per_valid_reg 		)
);


// artifical peripheral stuff
// ------------------------------------------------------------------------------------------------------------------------------

// end simulation condition - writing a '1' to M[0x04000104]
assign flag_done_o = (	per_req & 
						hart_data_rw & 
						(hart_data_data_o == 32'h00000001) & 
						(hart_data_add == 32'h04000104)
					);

always @(posedge clock_i) begin
	if (!reset_i) begin
		per_valid_reg 	<= 1'b0;
		per_data_reg 	<= 'b0;
	end
	else begin
		// defaults
		per_valid_reg 	<= 1'b0;

		if (per_req & !hart_data_rw) begin
			per_valid_reg 	<= 1'b1;
			per_data_reg 	<= 'b1; 	// unecessary for this
		end
	end
end

// instruction cache controller
// --------------------------------------------------------------------------------------
reg 		hart_inst_req_reg;
reg [31:0]	hart_inst_add_reg;

reg [31:0]	hart_inst_ref_trace;

always @(posedge clock_i) begin
	if (!reset_i) begin
		hart_inst_req_reg 			<= hart_inst_req;
		hart_inst_add_reg 			<= hart_inst_add;
		hart_inst_valid_reg 		<= 1'b0;
		hart_inst_done_reg 			<= 1'b1;
		hart_inst_ref_trace 		<= 'b0;
	end
	else begin
		// defaults
		hart_inst_valid_reg 		<= 1'b0;

		if (hart_inst_req) begin
			hart_inst_ref_trace 	<= hart_inst_ref_trace + 1'b1;
			hart_inst_req_reg 		<= hart_inst_req;
			hart_inst_add_reg 		<= hart_inst_add;
			hart_inst_valid_reg 	<= 1'b1;
		end
	end
end

// memory dummys (brams) - just checking for correct program evaluations
// memory file: test.mif
bram_32b_256kB inst_bram (
	.address 		(hart_inst_add_reg[17:2]	),
	.clock 			(bram_clock 				),
	.data 			('b0 						),
	.wren 			(1'b0 		 				),
	.q 				(hart_inst_data_i			)
);

// data cache controller
// --------------------------------------------------------------------------------------
reg 		hart_data_req_reg;
reg 		hart_data_rw_reg;
reg [31:0]	hart_data_add_reg;
reg [31:0]	hart_data_data_o_reg;

reg [31:0]	data_ref_trace_reg;

always @(posedge clock_i) begin
	if (!reset_i) begin

		data_ref_trace_reg 		<= 'b0;

		hart_data_req_reg 		<= 1'b0;
		hart_data_rw_reg	 	<= 1'b0;
		hart_data_add_reg 		<= 'b0;
		hart_data_data_o_reg 	<= 'b0;
		hart_data_valid_reg 	<= 1'b0;
		hart_data_done_reg 		<= 1'b1;
	end
	else begin
		// defaults
		hart_data_valid_reg 	<= 1'b0;

		// register inputs
		hart_data_req_reg 		<= mem_req;
		hart_data_rw_reg	 	<= hart_data_rw;
		hart_data_add_reg 		<= hart_data_add;
		hart_data_data_o_reg 	<= hart_data_data_o;

		// if a request for data then drive high
		if (mem_req & !hart_data_rw) 	hart_data_valid_reg <= 1'b1;

		if (mem_req) data_ref_trace_reg <= data_ref_trace_reg + 1'b1;
	end
end

// memory dummys (brams) - just checking for correct program evaluations
// memory file: test.mif

bram_32b_256kB data_bram (
	.address 		(hart_data_add_reg[17:2] 				),
	.clock 			(bram_clock 							),
	.data 			(hart_data_data_o_reg					),
	.wren 			(hart_data_rw_reg & hart_data_req_reg 	),
	.q 				(data_read_bus							)
);

endmodule