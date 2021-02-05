module cache_performance_controller_tracker_2 #(
	parameter CACHE_STRUCTURE 	=  	"",
	parameter CACHE_REPLACEMENT = 	""
)(
	input 			clock_i, 				// 90deg
	input 			clock_memory_i, 		// 180deg
	input 			resetn_i,
	input 			request_i,
	input 			hit_i, 				// logic high when there is a cache hit
	input 			miss_i, 			// logic high when there is the initial cache miss
	input 			writeback_i, 		// logic high when the cache writes a block back to externa memory
	input 			expired_i,			// logic high when lease cache replaces an expired block
	input 			expired_multi_i, 	// logic high when multiple cache lines are expired
	input 			defaulted_i, 		// logic high when lease cache renews using a default lease value
	input 	[31:0]	comm_i, 			// configuration signal
	output 	[31:0] 	comm_o, 	 		// return value of comm_i
	//input 	[127:0]	expired_flags_i,
	input 	[127:0]	expired_flags_0_i,
	input 	[127:0]	expired_flags_1_i,
	input 	[127:0]	expired_flags_2_i,
	output 			stall_o
);

// cache performance controller 
// ------------------------------------------------------------------------------
reg 	[31:0]	comm_o_reg;

//wire 	[127:0]	eviction_bit_bus;
wire 	[127:0]	eviction_bit_0_bus,
				eviction_bit_1_bus,
				eviction_bit_2_bus;


wire 	[127:0]	trace_bus;
wire 	[31:0]	count_bus;

reg 	[63:0]	n_hits_reg;

assign comm_o = comm_o_reg;

always @(posedge clock_memory_i) begin
	// reset state
	if (resetn_i != 1'b1) begin
		comm_o_reg 				<= 'b0; 				// no configuration given by comm_i so just set return val reg to zero
		n_hits_reg 				<= 'b0;
	end
	// active state
	else begin

		if (comm_i[24]) begin
			if (hit_i) n_hits_reg <= n_hits_reg + 1'b1;
		end

		// return value control
		// -------------------------------------------------------------------------
		//case (comm_i[3:0])

			// primary outputs
			/*4'b0000: comm_o_reg <= eviction_bit_bus[31:0];
			4'b0001: comm_o_reg <= eviction_bit_bus[63:32];
			4'b0010: comm_o_reg <= eviction_bit_bus[95:64];
			4'b0011: comm_o_reg <= eviction_bit_bus[127:96];

			4'b0100: comm_o_reg <= trace_bus[31:0];
			4'b0101: comm_o_reg <= trace_bus[63:32];
			4'b0110: comm_o_reg <= trace_bus[95:64];
			4'b0111: comm_o_reg <= trace_bus[127:96];

			4'b1000: comm_o_reg <= count_bus;
			4'b1111: comm_o_reg <= {{31'b0},stall_o}; 				// analygous to full flag

			4'b1001: comm_o_reg <= n_hits_reg[31:0]; 				// roughly total references
			4'b1010: comm_o_reg <= n_hits_reg[63:32];*/

			//default comm_o_reg 	<= 'b0;
		//endcase

		case(comm_i[4:0])

			5'b00000: 	comm_o_reg <= eviction_bit_0_bus[31:0];
			5'b00001:	comm_o_reg <= eviction_bit_0_bus[63:32];
			5'b00010:	comm_o_reg <= eviction_bit_0_bus[95:64];
			5'b00011:	comm_o_reg <= eviction_bit_0_bus[127:96];

			5'b00100: 	comm_o_reg <= eviction_bit_1_bus[31:0];
			5'b00101:	comm_o_reg <= eviction_bit_1_bus[63:32];
			5'b00110:	comm_o_reg <= eviction_bit_1_bus[95:64];
			5'b00111:	comm_o_reg <= eviction_bit_1_bus[127:96];

			5'b01000: 	comm_o_reg <= eviction_bit_2_bus[31:0];
			5'b01001:	comm_o_reg <= eviction_bit_2_bus[63:32];
			5'b01010:	comm_o_reg <= eviction_bit_2_bus[95:64];
			5'b01011:	comm_o_reg <= eviction_bit_2_bus[127:96];

			5'b01100: 	comm_o_reg <= trace_bus[31:0];
			5'b01101:	comm_o_reg <= trace_bus[63:32];
			5'b01110:	comm_o_reg <= trace_bus[95:64];
			5'b01111:	comm_o_reg <= trace_bus[127:96];

			5'b10000: 	comm_o_reg <= count_bus;
			5'b10001: 	comm_o_reg <= {{31'b0},stall_o};
			5'b10010: 	comm_o_reg <= n_hits_reg[31:0];
			5'b10011: 	comm_o_reg <= n_hits_reg[63:32];

			default: 	comm_o_reg <= 'b0;

		endcase
	end
end

cache_line_tracker_2 #(
	.FS 				(256 					),
	.N_LINES 	 		(128 					)
) tracker_inst (
	.clock_i  			(clock_i				), 		// phase = 90 deg		
	.clock_memory_i 	(clock_memory_i			), 	 	// phase = 180 deg
	.resetn_i 			(resetn_i 				),
	.config_i 			(comm_i 				), 		
	.request_i 			(request_i 				),

	//.expired_bits_i 	(expired_flags_i 		),
	.expired_bits_0_i 	(expired_flags_0_i 		),
	.expired_bits_1_i 	(expired_flags_1_i 		),
	.expired_bits_2_i 	(expired_flags_2_i 		),

	.stall_o 			(stall_o 				),
	.count_o 			(count_bus 				),	 			
	.trace_o 			(trace_bus 				),

	//.expired_bits_o 	(eviction_bit_bus 		)	
	.expired_bits_0_o 	(eviction_bit_0_bus 	),
	.expired_bits_1_o 	(eviction_bit_1_bus 	),
	.expired_bits_2_o 	(eviction_bit_2_bus 	)

);

endmodule