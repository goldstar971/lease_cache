module lru_line_controller #(
	parameter N_LOCATIONS = 0
)(
	input 						clock_i,
	input 						resetn_i,
	input 						enable_i,  					// so that in set associative caches the controller can be disabled
	input 	[BW_LOCATIONS-1:0] 	addr_i,
	input 						hit_i,
	input 						miss_i,
	output 						done_o,
	output 	[BW_LOCATIONS-1:0] 	addr_o
);

// parameterizations
// ----------------------------------------------------------------
localparam BW_LOCATIONS = `CLOG2(N_LOCATIONS);


// port mapping
// ----------------------------------------------------------------
reg 						done_reg;
reg [BW_LOCATIONS-1:0]		addr_reg;

assign done_o = done_reg;
assign addr_o = addr_reg;


// LRU registers and logic
// ----------------------------------------------------------------

integer i;
reg 	[BW_LOCATIONS-1:0] 	p_stack [0:N_LOCATIONS-1]; 			// stack of registers that point to the lines ordinal position
																// at the top is LRU position, bottom is MRU position
wire 	[BW_LOCATIONS-1:0] 	p_match;

assign p_match = p_stack[addr_i];

wire [N_LOCATIONS-1:0]		reduction_bits; 					// positions are ordinal so only one register and AND-REDUCE to logic high
																// thus the reduction of all registers in the stack is an encoding of the LRU
																// cache line
wire [BW_LOCATIONS-1:0]		replacement_encoding;

// generate reductions
genvar k;
generate
	for (k = 0; k < N_LOCATIONS; k = k + 1) begin : reps
		assign reduction_bits[k] = &p_stack[k];
	end
endgenerate

// encode reductions as an address
priority_encoder #(
	.INPUT_SIZE 	(N_LOCATIONS 			)
) p_encoder(
	.encoding_i 	(reduction_bits 		),
	.binary_o 		(replacement_encoding 	)
);


// LRU controller logic
// ----------------------------------------------------------------
reg [BW_LOCATIONS-1:0]	counter_reg;

always @(posedge clock_i) begin
	if (!resetn_i) begin
		counter_reg <= 'b0; 			// increments when allocating cold start cache lines
		done_reg 	<= 1'b0;
		addr_reg 	<= 'b0;
		for (i = 0; i < N_LOCATIONS; i = i + 1) p_stack[i] <= 'b0;
	end
	else begin

		// default signals
		done_reg <= 1'b1; 			// multicycle not needed to update/generate output

		if (enable_i) begin

			// on hit update stack
			// -------------------------------------------------
			if (hit_i) begin
				// go through entire stack, increment positions of every below the match
				// place the match at the bottom (bottom is MRU)
				for (i = 0; i < N_LOCATIONS; i = i + 1'b1) begin
					if (i == addr_i) begin
						p_stack[i] <= 'b0;
					end
					else if (p_stack[i] < p_match) begin
						p_stack[i] <= p_stack[i] + 1'b1;
					end
				end
			end

			// on miss determine replacement pointer
			// --------------------------------------------------
			if (miss_i) begin

				// if cache filled from cold start then evict LRU position
				if (&counter_reg) begin
					addr_reg 	<= replacement_encoding;
				end

				// if cache not yet filled from cold start then point to open spot
				else begin
					addr_reg 	<= counter_reg;
					counter_reg <= counter_reg + 1'b1;
					p_stack[counter_reg + 1'b1] <= counter_reg + 1'b1; 		// have to initialize stack location with its index
				end

			end
		end
	end
end


endmodule