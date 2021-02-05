`include "../include/top.h"

module top(

	input 	[`TEST_BW_DATA-1:0] 	data_i,
	input 	[`TEST_BW_SHIFT-1:0] 	shift_i,
	output	[`TEST_BW_DATA-1:0] 	data_o

);

barrel_shifter #(
	.BW_DATA 		(`TEST_BW_DATA 		)
) top_inst (
	.data_i 		(data_i 			),
	.shift_i 		(shift_i 			),
	.data_o 		(data_o 			)
);

endmodule