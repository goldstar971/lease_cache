module lease_dual_lookup_table #(
	parameter N_ENTRIES = 0,
	parameter BW_LEASE_REGISTER = 0,
	parameter BW_REF_ADDR = 0
)(
	// system ports
	input							clock_i,
	input 							resetn_i,

	// table initialization ports (write/remove values to table)
	input 	[BW_ENTRIES:0]			addr_i,   		// input address for writing/removing - extra bit to switch between parallel tables
	input 							wren_ref_addr_i,// write to addr_i
	input 							wren_lease_i, 	// write to addr_i
	input 							rmen_i, 		// remove addr_i from table
	input 	[BW_REF_ADDR-1:0] 		ref_addr_i, 	// ref address to write to table
	input 	[BW_LEASE_REGISTER-1:0]	ref_lease_i, 	// lease value to write to table

	// cache replacement ports
	input 	[`BW_WORD_ADDR-1:0] 	search_addr_i, 	// address of the ld/st making the memory request (for lease lookup)
	output 							hit_o, 			// logic high if the searched address is in the table
	output 	[BW_LEASE_REGISTER-1:0]	lease0_o, 		// resulting lease of match
	output 	[BW_LEASE_REGISTER-1:0]	lease1_o, 		// resulting lease of match
	output 	[8:0]	 				lease0_prob_o 	// resulting lease of match (9b LFSR used to eventally compare)
);

// parameterizations
// ----------------------------------------------------------------------------------------
localparam BW_ENTRIES = `CLOG2(N_ENTRIES); 			// entries per table, 4 mem arrays total (ref addr, lease0_val, lease1_val, lease0_probability)


// table write/remove logic
// ----------------------------------------------------------------------------------------
reg 	[N_ENTRIES-1:0]				validbits; 						// logic high when ref addr and lease value written to table
reg 	[BW_REF_ADDR-1:0] 			ref_addr_mem[0:N_ENTRIES-1]; 	// lease reference addr
reg 	[BW_LEASE_REGISTER-1:0] 	lease0_mem	[0:N_ENTRIES-1]; 	// lease0 value of reference addr
reg 	[BW_LEASE_REGISTER-1:0] 	lease1_mem	[0:N_ENTRIES-1]; 	// lease0 value of reference addr
reg 	[8:0] 						lease0_prob_mem	[0:N_ENTRIES-1]; 	// lease0 value of reference addr

test_bram_32b_512B ref_addr_inst(
	.address 	(addr_i[BW_ENTRIES-1:0] 				),
	.clock 		(clock_i 								),
	.data 		(ref_addr_i 			 				),
	.wren 		(wren_ref_addr_i & !addr_i[BW_ENTRIES]	),
	.q 			()
);

test_bram_32b_512B ref_lease0_inst(
	.address 	(addr_i[BW_ENTRIES-1:0] 				),
	.clock 		(clock_i 								),
	.data 		(ref_lease_i 			 				),
	.wren 		(wren_lease_i & !addr_i[BW_ENTRIES]		),
	.q 			()
);

test_bram_32b_512B ref_lease1_inst(
	.address 	(addr_i[BW_ENTRIES-1:0] 				),
	.clock 		(clock_i 								),
	.data 		(ref_addr_i 			 				),
	.wren 		(wren_ref_addr_i & addr_i[BW_ENTRIES]	),
	.q 			()
);

test_bram_32b_512B lease0_prob_inst(
	.address 	(addr_i[BW_ENTRIES-1:0] 				),
	.clock 		(clock_i 								),
	.data 		(ref_lease_i 			 				),
	.wren 		(wren_lease_i & addr_i[BW_ENTRIES]		),
	.q 			()
);

integer i;
always @(posedge clock_i) begin
	if (!resetn_i) begin
		validbits = 'b0;
		for (i = 0; i < N_ENTRIES; i = i + 1) begin
			ref_addr_mem[i] 	<= 'b0;
			lease0_mem[i] 		<= 'b0;
			lease1_mem[i] 		<= 'b0;
			lease0_prob_mem[i] 	<= 'b0;
		end
	end
	else begin
		
		case(addr_i[BW_ENTRIES])

			// TABLE 0 ARRAY - ref_addr and lease0
			// ---------------------------------------------------------
			1'b0: begin

				// write reference address to the table
				if (wren_ref_addr_i) begin
					ref_addr_mem[addr_i[BW_ENTRIES-1:0]] <= ref_addr_i;
				end
				// write the reference's lease to the table
				if (wren_lease_i) begin
					lease0_mem[addr_i[BW_ENTRIES-1:0]] 	<= ref_lease_i;
					validbits[addr_i[BW_ENTRIES-1:0]] 	<= 1'b1;
				end
				// invalidate table entry
				if (rmen_i) begin
					validbits[addr_i[BW_ENTRIES-1:0]] 	<= 1'b0;
				end
			end

			// TABLE 1 ARRAY - lease1 and lease0_prob
			// ---------------------------------------------------------
			1'b1: begin

				// write lease1 value to the table
				if (wren_ref_addr_i) begin
					lease1_mem[addr_i[BW_ENTRIES-1:0]] <= ref_addr_i;
				end
				// lease0 probability
				if (wren_lease_i) begin
					lease0_prob_mem[addr_i[BW_ENTRIES-1:0]] <= ref_lease_i[8:0];
					//validbits[addr_i] <= 1'b1;
				end
				// invalidate table entry
				//if (rmen_i) begin
				//	validbits[addr_i] <= 1'b0;
				//end
			end


	 	endcase
	end
end


// table search combinational logic
// ----------------------------------------------------------------------------------------
reg 	[BW_LEASE_REGISTER-1:0]	lease0_match_reg,
								lease1_match_reg;
reg 	[8:0]					lease0_prob_match_reg;
wire 	[N_ENTRIES-1:0] 		matchbits,
								hitbits;

// comparator array
genvar j;
generate
	for (j = 0; j < N_ENTRIES; j = j + 1) begin : llt_matchbit_array
		identity_comparator #(.BW(BW_REF_ADDR)) comp_inst (search_addr_i[BW_REF_ADDR-1:0], ref_addr_mem[j], matchbits[j]);
	end
endgenerate

assign hitbits = matchbits & validbits;
assign hit_o = |hitbits;

// lease output array
always @(*) begin

	// default condition
	lease0_match_reg = 'b0;
	lease1_match_reg = 'b0;
	lease0_prob_match_reg = 'b0;

	// output match
	for (i = 0; i < N_ENTRIES; i = i + 1) begin
		if (hitbits[i]) begin
			lease0_match_reg 		= lease0_mem[i];
			lease1_match_reg 		= lease1_mem[i];
			lease0_prob_match_reg 	= lease0_prob_mem[i];
		end
	end
end

assign lease0_o 		= lease0_match_reg;
assign lease1_o 		= lease1_match_reg;
assign lease0_prob_o 	= lease0_prob_match_reg;


endmodule