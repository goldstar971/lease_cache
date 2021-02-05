`timescale 1 ns / 1 ns

`include "../include/top.h"

module testbench;


// testbench internal signals
// --------------------------------------------------------------------------------------------------------
reg 		clock_core_reg;
reg 		resetn_flag;
wire 		clock_write_flag;

wire 		io_request_flag,
			io_wren_flag;
wire [31:0]	io_addr_bus;
wire [31:0]	io_data_bus;


// test circuit
// --------------------------------------------------------------------------------------------------------
top #(
	.BW_CORE_ADDR_BYTE 		(32 						), 		// byte addressible input address
	.BW_USED_ADDR_BYTE 		(26 						), 		// byte addressible converted address
	.BW_DATA_WORD 			(`BW_DATA_WORD 				), 		// bits in a data word
	.BW_DATA_EXTERNAL_BUS 	(512 						),		// bits that can be transfered between this level cache and next
	.BW_CACHE_COMMAND 		(`CACHE_CMD_BW 				), 		// command size for cache transactions
	.CACHE_WORDS_PER_BLOCK 	(16 						), 		// words in a block
	.CACHE_CAPACITY_BLOCKS 	(128 						), 		// cache capacity in blocks
	.CACHE_ASSOCIATIVITY 	(`ID_CACHE_FULLY_ASSOCIATIVE), 		// 0 = fully associative						
	.CACHE_POLICY 			(`ID_CACHE_FIFO 			),
	.BW_CONFIG_REGS 		(32 						),
	.BW_RAM_ADDR_WORD 		(`ADDRESS_LIMIT_BW 			) 		// testbench parameter				
) dut (
	.clock_control_i 		(clock_core_reg 			), 		// core, level one cache controller, main memory arbiter controller
	.clock_rw_i 			(clock_write_flag 			), 		// buffer, tag lookup table, cache memory
	.resetn_i 				(resetn_flag 				),
	.io_request_o 			(io_request_flag 			), 		// i/o signal buses
	.io_wren_o 				(io_wren_flag 				),
	.io_addr_o 				(io_addr_bus 				),
	.io_data_o 				(io_data_bus 				),
	.io_valid_i 			(),
	.io_data_i 				()
);


// testbench control
// --------------------------------------------------------------------------------------------------------

// clock generation
always #10 clock_core_reg = ~clock_core_reg;
assign clock_write_flag = ~clock_core_reg;


// testbench sequencing
initial begin

	// reset condition
	clock_core_reg 	= 1'b0;
	resetn_flag 	= 1'b0;
	#100;

	// pull out of reset
	resetn_flag 	= 1'b1;

end

// termination control
always @(posedge io_request_flag) begin
	if (io_addr_bus == 32'h04000104) begin
		if (io_data_bus == 32'h00000001) begin
			#1000;
			$stop;
		end
	end
end


endmodule