`timescale 1 ns / 1 ns

`include "../include/top.h"

`define ITERATIONS 10

module test;

// testbench signals
reg 	[`TEST_BW_DATA-1:0] 	data_reg;
reg 	[`TEST_BW_SHIFT-1:0] 	shift_reg;
wire 	[`TEST_BW_DATA-1:0] 	data_bus;

// test hardware
top top_inst(
	.data_i	 	(data_reg 		),
	.shift_i 	(shift_reg 		),
	.data_o 	(data_bus 	 	)
);


// testbench sequence
integer iterations_reg;

initial begin
	iterations_reg 	= 'b0;
	data_reg 		= 'b0;
	shift_reg 		= 'b0;
	#100;

	// write data, pause, examine, check
	while(iterations_reg < `ITERATIONS) begin
		data_reg 		= 1'b1 << ($urandom % 2**`TEST_BW_SHIFT);
		//data_reg 		= $urandom % 2**`TEST_BW_DATA;
		shift_reg 		= $urandom % 2**`TEST_BW_SHIFT;
		#40;
		iterations_reg 	= iterations_reg + 1'b1;
	end

	$stop;

end



endmodule