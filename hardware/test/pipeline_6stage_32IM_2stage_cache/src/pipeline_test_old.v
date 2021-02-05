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
wire 		hart_inst_done;
wire 		hart_inst_req;
wire [31:0]	hart_inst_add;

wire [31:0]	hart_data_data_i;
wire 		hart_data_done;
reg 		hart_data_valid_reg,
			hart_inst_valid_reg;
wire 		hart_data_req;
wire 		hart_data_rw;
wire [31:0]	hart_data_add;
wire [31:0]	hart_data_data_o;

assign hart_inst_done = 1'b1;


wire 		per_rw;
wire [31:0]	per_add, per_data_o;
assign flag_done_o = ((per_add == 32'h04000104) & (per_rw) & (per_data_o == 32'h00000001)) ? 1'b1: 1'b0;


// riscv core 
// --------------------------------------------------------
riscv_hart_6stage_pipeline_2stage_cache hart_inst(

	// system
	.clock_i 		(clock_i 			),
	.reset_i 		(reset_i 		 	),

	// internal memory system (inst references)
	.inst_data_i 	(hart_inst_data_i	), 
	.inst_done_i 	(hart_inst_done 	),
	.inst_valid_i 	(hart_inst_valid_reg),
	.inst_req_o 	(hart_inst_req 		), 	
	.inst_addr_o 	(hart_inst_add 		), 
	
	// internal memory system (data references)
	.data_data_i 	(hart_data_data_i 	), 
	.data_done_i 	(hart_data_done 	),
	.data_valid_i 	(hart_data_valid_reg),
	.data_req_o 	(hart_data_req 		), 
	.data_wren_o 	(hart_data_rw 		),
	.data_addr_o 	(hart_data_add 		), 
	.data_data_o 	(hart_data_data_o 	)
);



// register the inputs for a synthetic stage delay
reg 		hart_inst_req_reg;
reg [31:0]	hart_inst_add_reg;


/*`ifndef SAFE
	wire 		hart_data_req_reg;
	wire 		hart_data_rw_reg;
	wire [31:0]	hart_data_add_reg;
	wire [31:0]	hart_data_data_o_reg;

	assign 	hart_data_req_reg 		= hart_data_req;
	assign 	hart_data_rw_reg	 	= hart_data_rw;
	assign 	hart_data_add_reg 		= hart_data_add;
	assign	hart_data_data_o_reg 	= hart_data_data_o;
`else*/ 
	reg 		hart_data_req_reg;
	reg 		hart_data_rw_reg;
	reg [31:0]	hart_data_add_reg;
	reg [31:0]	hart_data_data_o_reg;

//`endif


reg [31:0]	data_ref_trace_reg;

always @(posedge clock_i) begin
	if (!reset_i) begin
		hart_inst_req_reg 		<= hart_inst_req;
		hart_inst_add_reg 		<= hart_inst_add;

		data_ref_trace_reg 		<= 'b0;

//`ifdef SAFE
		hart_data_req_reg 		<= 1'b0;
		hart_data_rw_reg	 	<= 1'b0;
		hart_data_add_reg 		<= 'b0;
		hart_data_data_o_reg 	<= 'b0;
//`endif

		hart_data_valid_reg <= 1'b0;
		hart_inst_valid_reg <= 1'b0;
	end
	else begin

		// default
		hart_data_valid_reg <= 1'b0;
		hart_inst_valid_reg <= 1'b0;

		if (hart_inst_req) begin
			hart_inst_req_reg 		<= hart_inst_req;
			hart_inst_add_reg 		<= hart_inst_add;
		end

		if (hart_data_req) data_ref_trace_reg <= data_ref_trace_reg + 1'b1;


//`ifdef SAFE
		if (hart_data_req) begin
			hart_data_req_reg 		<= hart_data_req;
			hart_data_rw_reg	 	<= hart_data_rw;
			hart_data_add_reg 		<= hart_data_add;
			hart_data_data_o_reg 	<= hart_data_data_o;
		end
//`endif

		if (hart_inst_req) 					hart_inst_valid_reg <= 1'b1; 
		if (hart_data_req & !hart_data_rw) 	hart_data_valid_reg <= 1'b1;

	end
end



wire 		mem_req, mem_rw, mem_done;
wire [31:0]	mem_addr, mem_data_read, mem_data_write;

assign mem_done = 1'b1;


port_switch peripheral_switch_inst(

	// core/hart ports
	.core_req_i 	(hart_data_req_reg 		),
	.core_wren_i 	(hart_data_rw_reg 		),
	.core_addr_i 	(hart_data_add_reg 		),
	.core_data_i 	(hart_data_data_o_reg 	),
	.core_done_o 	(hart_data_done 		),
	.core_data_o 	(hart_data_data_i 		),

	// internal memory ports
	.memory_done_i 	(mem_done 			),
	.memory_data_i 	(mem_data_read 		),
	.memory_req_o 	(mem_req 			),
	.memory_wren_o 	(mem_rw 			),
	.memory_addr_o 	(mem_addr 			),
	.memory_data_o 	(mem_data_write 	),

	// peripheral ports
	.peripheral_data_i	('b0		 	),
	.peripheral_req_o 	(),
	.peripheral_wren_o 	(per_rw 		),
	.peripheral_addr_o 	(per_add 		),
	.peripheral_data_o 	(per_data_o 	)	

);


// memory dummys (brams) - just checking for correct program evaluations
// memory file: test.mif
bram_32b_256kB inst_bram (
`ifndef SAFE
	.address 		(hart_inst_add_reg[17:2]	),
`else
	.address 		(hart_inst_add[17:2]		),
`endif
	.clock 			(bram_clock 				),
	.data 			('b0 						),
	.wren 			(1'b0 		 				),
	.q 				(hart_inst_data_i			)
);
bram_32b_256kB data_bram (
	.address 		(mem_addr[17:2] 			),
	.clock 			(bram_clock 				),
	.data 			(mem_data_write				),
	.wren 			(mem_rw 					),
	.q 				(mem_data_read				)
);



/*bram_32b_256kB inst_bram (
	.address 		(hart_inst_add[17:2]),
	.clock 			(bram_clock 		),
	.data 			('b0 				),
	.wren 			(1'b0 		 		),
	.q 				(hart_inst_data_i	)
);*/
/*bram_32b_256kB data_bram (
	.address 		(mem_addr[17:2] 	),
	.clock 			(bram_clock 		),
	.data 			(mem_data_write		),
	.wren 			(mem_rw 			),
	.q 				(hart_data_data_i		)
);*/

endmodule