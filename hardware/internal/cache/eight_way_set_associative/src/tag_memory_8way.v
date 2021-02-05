module tag_memory_8way #(
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
localparam BW_GRP 			= BW_CACHE_ADDR - 3; 					// [group]
localparam BW_TAG 			= `BW_WORD_ADDR - BW_GRP - `BW_BLOCK;


// internal memory components
reg 	[BW_TAG-1:0]		set0_tags	[0:(2**BW_GRP)-1];
reg 	[BW_TAG-1:0]		set1_tags	[0:(2**BW_GRP)-1];
reg 	[BW_TAG-1:0]		set2_tags	[0:(2**BW_GRP)-1];
reg 	[BW_TAG-1:0]		set3_tags	[0:(2**BW_GRP)-1];
reg 	[BW_TAG-1:0]		set4_tags	[0:(2**BW_GRP)-1];
reg 	[BW_TAG-1:0]		set5_tags	[0:(2**BW_GRP)-1];
reg 	[BW_TAG-1:0]		set6_tags	[0:(2**BW_GRP)-1];
reg 	[BW_TAG-1:0]		set7_tags	[0:(2**BW_GRP)-1];

wire 	[7:0]				matchbits;
reg 	[(2**BW_GRP)-1:0]	set0_validbits,
							set1_validbits,
							set2_validbits,
							set3_validbits,
							set4_validbits,
							set5_validbits,
							set6_validbits,
							set7_validbits;


// tag lookup logic
// -----------------------------------------------------------------------------------------------
assign matchbits[7] = (tag_i == set7_tags[group_i]) ? 1'b1 : 1'b0;
assign matchbits[6] = (tag_i == set6_tags[group_i]) ? 1'b1 : 1'b0;
assign matchbits[5] = (tag_i == set5_tags[group_i]) ? 1'b1 : 1'b0;
assign matchbits[4] = (tag_i == set4_tags[group_i]) ? 1'b1 : 1'b0;
assign matchbits[3] = (tag_i == set3_tags[group_i]) ? 1'b1 : 1'b0;
assign matchbits[2] = (tag_i == set2_tags[group_i]) ? 1'b1 : 1'b0;
assign matchbits[1] = (tag_i == set1_tags[group_i]) ? 1'b1 : 1'b0;
assign matchbits[0] = (tag_i == set0_tags[group_i]) ? 1'b1 : 1'b0;

wire 	[7:0]	hit_node;
assign hit_o = |hit_node;
assign hit_node[7] = matchbits[7] & set7_validbits[group_i];
assign hit_node[6] = matchbits[6] & set6_validbits[group_i];
assign hit_node[5] = matchbits[5] & set5_validbits[group_i];
assign hit_node[4] = matchbits[4] & set4_validbits[group_i];
assign hit_node[3] = matchbits[3] & set3_validbits[group_i];
assign hit_node[2] = matchbits[2] & set2_validbits[group_i];
assign hit_node[1] = matchbits[1] & set1_validbits[group_i];
assign hit_node[0] = matchbits[0] & set0_validbits[group_i];

reg [BW_CACHE_ADDR-1:0]	addr_reg;
assign addr_o = addr_reg;

always @(*) begin
	case(hit_node)
		8'b00000001: 	addr_reg = {3'b000,group_i};
		8'b00000010:	addr_reg = {3'b001,group_i};
		8'b00000100:	addr_reg = {3'b010,group_i};
		8'b00001000:	addr_reg = {3'b011,group_i};
		8'b00010000: 	addr_reg = {3'b100,group_i};
		8'b00100000:	addr_reg = {3'b101,group_i};
		8'b01000000:	addr_reg = {3'b110,group_i};
		8'b10000000:	addr_reg = {3'b111,group_i};
		default: 		addr_reg = {3'b000,group_i}; 	// no match - send group for replacement
	endcase
end

// cache addr to tag and group
assign tag_o = 	(addr_i[BW_CACHE_ADDR-1:BW_CACHE_ADDR-3] == 3'b111) ? 	set7_tags[addr_i[BW_GRP-1:0]] :
				(addr_i[BW_CACHE_ADDR-1:BW_CACHE_ADDR-3] == 3'b110) ? 	set6_tags[addr_i[BW_GRP-1:0]] : 
				(addr_i[BW_CACHE_ADDR-1:BW_CACHE_ADDR-3] == 3'b101) ? 	set5_tags[addr_i[BW_GRP-1:0]] :
				(addr_i[BW_CACHE_ADDR-1:BW_CACHE_ADDR-3] == 3'b100) ? 	set4_tags[addr_i[BW_GRP-1:0]] :
				(addr_i[BW_CACHE_ADDR-1:BW_CACHE_ADDR-3] == 3'b011) ? 	set3_tags[addr_i[BW_GRP-1:0]] : 
				(addr_i[BW_CACHE_ADDR-1:BW_CACHE_ADDR-3] == 3'b010) ? 	set2_tags[addr_i[BW_GRP-1:0]] :
				(addr_i[BW_CACHE_ADDR-1:BW_CACHE_ADDR-3] == 3'b001) ? 	set1_tags[addr_i[BW_GRP-1:0]] :
																	 	set0_tags[addr_i[BW_GRP-1:0]] ;


// tag memory write and remove control
// -----------------------------------------------------------------------------------------------
integer n;

always @(posedge clock_i) begin
	if (resetn_i != 1'b1) begin
		for (n = 0; n < (2**BW_GRP); n = n + 1) begin
			set0_tags[n] = 'b0;
			set1_tags[n] = 'b0;
			set2_tags[n] = 'b0;
			set3_tags[n] = 'b0;
			set4_tags[n] = 'b0;
			set5_tags[n] = 'b0;
			set6_tags[n] = 'b0;
			set7_tags[n] = 'b0;
		end
		set0_validbits = 'b0;
		set1_validbits = 'b0;
		set2_validbits = 'b0;
		set3_validbits = 'b0;
		set4_validbits = 'b0;
		set5_validbits = 'b0;
		set6_validbits = 'b0;
		set7_validbits = 'b0;
	end
	else begin
		// write to tag memory
		if (wren_i) begin
			case(addr_i[BW_CACHE_ADDR-1:BW_CACHE_ADDR-3])
				3'b111: begin
					set7_validbits[addr_i[BW_GRP-1:0]] 	= 1'b1;
					set7_tags[addr_i[BW_GRP-1:0]] 		= tag_i;
				end
				3'b110: begin
					set6_validbits[addr_i[BW_GRP-1:0]] 	= 1'b1;
					set6_tags[addr_i[BW_GRP-1:0]] 		= tag_i;
				end
				3'b101: begin
					set5_validbits[addr_i[BW_GRP-1:0]] 	= 1'b1;
					set5_tags[addr_i[BW_GRP-1:0]] 		= tag_i;
				end
				3'b100: begin
					set4_validbits[addr_i[BW_GRP-1:0]] 	= 1'b1;
					set4_tags[addr_i[BW_GRP-1:0]] 		= tag_i;
				end
				3'b011: begin
					set3_validbits[addr_i[BW_GRP-1:0]] 	= 1'b1;
					set3_tags[addr_i[BW_GRP-1:0]] 		= tag_i;
				end
				3'b010: begin
					set2_validbits[addr_i[BW_GRP-1:0]] 	= 1'b1;
					set2_tags[addr_i[BW_GRP-1:0]] 		= tag_i;
				end
				3'b001: begin
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
			case(addr_i[BW_CACHE_ADDR-1:BW_CACHE_ADDR-3])
				3'b111: 	set7_validbits[addr_i[BW_GRP-1:0]] = 1'b0;
				3'b110: 	set6_validbits[addr_i[BW_GRP-1:0]] = 1'b0;
				3'b101: 	set5_validbits[addr_i[BW_GRP-1:0]] = 1'b0;
				3'b100: 	set4_validbits[addr_i[BW_GRP-1:0]] = 1'b0;
				3'b011: 	set3_validbits[addr_i[BW_GRP-1:0]] = 1'b0;
				3'b010: 	set2_validbits[addr_i[BW_GRP-1:0]] = 1'b0;
				3'b001: 	set1_validbits[addr_i[BW_GRP-1:0]] = 1'b0;
				default: 	set0_validbits[addr_i[BW_GRP-1:0]] = 1'b0;
			endcase
		end
	end
end

endmodule