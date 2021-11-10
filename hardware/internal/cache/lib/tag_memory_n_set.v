
module tag_memory_n_set #(
	// configurables
	parameter   CACHE_SET_SIZE=64,
	parameter 	CACHE_BLOCK_CAPACITY = 128
	// derived - cannot localparam due to shit verilog standards
)(
	input 						clock_i, 	// write edge
	input 						resetn_i, 	// reset active low 		
	input 						wren_i, 	// write enable (write new entry)
	input    [BW_SET-1:0]    set_i,	
	input 	[BW_TAG-1:0]		tag_i, 		// primary input (tag -> cache location)
	input 	[BW_CACHE_CAPACITY-1:0]	add_i, 		// add -> tag (part of absolute memory address) - used for replacement
	output	[BW_CACHE_CAPACITY-1:0]	add_o, 		// primary output (cache location <- tag)
	output 	[BW_TAG-1:0]		tag_o,		// tag <- add
	output 						hit_o 		// logic high if lookup hit
);

// parameterizations
// ----------------------------------------------------------------------------------
localparam BW_CACHE_CAPACITY 	= `CLOG2(CACHE_BLOCK_CAPACITY); // block addressible cache addresses
localparam BW_GRP 				=`CLOG2(CACHE_SET_SIZE);				
localparam BW_SET 				=BW_CACHE_CAPACITY-BW_GRP;
localparam BW_TAG 			= `BW_WORD_ADDR - BW_SET - `BW_BLOCK;
localparam N_GROUPS             = 2**BW_GRP;
localparam N_SET               = 2**BW_SET;



// internal memories
// -----------------------------------------------------------------------------------------------
reg 	[BW_TAG-1:0]				tag_mem 		[0:N_SET-1][0:N_GROUPS-1];	 	// where block tags are stored
reg			validbits_reg_2d  [0:N_SET-1][N_GROUPS-1:0];									// high if tag has been written into tag memory
wire 	[BW_GRP-1:0] add_reg;  										// address passed from tag -> addr lookup

//get set and grp value
integer i,t;
//nway
generate if (N_SET!=1)begin
	wire[BW_CACHE_CAPACITY-BW_GRP-1:0] set_val=add_i[BW_CACHE_CAPACITY-BW_GRP-1:0];
	wire[BW_CACHE_CAPACITY-BW_SET-1:0] grp_val=add_i[BW_CACHE_CAPACITY-1:BW_SET];
	assign add_o = {add_reg,set_i};
end
//fully associative
else begin
	wire[BW_CACHE_CAPACITY-BW_SET-1:0] grp_val=add_i[BW_CACHE_CAPACITY-1:0];
	wire set_val=1'b0;
	 assign add_o = add_reg; 
end
endgenerate

// port mappings
// -----------------------------------------------------------------------------------------------
assign tag_o = tag_mem[set_val][grp_val];


// tag -> address decoding (asynchronous - combinational)
// -----------------------------------------------------------------------------------------------

// comparator array that produces matchbits
genvar j,h;
integer k;
generate 
		//this is a hacky way to refer to an entire set because you can't slice into 2d arrays directly
	wire  [N_GROUPS-1:0]      set_matchbits,set_validbits_reg;
		for (j = 0; j < N_GROUPS; j = j + 1'b1) begin : tag_comparator_array
			identity_comparator #(.BW(BW_TAG)) comp_inst(tag_i, tag_mem[set_i][j], set_matchbits[j]);
			assign set_validbits_reg[j]=validbits_reg_2d[set_i][j];
		end
		priority_encoder lease_rep_encoder(.clk(),.rst(),.oht(set_validbits_reg&set_matchbits),.bin(add_reg),.vld(hit_o));

endgenerate

// tag -> add search out



// write and remove control logic (synchronous)
// -----------------------------------------------------------------------------------------------


always @(posedge clock_i) begin
	// reset condition
	if (resetn_i != 1'b1) begin
		for (i = 0; i < N_SET; i = i + 1'b1) begin
			for (t=0;t<N_GROUPS; t=t+1'b1) begin
				validbits_reg_2d[i][t]=1'b0;
				tag_mem[i][t] = 'b0;
			end
		end
	end
	// active sequencing
	else begin
		if (wren_i == 1'b1) begin
			tag_mem[set_val][grp_val] = tag_i;
			validbits_reg_2d[set_val][grp_val] = 1'b1;
		end
	end
end

endmodule