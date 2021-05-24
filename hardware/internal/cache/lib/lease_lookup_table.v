module lease_lookup_table #(
	parameter N_ENTRIES = 0, 						// defined as paraemeters incase code re-used for second level cache
	parameter BW_LEASE_REGISTER = 0, 				// (not sure if applicable but does hurt)
	parameter BW_REF_ADDR = 0,
	parameter BW_PERCENTAGE = 0
)(
	// system ports
	input							clock_i,
	input 							resetn_i,

	// table initialization ports (write/remove values to table)
	input 	[BW_ADDR_SPACE-1:0]		addr_i, 		// sized to total address space
	input 							wren_i, 		// write data_i to addr_i
	input 							rmen_i, 		// evict from addr_i 
	input 	[31:0] 					data_i, 		// data as word in (table will handle bus size conversion)

	// cache ports
	input 	[`BW_WORD_ADDR-1:0] 	search_addr_i, 	// address of the ld/st making the memory request (for lease lookup)
	output 							hit_o, 			// logic high if the searched address is in the table
	output 	[BW_LEASE_REGISTER-1:0]	lease0_o, 		// resulting lease of match
	output 	[BW_LEASE_REGISTER-1:0]	lease1_o, 		// resulting lease of match
	output 	[BW_PERCENTAGE-1:0]	 	lease0_prob_o 	// resulting lease of match (9b LFSR used to eventally compare)
);

// parameterizations
// ----------------------------------------------------------------------------------------
localparam BW_ENTRIES 		= `CLOG2(N_ENTRIES); 	// entries per table
localparam BW_ADDR_SPACE 	= BW_ENTRIES + 2; 		// four tables total (address, lease0, lease1, lease0_probability)


// table write/remove logic
// ----------------------------------------------------------------------------------------
reg 	[N_ENTRIES-1:0]				validbits; 							// logic high when ref addr written to table
reg 	[BW_REF_ADDR-1:0] 			ref_addr_mem	[0:N_ENTRIES-1]; 	// lease reference addr
reg 	[BW_LEASE_REGISTER-1:0] 	lease0_mem		[0:N_ENTRIES-1]; 	// lease0 value of reference addr
reg 	[BW_LEASE_REGISTER-1:0] 	lease1_mem		[0:N_ENTRIES-1]; 	// lease1 value of reference addr
reg 	[BW_PERCENTAGE-1:0] 		lease0_prob_mem	[0:N_ENTRIES-1]; 	// lease0 percentage of reference addr

wire 	[BW_ENTRIES-1:0]			addr_table;

assign addr_table = addr_i[BW_ENTRIES-1:0];



integer i;
always @(posedge clock_i) begin
	if (!resetn_i) begin
		validbits <= 'b0;
		for (i = 0; i < N_ENTRIES; i = i + 1) begin
			ref_addr_mem[i] 	<= 'b0;
			lease0_mem[i] 		<= 'b0;
			lease1_mem[i] 		<= 'b0;
			lease0_prob_mem[i] 	<= 'b0;
		end
	end
	else begin
		
		case(addr_i[BW_ADDR_SPACE-1:BW_ADDR_SPACE-2])

			// reference address array
			2'b00: begin
				if (wren_i) begin
					validbits[addr_table] 					<= 1'b1;
					ref_addr_mem[addr_table] 				<= data_i[BW_REF_ADDR+1:2]; 	// shifted two to convert to word address
				end
				if (rmen_i) validbits[addr_table] 			<= 1'b0;
			end

			// lease 0 array
			2'b01: if (wren_i) lease0_mem[addr_table] 		<= data_i[BW_LEASE_REGISTER-1:0];

			// lease 1 array
			2'b10: if (wren_i) lease1_mem[addr_table] 		<= data_i[BW_LEASE_REGISTER-1:0];

			// lease 0 percentage array
			2'b11: if (wren_i) lease0_prob_mem[addr_table] 	<= data_i[BW_PERCENTAGE-1:0];

		endcase
	end
end


// table search combinational logic
// ----------------------------------------------------------------------------------------
reg 	[BW_LEASE_REGISTER-1:0]	lease0_match_reg,
								lease1_match_reg;
reg 	[BW_PERCENTAGE-1:0]		lease0_prob_match_reg;
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