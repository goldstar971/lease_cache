module cache_performance_controller #(
	parameter CACHE_STRUCTURE 	=  	"",
	parameter CACHE_REPLACEMENT = 	""
)(
	input 			clock_i,
	input 			resetn_i,
	input 			hit_i, 				// logic high when there is a cache hit
	input 			miss_i, 			// logic high when there is the initial cache miss
	input 			writeback_i, 		// logic high when the cache writes a block back to externa memory
	input 			expired_i,			// logic high when lease cache replaces an expired block
	input 			expired_multi_i, 	// logic high when multiple cache lines are expired
	input 			defaulted_i, 		// logic high when lease cache renews using a default lease value
	input 	[31:0]	comm_i, 			// configuration signal
	output 	[31:0] 	comm_o 	 			// return value of comm_i
);

// cache performance controller 
// ------------------------------------------------------------------------------
reg 	[31:0]	comm_o_reg;
reg 	[63:0]	counter_walltime_reg,	// when enabled counts "wall time" - actually it counts cycles
				counter_hit_reg,  		// when enabled counts times hit_i is logic high
				counter_miss_reg, 		// when enabled counts times miss_i is logic high
				counter_wb_reg, 		// when enabled counts times writeback_i is logic high
				counter_expired_reg, 	// counts times expired_i is logic high
				counter_mexpired_reg, 	// counts times multi_expired_i is logic high
				counter_defaulted_reg; 	// counts times defaulted_i is logic high

assign comm_o = comm_o_reg;

always @(posedge clock_i) begin
	// reset state
	if (resetn_i != 1'b1) begin
		comm_o_reg 				<= 'b0; 				// no configuration given by comm_i so just set return val reg to zero
		counter_hit_reg 		<= 'b0; 
		counter_miss_reg 		<= 'b0; 
		counter_wb_reg 			<= 'b0; 
		counter_walltime_reg 	<= 'b0;
		counter_expired_reg 	<= 'b0;
		counter_mexpired_reg 	<= 'b0;
		counter_defaulted_reg 	<= 'b0;
	end
	// active state
	else begin

		// if enabled then upcount depending on flag thrown by cache
		if (comm_i[24] == 1'b1) begin
			if 		(hit_i) 			counter_hit_reg 		<= counter_hit_reg + 1'b1;
			if 		(miss_i) 			counter_miss_reg 		<= counter_miss_reg + 1'b1;
			if 		(writeback_i) 		counter_wb_reg 			<= counter_wb_reg + 1'b1;
			if 		(expired_i) 		counter_expired_reg 	<= counter_expired_reg + 1'b1;
			if 		(expired_multi_i) 	counter_mexpired_reg 	<= counter_mexpired_reg + 1'b1;
			if 		(defaulted_i) 		counter_defaulted_reg 	<= counter_defaulted_reg + 1'b1;

			// always increment wall-timer
			counter_walltime_reg <= counter_walltime_reg + 1'b1;
		end

		// return value control
		// -------------------------------------------------------------------------
		case (comm_i[3:0])

			// primary outputs
			4'b0000: comm_o_reg <= counter_hit_reg[31:0];				// hits
			4'b0001: comm_o_reg <= counter_hit_reg[63:32];
			4'b0010: comm_o_reg <= counter_miss_reg[31:0]; 				// misses
			4'b0011: comm_o_reg <= counter_miss_reg[63:32];
			4'b0100: comm_o_reg <= counter_wb_reg[31:0]; 				// writebacks
			4'b0101: comm_o_reg <= counter_wb_reg[63:32];
			4'b0110: comm_o_reg <= counter_walltime_reg[31:0]; 			// duration (cycles)
			4'b0111: comm_o_reg <= counter_walltime_reg[63:32];
			4'b1000: comm_o_reg <= counter_expired_reg[31:0]; 			// expired lease replacements
			4'b1001: comm_o_reg <= counter_expired_reg[63:32];
			4'b1010: comm_o_reg <= counter_defaulted_reg[31:0]; 		// defaulted lease renewals
			4'b1011: comm_o_reg <= counter_defaulted_reg[63:32];
			4'b1100: comm_o_reg <= counter_mexpired_reg[31:0]; 			// multiple leases expired at eviction
			4'b1101: comm_o_reg <= counter_mexpired_reg[63:32];

			// cache identification
			4'b1111: comm_o_reg <= CACHE_STRUCTURE | CACHE_REPLACEMENT;

			default comm_o_reg <= 'b0;
		endcase

	end
end

endmodule