module lease_probability_controller #(
	parameter BW_LEASE_VALUE = 0
)(
	input 							clock_i,
	input 							resetn_i,
	input 							enable_i,
	input 	[BW_LEASE_VALUE-1:0] 	lease0_i,
	input 	[BW_LEASE_VALUE-1:0]	lease1_i,
	input 	[`BW_PERCENTAGE-1:0]		lease0_prob_i,
	output	[BW_LEASE_VALUE-1:0]	lease_o
);

// LFSR to generate random number
// -----------------------------------------------------------------------------
wire 	[8:0] 	val_lfsr;
linear_shift_register_9b #(
	.SEED 			(9'b101010101 		) 		
) lfsr_inst (
	.clock_i 		(clock_i 			), 
	.resetn_i 		(resetn_i 			), 
	.enable_i 		(enable_i 			), 
	.result_o 		(val_lfsr 			)
);


// comparator logic
// -----------------------------------------------------------------------------
// first condition is that the lfsr seed must be greater than the probability discretization
assign lease_o = (val_lfsr > lease0_prob_i) ? lease1_i : lease0_i;


endmodule