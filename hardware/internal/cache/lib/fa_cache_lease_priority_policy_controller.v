// MISS: 	lease registers always decremented
// HIT: 	lease registers only decremented if last serviced item was not a cacheable miss

module fa_cache_lease_priority_policy_controller #(
	parameter CACHE_BLOCK_CAPACITY = 0
)(
	// system generics
	input 							clock_i, 			// clock for all submodules (prob. cntrl uses falling edge)
	input 							resetn_i,

	// lease lookup table and config register
	// ports directly routed to LLT from cache controller
	input 							con_wren_i, 		// high when writing to configuration registers
	input 							llt_wren_i, 		// high when writing to lease lookup table
	input 	[BW_ADDR_SPACE-1:0] 	llt_addr_i, 		// also used to write configurations (assumed that config reg addr space < llt addr space)
	input 	[31:0]					llt_data_i, 		// value to write to llt_addr_i
	input 	[`BW_WORD_ADDR-1:0] 	llt_search_addr_i, 	// address from core to table search for

	// controller - lease ports
	input 	[BW_CACHE_CAPACITY-1:0] cache_addr_i, 		// translated cache address - so that lease controller can update lease value
	input 							hit_i, 				// when high, adjust lease register values (strobe trigger)
	input 							miss_i, 			// when high, generate a replacement address (strobe trigger)
	output 							done_o, 			// logic high when controller generates replacement addr
	output 	[BW_CACHE_CAPACITY-1:0]	addr_o,
	output 							swap_o, 			// logic high if the missed block has non-zero lease (i.e. should be brought into cache)
	output 							expired_o, 			// logic high if the replaced cache addr.'s lease expired
	output 							expired_multi_o, 	// logic high if there are multiple cache lines expired at the time of a miss
	output 							default_o 			// logic high if upon a hit the line is renewed with the default lease value
);


// local parameterizations
// ------------------------------------------------------------------------------------------
localparam BW_CACHE_CAPACITY 	= `CLOG2(CACHE_BLOCK_CAPACITY); 				// block addressible cache addresses
localparam BW_ENTRIES 			= `CLOG2(`LEASE_LLT_ENTRIES); 	// entries per table
localparam BW_ADDR_SPACE 		= BW_ENTRIES + 2; 				// four tables total (address, lease0, lease1, lease0_probability)


// lease lookup table
// ------------------------------------------------------------------------------------------
wire [`LEASE_VALUE_BW-1:0] 		llt_lease0, llt_lease1;
wire [8:0]						llt_lease0_prob;
wire 							llt_hit;

lease_lookup_table #(
	.N_ENTRIES 			(`LEASE_LLT_ENTRIES	),
	.BW_LEASE_REGISTER 	(`LEASE_VALUE_BW 	),
	.BW_REF_ADDR 		(`LEASE_REF_ADDR_BW ),
	.BW_PERCENTAGE 		(9 					)
)lease_lookup_table_inst (
	// system ports
	.clock_i 			(clock_i 			),
	.resetn_i 			(resetn_i 			),

	// table initialization ports (write/remove values to table)
	.addr_i 			(llt_addr_i 		), 		// sized to total address space
	.wren_i 			(llt_wren_i 		), 		// write data_i to addr_i
	.rmen_i 			(1'b0 				), 		// evict from addr_i (not used currently)
	.data_i 			(llt_data_i 		), 		// data as word in (table will handle bus size conversion)

	// cache ports
	.search_addr_i 		(llt_search_addr_i 	), 		// address of the ld/st making the memory request (for lease lookup) (address width is full system word-add width)
	.hit_o 				(llt_hit 			), 	 	// logic high if the searched address is in the table
	.lease0_o 			(llt_lease0 		), 		// resulting lease of match
	.lease1_o 			(llt_lease1 		), 		// resulting lease of match
	.lease0_prob_o 		(llt_lease0_prob 	) 		// resulting lease of match (9b LFSR used to eventally compare)
);


// lease probability controller
// ------------------------------------------------------------------------------------------
reg 							lease_prob_en_reg;
wire [`LEASE_VALUE_BW-1:0] 		lease_result;

lease_probability_controller #(
	.BW_LEASE_VALUE		(`LEASE_VALUE_BW	),
	.BW_PERCENTAGE 		(9					)
) lease_prob_contrl_inst (
	.clock_i 			(~clock_i 			),
	.resetn_i 			(resetn_i 			),
	.enable_i 			(lease_prob_en_reg 	), 		// cycle LFSR to generate next prandom number
	.lease0_i 			(llt_lease0 		), 		// higher prob. lease
	.lease1_i 			(llt_lease1 		), 		// lower prob. lease
	.lease0_prob_i 		(llt_lease0_prob 	), 		// prob of higher prob lease
	.lease_o 			(lease_result 		) 		// lease selected based on modules internal random number
);


// lease controller configuration control
// ------------------------------------------------------------------------------------------
reg 	[`LEASE_VALUE_BW-1:0] 	default_lease_reg;

always @(posedge clock_i) begin
	if (!resetn_i) 	default_lease_reg <= 'b0;			//default_lease_reg <= 'b0;
	else begin
		if ((con_wren_i) & (llt_addr_i == 'b0)) default_lease_reg <= llt_data_i[`LEASE_VALUE_BW-1:0];
	end
end


// lease controller
// ------------------------------------------------------------------------------------------
reg 	[`LEASE_VALUE_BW-1:0] 		lease_registers [0:CACHE_BLOCK_CAPACITY-1]; 	// 1 lease register per cache line

reg 								done_reg,
									swap_reg;
reg 	[BW_CACHE_CAPACITY-1:0] 	addr_reg;
reg 								expired_reg,
									default_reg,
									expired_multi_reg;
// generic port maps
assign done_o 			= done_reg;
assign addr_o 			= addr_reg;
assign swap_o 			= swap_reg;
assign expired_o 		= expired_reg;
assign default_o 		= default_reg;
assign expired_multi_o 	= expired_multi_reg;


// set pointer logic - 1 priority encoder per set of lines
// 1 expired bit per line (expired bits used to decode to an address)
// -----------------------------------------------------------------
reg 	[BW_CACHE_CAPACITY-1:0] 	cold_start_counter_reg;
reg 								full_flag_reg; 				// 1: set filled from cold start
wire 	[CACHE_BLOCK_CAPACITY-1:0]	expired_flags;
reg 	[CACHE_BLOCK_CAPACITY-1:0]	default_flag_reg;			// 1: the lease was assigned by default value 
genvar g;

// expired flags
generate
	for (g = 0; g < CACHE_BLOCK_CAPACITY; g = g + 1) begin: exp_flag_arr
		assign expired_flags[g] = ~|lease_registers[g];
	end
endgenerate

// address encodings from the expired flags
wire 	[BW_CACHE_CAPACITY-1:0]	replacement_addr;
wire 							replacement_addr_valid; 			// redux bit of enc inputs - indicates if there is an expired location 	

assign replacement_addr_valid = |expired_flags; 					// valid if at least 1 line in the set is expired

priority_encoder #(
	.INPUT_SIZE		(CACHE_BLOCK_CAPACITY 	)
) lease_rep_encoder (
	.encoding_i		(expired_flags			),
	.binary_o		(replacement_addr		)
);

// address encoding from the defaulted flags
wire 							defaulted_replacement_addr_valid;
wire 	[BW_CACHE_CAPACITY-1:0]	defaulted_replacement_addr;

assign defaulted_replacement_addr_valid = |default_flag_reg;

priority_encoder #(
	.INPUT_SIZE		(CACHE_BLOCK_CAPACITY 		)
) lease_default_encoder (
	.encoding_i		(default_flag_reg			),
	.binary_o		(defaulted_replacement_addr	)
);


// backup policy address generator (LFSR)
// -----------------------------------------------------------------
wire 	[8:0] 						lfsr_val;
wire 	[BW_CACHE_CAPACITY-1:0] 	lfsr_set;
reg 								lfsr_en_reg;

assign lfsr_set = lfsr_val[BW_CACHE_CAPACITY:1];

linear_shift_register_9b #(
	.SEED 			(9'b101010101 		) 		
) lfsr_inst (
	.clock_i 		(~clock_i 			), 
	.resetn_i 		(resetn_i 			), 
	.enable_i 		(lfsr_en_reg 		), 
	.result_o 		(lfsr_val 			)
);


// controller logic
// -----------------------------------------------------------------
reg 							state_reg;
reg 	[`LEASE_VALUE_BW-1:0] 	lease_saved_reg;
reg 							miss_followup_reg;
reg 							miss_default_followup_reg;
integer j;

localparam ST_NORMAL 					= 1'b0;
localparam ST_GENERATE_REPLACEMENT_ADDR = 1'b1;

always @(posedge clock_i) begin
	if (!resetn_i) begin

		// signals to controller
		done_reg 			<= 1'b0;
		addr_reg 			<= 'b0;
		swap_reg 			<= 1'b0;
		expired_reg 		<= 1'b0;
		default_reg 		<= 1'b0;	

		// replacement signals
		for (j = 0; j < CACHE_BLOCK_CAPACITY; j = j + 1)	lease_registers[j] <= 'b0;
		cold_start_counter_reg  <= 'b0;
		default_flag_reg 		<= 'b0;
		full_flag_reg 			<= 'b0;
		lease_saved_reg 		<= 'b0;
		lease_prob_en_reg 		<= 1'b0;
		lfsr_en_reg 			<= 1'b0;

		// sequencing signals
		miss_followup_reg 			<= 1'b0;
		miss_default_followup_reg 	<= 1'b0;
		state_reg 					<= ST_NORMAL;

	end
	else begin

		// default signals
		lease_prob_en_reg 	<= 1'b0;
		lfsr_en_reg 		<= 1'b0;
		expired_reg 		<= 1'b0;
		default_reg 		<= 1'b0;


		case(state_reg)

			ST_NORMAL: begin

				// hit condition
				// ---------------------------------------------------------
				// if the hit is not a followup servicing of a miss, decrement all lease registers
				// always renew the the accessed cache line's lease register
				if (hit_i) begin

					// miss->hit servicing - do not decrement (already done)
					if (miss_followup_reg) begin
						miss_followup_reg 					<= 1'b0;
						lease_registers[cache_addr_i] 		<= lease_saved_reg;

						if (miss_default_followup_reg) begin
							miss_default_followup_reg 		<= 1'b0;
							default_flag_reg[cache_addr_i] 	<= 1'b1;
						end
						else begin
							default_flag_reg[cache_addr_i] 	<= 1'b0;
						end
					end

					// hit servicing
					else begin
						// decrement all lease registers
						for (j = 0; j < CACHE_BLOCK_CAPACITY; j = j + 1) begin
							if (lease_registers[j] != 'b0) lease_registers[j] <= lease_registers[j] - 1'b1;
						end

						// renew lease of referenced line
						if (llt_hit) begin
							lease_registers[cache_addr_i] 			<= lease_result; 			// reference instruction addr is a table match
							default_flag_reg[cache_addr_i] 			<= 1'b0;
						end

						else begin
							default_flag_reg[cache_addr_i] 			<= 1'b1;
							lease_registers[cache_addr_i] 			<= default_lease_reg; 		// reference instrction addr is not a table match so take default value
							default_reg 							<= 1'b1;
						end
					end

					// cycle the policy controller lfsr
					lease_prob_en_reg 	<= 1'b1;

				end

				// miss condition
				// ---------------------------------------------------------
				if (miss_i) begin

					// default signals
					lease_prob_en_reg 	<= 1'b1; 		// cycle probability lfsr
					done_reg 			<= 1'b0; 		// assume a line must be allocated
					swap_reg 			<= 1'b1; 		// assume a line must be allocated

					// decrement all lease registers
					for (j = 0; j < CACHE_BLOCK_CAPACITY; j = j + 1) begin
						if (lease_registers[j] != 'b0) lease_registers[j] <= lease_registers[j] - 1'b1;
					end

					// if the reference that caused a miss has a non-zero lease then a cache line needs to be allocated for it
					// must go to next state
					// register signals here
					if (llt_hit & (lease_result != 'b0)) begin
						state_reg 			<= ST_GENERATE_REPLACEMENT_ADDR;
						miss_followup_reg 	<= 1'b1;
						swap_reg 			<= 1'b1;
						lease_saved_reg 	<= lease_result;
					end
					else if (!llt_hit & (default_lease_reg != 'b0)) begin
						state_reg 					<= ST_GENERATE_REPLACEMENT_ADDR;
						miss_followup_reg 			<= 1'b1;
						miss_default_followup_reg 	<= 1'b1;
						swap_reg 					<= 1'b1;
						lease_saved_reg 			<= default_lease_reg;
						default_reg 				<= 1'b1;
					end
					// if the reference that caused a miss has a zero lease then the request just needs to be serviced
					// this does not result in a follow up hit
					else begin
						done_reg 			<= 1'b1; 	// do not need additional cycles to generate a replacement address
						swap_reg 			<= 1'b0; 	// tell cache controller just to service the request, do not allocate it into cache
						if (!llt_hit) begin
							default_reg 	<= 1'b1; 	// if there was no table hit then a default lease of zero must have caused the condition so 
														// raise flag to record the occurrence
						end
					end		
					/*if (llt_hit) begin
						state_reg 			<= ST_GENERATE_REPLACEMENT_ADDR;
						miss_followup_reg 	<= 1'b1;
						swap_reg 			<= 1'b1;
						lease_saved_reg 	<= lease_result;
					end
					else begin
						state_reg 			<= ST_GENERATE_REPLACEMENT_ADDR;
						miss_followup_reg 	<= 1'b1;
						swap_reg 			<= 1'b1;
						lease_saved_reg 	<= default_lease_reg;
						default_reg 		<= 1'b1;
					end*/
				end
			end

			ST_GENERATE_REPLACEMENT_ADDR: begin

				// no matter the selection method, address generation is finished in this step
				done_reg 	<= 1'b1;
				state_reg 	<= ST_NORMAL;

				// if the cache set is not full (from cold start) then use pointed to address
				if (!full_flag_reg) begin
					addr_reg 				<= {cold_start_counter_reg};

					// determine if full
					if (cold_start_counter_reg == {(BW_CACHE_CAPACITY){1'b1}}) begin
						full_flag_reg <= 1'b1;
					end

					// arbitrarily increment
					cold_start_counter_reg <= cold_start_counter_reg + 1'b1;

				end

				// if cache is full, there is no expired leases, and there is a defaulted lease then replace the default
				else if (defaulted_replacement_addr_valid & !replacement_addr_valid) begin
					addr_reg <= defaulted_replacement_addr;
					//default_flag_reg[defaulted_replacement_addr] 	<= 1'b0;
				end

				// if the cache set is full (from cold start) and there is no expired line in the set then use random address
				else if (!replacement_addr_valid) begin
					addr_reg 				<= lfsr_set;
					lfsr_en_reg 			<= 1'b1;
				end

				// if the cache set is full (from cold start) and there is at least one expired line in the set then 
				// use the replacement address generated from the encoding array
				else begin
					expired_reg 			<= 1'b1;
					addr_reg				<= replacement_addr;
				end

			end

		endcase
	end
end


endmodule