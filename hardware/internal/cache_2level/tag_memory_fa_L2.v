module tag_memory_fa_L2 #(
	// configurables
	parameter 	CACHE_BLOCK_CAPACITY = 128,
	// derived - cannot localparam due to shit verilog standards
	parameter 	BW_CACHE_ADDR = `CLOG2(CACHE_BLOCK_CAPACITY),
	parameter 	BW_TAG = `BW_WORD_ADDR - `BW_BLOCK
)(
	input 	[1:0]					clock_bus_i, 	//read and write edge
	input 						resetn_i, 	// reset active low 		
	input 						wren_i, 	// write enable (write new entry)
	input 						rmen_i, 	// remove enable (invalidate entry) 	
	input 	[BW_TAG-1:0]		tag_i, 		// primary input (tag -> cache location)
	input 	[BW_CACHE_ADDR-1:0]	add_i, 		// add -> tag (part of absolute memory address) - used for replacement
	output	[BW_CACHE_ADDR-1:0]	add_o, 		// primary output (cache location <- tag)
	output 	[BW_TAG-1:0]		tag_o,		// tag <- add
	output 						hit_o 		// logic high if lookup hit
);

// internal memories
// -----------------------------------------------------------------------------------------------
reg 	[BW_TAG-1:0]				tag_mem 		[0:CACHE_BLOCK_CAPACITY-1];	 	// where block tags are stored
wire 	[CACHE_BLOCK_CAPACITY-1:0]	matchbits;										// high if there is a match
reg		[CACHE_BLOCK_CAPACITY-1:0]	validbits_reg;									// high if tag has been written into tag memory
reg 	[BW_CACHE_ADDR-1:0]			add_reg; 										// address passed from tag -> addr lookup
wire [BW_CACHE_ADDR-1:0]            match_index;
wire match;
reg match_reg;
reg [BW_CACHE_ADDR-1:0] match_index_reg;

always@(posedge clock_bus_i[0])begin
	if(!resetn_i)begin
		match_index_reg<={BW_CACHE_ADDR-1{1'b0}};
		match_reg<=1'b0;
	end
	else begin
	match_index_reg<=match_index;
	match_reg<=match;
end

end

// port mappings
// -----------------------------------------------------------------------------------------------
assign hit_o = match_reg;
assign add_o = match_index_reg;
assign tag_o = tag_mem[add_i];


// tag -> address decoding (asynchronous - combinational)
// -----------------------------------------------------------------------------------------------

// comparator array that produces matchbits
genvar j;
generate 
	for (j = 0; j < CACHE_BLOCK_CAPACITY; j = j + 1'b1) begin : tag_comparator_array
		identity_comparator #(.BW(BW_TAG)) comp_inst(tag_i, tag_mem[j], matchbits[j]);
	
	end
endgenerate

tag_match_encoder_9b tag_match(.match_bits(matchbits&validbits_reg),.match_index_reg(match_index),.actual_match(match));


// write and remove control logic (synchronous)
// -----------------------------------------------------------------------------------------------
integer i;
always @(posedge clock_bus_i[1]) begin
	// reset condition
	if (resetn_i != 1'b1) begin
		validbits_reg = 'b0;
		for (i = 0; i < CACHE_BLOCK_CAPACITY; i = i + 1'b1) begin
			tag_mem[i] = 'b0;
		end
	end
	// active sequencing
	else begin
		if (wren_i == 1'b1) begin
			tag_mem[add_i] = tag_i;
			validbits_reg[add_i] = 1'b1;
		end
		if (rmen_i == 1'b1) begin
			validbits_reg[add_i] = 1'b0;
		end
	end
end

endmodule