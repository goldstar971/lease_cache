`timescale 1 ns / 1 ns

`include "top.h"

`define ITERATIONS 			100000 		// iterations to run
`define ADDRESS_LIMIT_BW  	16  		// 2**16 = 64kW = 256kB
`define BW_DATA_WORD 		32

module testbench;

// test hardware
// -----------------------------------------------------------

// drivers
reg 						clock_control_reg;
wire						clock_rw_bus;
reg 						resetn_reg;
reg 						core_request_reg;
reg 						core_wren_reg;
reg [`BW_DATA_WORD-1:0]		core_addr_reg;
reg [`BW_DATA_WORD-1:0]		core_data_reg;

// sinks
wire 						stall_flag;
wire 						core_valid_flag;
wire [`BW_DATA_WORD-1:0]	core_data_bus;

// hardware instantiation
top #(
	.BW_CORE_ADDR_BYTE 		(32 						), 	// byte addressible input address
	.BW_USED_ADDR_BYTE 		(26 						), 	// byte addressible converted address
	.BW_DATA_WORD 			(`BW_DATA_WORD 				), 	// bits in a data word
	.BW_DATA_EXTERNAL_BUS 	(512 						),	// bits that can be transfered between this level cache and next
	.BW_CACHE_COMMAND 		(`CACHE_CMD_BW 				), 	// command size for cache transactions
	.CACHE_WORDS_PER_BLOCK 	(16 						), 	// words in a block
	.CACHE_CAPACITY_BLOCKS 	(128 						), 	// cache capacity in blocks
	.CACHE_ASSOCIATIVITY 	(`ID_CACHE_FULLY_ASSOCIATIVE), 	// 0 = fully associative						
	.CACHE_POLICY 			(`ID_CACHE_FIFO 			),
	.BW_CONFIG_REGS 		(32 						),
	.BW_RAM_ADDR_WORD 		(`ADDRESS_LIMIT_BW 			) 	// testbench parameter				
) dut (
// generics
	.clock_control_i		(clock_control_reg 			),
	.clock_rw_i 			(clock_rw_bus 				),
	.resetn_i 				(resetn_reg 				),
	.stall_o 				(stall_flag 				),

	// drivers
	.core_request_i	 		(core_request_reg 			),	
	.core_wren_i	 		(core_wren_reg 				),
	.core_addr_i	 		(core_addr_reg 				),
	.core_data_i	 		(core_data_reg 				),

	// sinks
	.core_valid_o 			(core_valid_flag 			),
	.core_data_o 			(core_data_bus 				)
);


// clock generation
// ----------------------------------------------------------------------------------------------------------
always #10 clock_control_reg = ~clock_control_reg;
assign clock_rw_bus = ~clock_control_reg;


// testbench control sequence
// ----------------------------------------------------------------------------------------------------------

// driver signals
reg [`ADDRESS_LIMIT_BW-1:0] 	address_gen_reg;	
reg [`ADDRESS_LIMIT_BW-1:0] 	address_gen_fifo 	[0:7];
reg [`BW_DATA_WORD-1:0] 	data_check_fifo 	[0:7];
reg [2:0]						read_ptr_reg;
reg [2:0]						write_ptr_reg;
reg [`BW_DATA_WORD-1:0] 		mem_array 			[0:2**`ADDRESS_LIMIT_BW-1];
reg [`BW_DATA_WORD-1:0] 		check_data_reg;

// sink signals
reg [31:0]	counter_correct_reg,
			counter_wrong_reg;

integer i;

reg [1:0] 	coin_reg;
reg [31:0]	data_gen_reg;

reg gen_flag;

initial begin

	// initialize testbench
	// --------------------------------------------------------------------------------------

	// core signals
	core_wren_reg 		= 1'b0;
	core_addr_reg 		= 'b0;
	core_data_reg 		= 'b0;

	read_ptr_reg 		= 'b0;
	write_ptr_reg 		= 'b0;
	address_gen_reg 	= 'b0;
	counter_correct_reg = 'b0;
	counter_wrong_reg 	= 'b0;
	check_data_reg 		= 'b0;

	data_gen_reg 		= 'b0;
	coin_reg 			= 'b0;
	gen_flag 			= 1'b0;

	for (i = 0; i < 2**`ADDRESS_LIMIT_BW; i = i + 1) mem_array[i] = i[`ADDRESS_LIMIT_BW-1:0];
	for (i = 0; i < 8; i = i + 1) data_check_fifo[i] = 'b0;
	//address_gen_fifo[i] = 'b0;

	// reset hold
	clock_control_reg 	= 1'b0;
	resetn_reg  		= 1'b0;
	#100;

	// pull out of reset and begin driving hardware
	//@(posedge clock_control_reg);
	

	// testbench block
	// --------------------------------------------------------------------------------------
	repeat(`ITERATIONS) begin

		// core is posedge triggered so make all requests and verifications on this edge
		@(posedge clock_control_reg);
		resetn_reg  		= 1'b1;

		// generate request and write its contents to array
		if (!stall_flag)begin

			// request generation - read / or write
			coin_reg 						= $urandom() % 4;
			address_gen_reg 				= $urandom() % 2**`ADDRESS_LIMIT_BW; 		// generate random address between 0 and the limit

			/*gen_flag = 1'b0;
			while(!gen_flag) begin
				gen_flag = 1'b1;
				address_gen_reg 				= $urandom() % 2**`ADDRESS_LIMIT_BW;
				for (i = 0; i < 8; i = i + 1) begin
					if (address_gen_reg == address_gen_fifo[i]) gen_flag = 1'b0;
				end
			end*/

			// read
			if (coin_reg < 3) begin	
				data_check_fifo[write_ptr_reg] = mem_array[address_gen_reg];
				//address_gen_fifo[write_ptr_reg] = address_gen_reg;
				write_ptr_reg 					= write_ptr_reg + 1'b1;
				core_addr_reg 					= address_gen_reg << 2; 						// shift by two bc byte address get converted to word address
				core_request_reg 				= 1'b1;
				core_wren_reg 					= 1'b0;
			end
			else begin
				data_gen_reg  					= $urandom();
				mem_array[address_gen_reg] 		= data_gen_reg;
				core_wren_reg 					= 1'b1;
				core_addr_reg 					= address_gen_reg << 2; 						// shift by two bc byte address get converted to word address
				core_request_reg 				= 1'b1;
				core_data_reg 					= data_gen_reg;
			end
		end
		else begin
			core_request_reg 				= 1'b0;
			core_wren_reg 					= 1'b0;
		end

		// if cache returns a value check it
		if (core_valid_flag) begin

			// store to variable for testbench visualization
			//check_data_reg = mem_array[address_gen_fifo[read_ptr_reg]];
			check_data_reg = data_check_fifo[read_ptr_reg];

			if (core_data_bus != check_data_reg) begin
				counter_wrong_reg = counter_wrong_reg + 1;
				$display("Error %t", $time);
				#10;
				$stop;
			end
			else begin
				counter_correct_reg = counter_correct_reg + 1;
			end
			read_ptr_reg = read_ptr_reg + 1'b1;
		end
	end

	// testbench results
	$display("Correct:\t%d", counter_correct_reg);
	$display("Errors:\t%d", counter_wrong_reg);
	$stop;
end

endmodule