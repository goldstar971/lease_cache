
`include "riscv.h"

module top(

	input 			clock_i,
	input 			resetn_i, 	// core reset
	input 	[1:0]	pb_i, 		// pll reset
	output 	[2:0]	led_o

);


// pll clock [5,10,20,30,40,50]
//wire [5:0]	clock_gen_bus;
wire [2:0]	clock_gen_bus;
wire pll_locked;

/*test_pll pll_inst(
	.refclk			(clock_i			), 
	.rst 			(~pb_i[0] 			), 
	.outclk_0 		(clock_gen_bus[0] 	), 	// 5 Mhz
	.outclk_1 		(clock_gen_bus[1]	), 	// 10 Mhz
	.outclk_2 		(clock_gen_bus[2]	),  // 20 Mhz
	.outclk_3 		(clock_gen_bus[3]	),  // 30 Mhz
	.outclk_4 		(clock_gen_bus[4]	),  // 40 Mhz
	.outclk_5 		(clock_gen_bus[5]	),  // 50 Mhz
	.locked 		(pll_locked 		)
);*/

pll_speed_test pll_inst(
	.refclk			(clock_i			), 
	.rst 			(~pb_i[0] 			), 
	.outclk_0 		(clock_gen_bus[0] 	), 	// 20 Mhz
	.outclk_1 		(clock_gen_bus[1]	), 	// 20 Mhz - 180deg
	.outclk_2 		(clock_gen_bus[2]	),  // 20 Mhz - 270deg
	.locked 		(pll_locked 		)
);

assign led_o[0] = !pll_locked;

reg done_reg;
wire flag_done;

//assign led_o[1] = !done_reg;
//assign led_o[1] = !resetn_i;
assign led_o[1] = !pb_i[1] ;
assign led_o[2] = !done_reg;


always @(posedge clock_gen_bus[0]) begin
	if (!pb_i[1]) done_reg = 1'b0;
	else begin
		if (flag_done) done_reg = 1'b1;
	end
end

// riscv system
pipeline_test test_inst(

	// system
	.clock_i 		(clock_gen_bus[0] 	),
	.clock_mem_i 	(clock_gen_bus[2] 	),
	.reset_i 		(pb_i[1] 			),
	.flag_done_o 	(flag_done 			)	

);

endmodule