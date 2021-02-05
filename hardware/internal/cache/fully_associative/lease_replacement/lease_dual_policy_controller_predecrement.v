module lease_dual_policy_controller #(
	parameter CACHE_BLOCK_CAPACITY = 0,
	parameter N_LEASE_CONFIGS = 0,
	parameter N_ENTRIES = 0,
	parameter BW_LEASE_REGISTER = 0,
	parameter BW_REF_ADDR = 0
)(
	// system ports
	input 							clock_i, 		// llt and controller clocked with same clock
	input 							resetn_i,

	// cache to llt ports (ignore logic/structure of the controller)
	input 	[BW_ENTRIES:0]			llt_addr_i, 	// table write address - extra bit to shift between tables
	input 							wren_ref_addr_i,// write to addr_i
	input 							wren_lease_i, 	// write to addr_i
	input 							rmen_i, 		// remove addr_i from table
	input 	[BW_REF_ADDR-1:0] 		ref_addr_i, 	// ref address to write to table
	input 	[BW_LEASE_REGISTER-1:0]	ref_lease_i, 	// lease value to write to table
	input 	[`BW_WORD_ADDR-1:0] 	search_addr_i, 	// address of the ld/st making the memory request (for lease lookup)

	// controller - lease config ports
	input 							config_wren_i, 	// when high write data to config addr
	input 	[BW_CONFIG_REGS-1:0]	config_addr_i,
	input 	[`LEASE_CONFIG_VAL_BW-1:0]	config_data_i,

	// controller - lease ports
	input 	[BW_CACHE_CAPACITY-1:0] cache_addr_i, 	// translated cache address - so that lease controller can update lease value
	input 							hit_i, 			// when high, adjust lease register values (strobe trigger)
	input 							miss_i, 		// when high, generate a replacement address (strobe trigger)
	input 							hit_no_swap_i , // when high, decrement all lease registers (strobe trigger)
	output 							done_o, 		// logic high when controller generates replacement addr
	output 	[BW_CACHE_CAPACITY-1:0]	addr_o,
	output 							swap_o, 		// logic high if the missed block has non-zero lease (i.e. should be brought into cache)
	output 							expired_o, 		// logic high if the replaced cache addr.'s lease expired
	output 							default_o 		// logic high if upon a hit the line is renewed with the default lease value
);

// parameterizations
// ----------------------------------------------------------------------------------------------------------------------
localparam BW_ENTRIES  		 = `CLOG2(N_ENTRIES);
localparam BW_CACHE_CAPACITY = `CLOG2(CACHE_BLOCK_CAPACITY);
localparam BW_CONFIG_REGS 	 = `CLOG2(N_LEASE_CONFIGS);


// lease lookup table
// ----------------------------------------------------------------------------------------------------------------------
wire 	 						llt_hit;
wire [BW_LEASE_REGISTER-1:0] 	llt_lease0, llt_lease1;
wire [8:0]						llt_lease0_prob;

lease_dual_lookup_table #(
	.N_ENTRIES 			(N_ENTRIES 			),
	.BW_LEASE_REGISTER 	(BW_LEASE_REGISTER 	),
	.BW_REF_ADDR 		(BW_REF_ADDR 		)
) llt_inst (

	// system ports
	.clock_i 			(clock_i 			),
	.resetn_i 			(resetn_i 			),

	// table initialization ports (write/remove values to table)
	.addr_i 			(llt_addr_i 		),	// address to write to
	.wren_ref_addr_i 	(wren_ref_addr_i 	), 	// write to addr_i
	.wren_lease_i 		(wren_lease_i 		), 	// write to addr_i
	.rmen_i 			(rmen_i 			), 	// remove addr_i from table
	.ref_addr_i 		(ref_addr_i 		), 	// ref address to write to table
	.ref_lease_i 		(ref_lease_i 		), 	// lease value to write to table

	// cache replacement ports
	.search_addr_i 		(search_addr_i 		), 	// address of the ld/st making the memory request (for lease lookup)
	.hit_o 				(llt_hit 			), 	// logic high if the searched address is in the table
	.lease0_o 			(llt_lease0 		), 	// resulting lease0 of match
	.lease1_o 			(llt_lease1 		), 	// resulting lease1 of match
	.lease0_prob_o 		(llt_lease0_prob 	) 	// resulting lease0 probability of match
);


// dual lease lease selector
// ----------------------------------------------------------------------------------------------------------------------



// lease register controller logic
// ----------------------------------------------------------------------------------------------------------------------
reg 	[`LEASE_CONFIG_VAL_BW-1:0] 	config_registers[0:N_LEASE_CONFIGS-1];
reg 	[BW_LEASE_REGISTER-1:0] 	lease_registers [0:CACHE_BLOCK_CAPACITY-1]; 	// 1 lease register per cache line
wire 	[`LEASE_CONFIG_VAL_BW-1:0] 	default_lease;
wire 	[`LEASE_CONFIG_VAL_BW-1:0] 	default_policy;
wire 	[`LEASE_CONFIG_VAL_BW-1:0] 	default_pool;

assign default_lease = config_registers[0];
assign default_policy = config_registers[1];
assign default_pool = config_registers[2];

// port mapping
reg 								done_reg;
reg [BW_CACHE_CAPACITY-1:0] 		addr_reg;
reg 								expired_reg,
									default_reg;

assign done_o = done_reg;
assign addr_o = addr_reg;
assign expired_o = expired_reg;
assign default_o = default_reg;

// controller hardware components
// ----------------------------------------------------------------------------------------------------------------------
wire [CACHE_BLOCK_CAPACITY-1:0]		lease_expired_flags;

genvar k;
generate
	for (k = 0; k < CACHE_BLOCK_CAPACITY; k = k + 1) begin: expired_flag_array
		assign lease_expired_flags[k] = ~|lease_registers[k]; 				// set a flag when an RRPV register is at capacity
	end
endgenerate

// priority encoder to find first occurrence of expired lease line
wire	[BW_CACHE_CAPACITY-1:0]		lease_flag_encoder_addr;

priority_encoder #( 
	.INPUT_SIZE 	(CACHE_BLOCK_CAPACITY 		) 
) rrpv_addr_encoder(
	.encoding_i 	(lease_expired_flags 		),
	.binary_o 		(lease_flag_encoder_addr 	)
);

// LFSR to generate random addresses on non-expired replacement
reg 			en_lfsr;
wire 	[8:0] 	val_lfsr;
linear_shift_register_9b lfsr_inst(
	.clock_i 		(clock_i 			), 
	.resetn_i 		(resetn_i 			), 
	.enable_i 		(en_lfsr 			), 
	.result_o 		(val_lfsr 			)
);


// dual lease selector
// ----------------------------------------------------------------------------------------------------------------------
reg 	 						lease_sel_en_reg;
wire 	[BW_LEASE_REGISTER-1:0] lease_sel_result;

lease_dual_probability_controller #(
	.BW_LEASE_VALUE 		(BW_LEASE_REGISTER 	)
) lease_dual_selector(
	.clock_i 				(clock_i 			),
	.resetn_i 				(resetn_i 			),
	.enable_i 				(lease_sel_en_reg 	),
	.lease0_i 				(llt_lease0 		),
	.lease1_i 				(llt_lease1 		),
	.lease0_prob_i 			(llt_lease0_prob 	),
	.lease_o 				(lease_sel_result 	)
);


// controller logic
// ----------------------------------------------------------------------------------------------------------------------
reg 						state_reg;
wire 						full_flag; 					// goes high when the cache is filled from cold start
reg [BW_CACHE_CAPACITY:0] 	utilization_count_reg; 		// counts the running count of cache utilization from cold start

assign full_flag = utilization_count_reg[BW_CACHE_CAPACITY]; 	// if MSb is high then cache is fully utilized
assign swap_o = |lease_sel_result;

localparam ST_NORMAL 					= 1'b0;
localparam ST_GENERATE_REPLACEMENT 		= 1'b1;

test_bram_32b_256B config_inst(
	.address 	(config_addr_i 		),
	.clock 		(clock_i 			),
	.data 		(config_data_i 		),
	.wren 		(config_wren_i		),
	.q 			()
);


integer i, j;
always @(posedge clock_i) begin
	// reset state
	if (!resetn_i) begin
		for (i = 0; i < N_LEASE_CONFIGS; i = i + 1)	 		config_registers[i] = 'b0;
		for (j = 0; j < CACHE_BLOCK_CAPACITY; j = j + 1)	lease_registers[j] = 'b0;
		done_reg = 1'b0;
		addr_reg = 'b0;
		expired_reg = 1'b0;
		default_reg = 1'b0;
		utilization_count_reg = 'b0;
		state_reg = ST_NORMAL;
		en_lfsr = 1'b0;
		lease_sel_en_reg = 1'b0;
	end
	// active sequencing
	else begin

		// default values
		lease_sel_en_reg = 1'b0;
		en_lfsr = 1'b0;
		expired_reg = 1'b0;
		default_reg = 1'b0;

		// configuration control
		// -----------------------------------------------------------------------------------
		if (config_wren_i) config_registers[config_addr_i] <= config_data_i;

		// state control
		// -----------------------------------------------------------------------------------
		case(state_reg)

			// state updates lease registers, and generates replacement addresses that can be 
			// generated same cycle, transitions to next state if address requires more than one
			// cycle. The backup cache policy dictates this.
			ST_NORMAL: begin

				// lease control - hit
				// ---------------------------------------------------------------------------
				if (hit_i) begin
					// increment the selector LFSR
					lease_sel_en_reg = 1'b1;

					// upon a hit go through all cache lines, renew the matched line and decrement all others
					for (j = 0; j < CACHE_BLOCK_CAPACITY; j = j + 1) begin
						if (j == cache_addr_i) begin
							// renew lease
							if (llt_hit) begin
								//lease_registers[j] <= llt_lease;
								lease_registers[j] <= lease_sel_result;
							end
							else begin
								default_reg = 1'b1;
								lease_registers[j] <= default_lease;
							end
						end
						else begin
							// decrement upon reference if not already expired
							if (lease_registers[j] != 'b0) begin
								lease_registers[j] <= lease_registers[j] - 1'b1;
							end
						end
					end
				end

				// lease control - miss
				// ---------------------------------------------------------------------------
				if (miss_i) begin

					// increment the selector LFSR so generate new random number
					lease_sel_en_reg = 1'b1;

					// set control signals
					done_reg = 1'b0;

					// if miss and the renewal lease value is 0, the block is never brought into cache so never results in a hit
					// thus need additional logic here to decrement all lease registers in that event
					if (lease_sel_result == 'b0) begin
						for (j = 0; j < CACHE_BLOCK_CAPACITY; j = j + 1) begin
							if (lease_registers[j] != 'b0) begin
								lease_registers[j] <= lease_registers[j] - 1'b1;
							end
						end
					end

					else begin

						// if cache not yet full then replace next open cache line
						// -----------------------------------------------------------------------
						if (!full_flag) begin
							done_reg = 1'b1;
							addr_reg = utilization_count_reg[BW_CACHE_CAPACITY-1:0];	// point to next open location
							utilization_count_reg = utilization_count_reg + 1'b1; 		// increment count, when MSb goes high then cache
																						// fully utilized
						end
						// cache fully utilized so active lease policy
						// -----------------------------------------------------------------------
						else begin

							// if there is an expired lease then priority encoder selects first instance of expired block to swap
							if (|lease_expired_flags) begin
								expired_reg = 1'b1;
								done_reg = 1'b1;
								addr_reg = lease_flag_encoder_addr;
							end

							// if there is no expired lease then backup policy dictates the replacement method
							else begin
								state_reg = ST_GENERATE_REPLACEMENT;
							end
						end
					end
				end
			end

			// if replacement cannot be generated in one step then switch to this state to determine the
			// replacement line
			ST_GENERATE_REPLACEMENT: begin

				// get random cache line from LFSR and enable LFSR to generate next number in it's sequence
				done_reg = 1'b1;
				//addr_reg = multiplexer_output;
				//addr_reg = val_lfsr[BW_CACHE_CAPACITY-1:0];
				addr_reg = val_lfsr[BW_CACHE_CAPACITY:1];
				en_lfsr = 1'b1;
				state_reg = ST_NORMAL;
			end

		endcase
	end
end

endmodule