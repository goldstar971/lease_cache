module tag_memory_2way #(
	parameter CACHE_BLOCK_CAPACITY = 128
)(	
	input 						clock_i, 	// write edge
	input 						resetn_i, 	// reset active low 		
	input 						wren_i, 	// write enable (write new entry)
	input 						rmen_i, 	// remove enable (invalidate entry) 	
	input 	[BW_TAG-1:0]		tag_i, 		// primary input (tag -> cache location)
	input 	[BW_GRP-1:0]		group_i,
	input 	[BW_CACHE_ADDR-1:0]	addr_i, 	// add -> tag (part of absolute memory address) - used for replacement
	output	[BW_CACHE_ADDR-1:0]	addr_o, 	// primary output (cache location <- tag)
	output 	[BW_TAG-1:0]		tag_o,		// tag <- add
	output 						hit_o 		// logic high if lookup hit
);


// parameterizations
// ----------------------------------------------------------------------------------
localparam BW_CACHE_ADDR 	= `CLOG2(CACHE_BLOCK_CAPACITY); 		// block addressible [set|group]
localparam BW_GRP 			= BW_CACHE_ADDR - 1; 					// [group]
localparam BW_TAG 			= `BW_WORD_ADDR - BW_GRP - `BW_BLOCK;


// internal memory components
reg 	[BW_TAG-1:0]		set0_tags	[0:(2**BW_GRP)-1];
reg 	[BW_TAG-1:0]		set1_tags	[0:(2**BW_GRP)-1];

wire 	[1:0]				matchbits;
reg 	[(2**BW_GRP)-1:0]	set0_validbits,
							set1_validbits;


// tag lookup logic
// -----------------------------------------------------------------------------------------------
assign matchbits[1] = (tag_i == set1_tags[group_i]) ? 1'b1 : 1'b0;
assign matchbits[0] = (tag_i == set0_tags[group_i]) ? 1'b1 : 1'b0;

wire 	[1:0]	hit_node;
assign hit_o = |hit_node;
assign hit_node[1] = matchbits[1] & set1_validbits[group_i];
assign hit_node[0] = matchbits[0] & set0_validbits[group_i];

reg [BW_CACHE_ADDR-1:0]	addr_reg;
assign addr_o = addr_reg;

always @(*) begin
	case(hit_node)
		2'b01: 		addr_reg = {1'b0,group_i};
		2'b10:		addr_reg = {1'b1,group_i};
		default: 	addr_reg = {1'b0,group_i}; 	// no match - send group for replacement
	endcase
end

// cache addr to tag and group
assign tag_o = 	(addr_i[BW_CACHE_ADDR-1:BW_CACHE_ADDR-1] == 1'b1) ? 	set1_tags[addr_i[BW_GRP-1:0]] :
																	 	set0_tags[addr_i[BW_GRP-1:0]] ;


// tag memory write and remove control
// -----------------------------------------------------------------------------------------------
integer n;

always @(posedge clock_i) begin
	if (resetn_i != 1'b1) begin
		for (n = 0; n < (2**BW_GRP); n = n + 1) begin
			set0_tags[n] = 'b0;
			set1_tags[n] = 'b0;
		end
		set0_validbits = 'b0;
		set1_validbits = 'b0;
	end
	else begin
		// write to tag memory
		if (wren_i) begin
			case(addr_i[BW_CACHE_ADDR-1:BW_CACHE_ADDR-1])
				1'b1: begin
					set1_validbits[addr_i[BW_GRP-1:0]] 	= 1'b1;
					set1_tags[addr_i[BW_GRP-1:0]] 		= tag_i;
				end
				default: begin
					set0_validbits[addr_i[BW_GRP-1:0]] 	= 1'b1;
					set0_tags[addr_i[BW_GRP-1:0]] 		= tag_i;
				end
			endcase
		end
		// remove from tag memory
		if (rmen_i) begin
			case(addr_i[BW_CACHE_ADDR-1:BW_CACHE_ADDR-1])
				1'b1: 		set1_validbits[addr_i[BW_GRP-1:0]] = 1'b0;
				default: 	set0_validbits[addr_i[BW_GRP-1:0]] = 1'b0;
			endcase
		end
	end
end

endmodule