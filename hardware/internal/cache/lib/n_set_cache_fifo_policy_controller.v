// cache address in the following form
//
// 		[set | group]
//

module n_set_cache_fifo_policy_controller #(
	parameter CACHE_BLOCK_CAPACITY 	= 0,
	parameter CACHE_SET_SIZE 		= 0 				// 2: two-way
														// 4: four-way
														// 8: eight-way
)(
	input 								clock_i,
	input 								resetn_i,
	input 								miss_i, 		// pulse trigger to generate a replacement address
	input 	[BW_GRP-1:0]				set_i, 		// group of the block/reference trying to allocate in cache
	output 								done_o, 		// logic high when replacement address generated
	output 	[BW_CACHE_CAPACITY-1:0] 	addr_o 			// replacement address generated
);


// parameterizations
// ------------------------------------------------------------------------------------------
localparam BW_CACHE_CAPACITY 	= `CLOG2(CACHE_BLOCK_CAPACITY); 				// block addressible cache addresses
localparam BW_FIFO 				= `CLOG2(CACHE_SET_SIZE);
localparam N_FIFO 				= CACHE_BLOCK_CAPACITY / CACHE_SET_SIZE;
localparam BW_SET 				=BW_CACHE_CAPACITY-`CLOG2(CACHE_SET_SIZE);				
localparam BW_GRP 				= 	BW_CACHE_CAPACITY-BW_SET;
localparam N_SET                =2**BW_SET;

// replacement controller
//  ------------------------------------------------------------------------------------------
reg 								done_reg;
reg 	[BW_CACHE_CAPACITY-1:0] 	addr_reg; 					// block addressible (set|group)

assign done_o = done_reg;
assign addr_o = addr_reg;

generate if (N_SET!=1) begin

	reg 	[BW_FIFO-1:0]	 			set_fifos	[0:N_FIFO-1];	// one fifo counter for each set line
	integer i;

	always @(posedge clock_i) begin

		// reset state
		// ---------------------------------------------------------------------------------------
		if (!resetn_i) begin
			for (i = 0; i < N_FIFO; i = i + 1) set_fifos[i] <= 'b0;
			done_reg <= 1'b0;
			addr_reg <= 'b0;
		end

		// active sequencing
		// ---------------------------------------------------------------------------------------
		else begin
			// only trigger controller on a miss
			if (miss_i) begin
				
				// set the replacement ptr to where the set fifo counter is pointing
				addr_reg <= {set_fifos[set_i],set_i };
				done_reg <= 1'b1;

				// point to next location
				set_fifos[set_i] <= set_fifos[set_i] + 1'b1;
			end
		end
	end

end 
else begin

	reg 	[BW_FIFO-1:0]	 			set_fifos;	// one fifo counter for each set line

	always @(posedge clock_i) begin

		// reset state
		// ---------------------------------------------------------------------------------------
		if (!resetn_i) begin
			set_fifos <= 'b0;
			done_reg <= 1'b0;
			addr_reg <= 'b0;
		end

		// active sequencing
		// ---------------------------------------------------------------------------------------
		else begin
			// only trigger controller on a miss
			if (miss_i) begin
				
				// set the replacement ptr to where the set fifo counter is pointing
				addr_reg <= set_fifos;
				done_reg <= 1'b1;

				// point to next location
				set_fifos <= set_fifos + 1'b1;
			end
		end
	end

end
endgenerate

endmodule 