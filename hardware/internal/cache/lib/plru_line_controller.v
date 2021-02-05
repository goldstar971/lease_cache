module plru_line_controller #(
	parameter N_LOCATIONS = 0
)(
	input 						clock_i,
	input 						resetn_i,
	input 						miss_i,
	input 						enable_i, 		// if 1: update the tree nodes
	input 	[BW_LOCATIONS-1:0]	addr_i, 		// if enabled, update the tree nodes based on this address
	output 	[BW_LOCATIONS-1:0]	addr_o 			// if a replacement is needed 
);

// parameterizations
// ----------------------------------------------------------------
localparam BW_LOCATIONS = `CLOG2(N_LOCATIONS);
localparam NODES 		= N_LOCATIONS - 1;
localparam LAYERS 		= `CLOG2(N_LOCATIONS);


// node tree generation and replacement logic
// ----------------------------------------------------------------------------------
reg 	[NODES-1:0]	 		tree_nodes_reg;
wire 	[BW_LOCATIONS-1:0]	addr_rep_ptr;

wire 	[BW_LOCATIONS-1:0] 	addr_rep_index_ptrs [0:LAYERS-1];

reg 	[BW_LOCATIONS:0] 	cold_start_counter;

assign addr_o = (cold_start_done_reg) ? addr_rep_ptr : cold_start_counter[BW_LOCATIONS-1:0];
//assign addr_o = cold_start_counter[BW_LOCATIONS-1:0];

genvar k;
generate
	for (k = 0; k < LAYERS; k = k + 1) begin: plru_replacement_ptrs

		// index ptr assignment
		if (k == 0) begin
			assign addr_rep_index_ptrs[k] = {BW_LOCATIONS{1'b0}};
		end
		else begin
			// if k-1 node == 1: 2n+2 => next node
			// else 			 2n+1 => next node
			assign addr_rep_index_ptrs[k] = (addr_rep_index_ptrs[k-1] << 1) + 1'b1 + tree_nodes_reg[ addr_rep_index_ptrs[k-1] ];
		end

		// convert index to address
		assign addr_rep_ptr[BW_LOCATIONS-1-k] = tree_nodes_reg[ addr_rep_index_ptrs[k] ];
	end
endgenerate


// node update logic (upon a reference and enabled)
// ----------------------------------------------------------------------------------
wire [BW_LOCATIONS-1:0]	update_index_ptrs [0:LAYERS-1];

// index = 0: nodes[0]
// index = 1: nodes[2:1]
// index = 2: nodes[6:3]
// etc.

assign update_index_ptrs[0] = {BW_LOCATIONS{1'b0}}; 	// always update the first tree node

genvar j;
generate
	for (j = LAYERS-1; j > 0; j = j - 1) begin: plru_update_ptrs 
		if (j == LAYERS-1) begin
			assign update_index_ptrs[j] = addr_i[LAYERS-1:1] + (1'b1 << (LAYERS-1)) - 1'b1;
		end
		else begin
			assign update_index_ptrs[j] = ((update_index_ptrs[j+1] - 1'b1) >> 1);
		end
	end
endgenerate

// make sure to fill up the cache first
reg cold_start_done_reg;

integer i;
always @(posedge clock_i) begin
	// reset state
	if (!resetn_i) begin
		tree_nodes_reg 		<= 'b0;
		cold_start_counter 	<= {BW_LOCATIONS{1'b1}}; // will roll over upon first miss
		cold_start_done_reg <= 1'b0;
	end
	// active sequencing
	else begin

		if (miss_i) begin
			cold_start_counter = cold_start_counter + 1'b1;
			if (cold_start_counter[BW_LOCATIONS]) cold_start_done_reg = 1'b1;
		end

		// only if enabled to update
		if ((enable_i) & (cold_start_done_reg)) begin

			// logic for an update is as follows...
			// nodes along the path from node0 to the referenced block are:
			// 	- keep the same if not pointing to the block
			//	- inverted if pointing to the block
			for (i = 0; i < LAYERS; i = i + 1) begin
				if (addr_i[BW_LOCATIONS-1-i] == tree_nodes_reg[ update_index_ptrs[i] ]) begin
					tree_nodes_reg[ update_index_ptrs[i] ] <= ~tree_nodes_reg[ update_index_ptrs[i] ];
				end
			end

		end
	end
end

endmodule
