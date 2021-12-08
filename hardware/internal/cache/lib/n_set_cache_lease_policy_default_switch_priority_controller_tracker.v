// MISS: 	lease registers always decremented
// HIT: 	lease registers only decremented if last serviced item was not a cacheable miss

module n_set_cache_lease_policy_default_switch_priority_controller_tracker #(
	parameter CACHE_BLOCK_CAPACITY = 0,
	parameter CACHE_SET_SIZE = 0 
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

	// line tracking ports
	`ifdef TRACKER
	output [CACHE_BLOCK_CAPACITY-1:0] expired_flags_0_o,
	output [CACHE_BLOCK_CAPACITY-1:0] expired_flags_1_o,
	output [CACHE_BLOCK_CAPACITY-1:0] expired_flags_2_o,
	`endif
	// controller - lease ports
	input 	[BW_CACHE_CAPACITY-1:0] cache_addr_i, 		// translated cache address - so that lease controller can update lease value
	input 							hit_i, 				// when high, adjust lease register values (strobe trigger)
	input 							miss_i, 			// when high, generate a replacement address (strobe trigger)
	output 							done_o, 			// logic high when controller generates replacement addr
	output 	[BW_CACHE_CAPACITY-1:0]	addr_o,
	output 							swap_o, 			// logic high if the missed block has non-zero lease (i.e. should be brought into cache)
	output 							expired_o, 			// logic high if the replaced cache addr.'s lease expired
	output 							expired_multi_o, 	// logic high if there are multiple cache lines expired at the time of a miss
	output 							default_o, 			// logic high if upon a hit the line is renewed with the default lease value
	output                          rand_evict_o
	
);


// local parameterizations
// ------------------------------------------------------------------------------------------
localparam BW_CACHE_CAPACITY 	= `CLOG2(CACHE_BLOCK_CAPACITY); // block addressible cache addresses
localparam BW_GRP 				=`CLOG2(CACHE_SET_SIZE);				
localparam BW_SET 				=BW_CACHE_CAPACITY-BW_GRP;
localparam N_SET 				= 2**BW_SET;
localparam N_GROUPS 			= CACHE_SET_SIZE;
localparam BW_ENTRIES 			= `CLOG2(`LEASE_LLT_ENTRIES); 	// entries per table
localparam BW_ADDR_SPACE 		= BW_ENTRIES + 1; 				// two tables total (address, lease0)

generate
	if(CACHE_BLOCK_CAPACITY!=CACHE_SET_SIZE)begin
		wire [BW_SET-1:0] cache_set_index;
		assign cache_set_index=cache_addr_i[BW_CACHE_CAPACITY-1:BW_GRP];
	end 
	else begin 
		wire cache_set_index;
		assign cache_set_index=1'b0;
	end
endgenerate

// lease lookup table
// ------------------------------------------------------------------------------------------
wire [`LEASE_VALUE_BW-1:0] 		llt_lease0;
reg  [`LEASE_VALUE_BW-1:0] llt_lease1, dual_lease_ref;
reg [`BW_PERCENTAGE-1:0]	dual_lease_prob;
wire [`BW_PERCENTAGE-1:0] llt_lease0_prob;

wire 							llt_hit;

lease_lookup_table #(
	.N_ENTRIES 			(`LEASE_LLT_ENTRIES	),
	.BW_LEASE_REGISTER 	(`LEASE_VALUE_BW 	),
	.BW_REF_ADDR 		(`LEASE_REF_ADDR_BW )
	
)lease_lookup_table_inst (
	// system ports
	.clock_i 			(clock_i 			),
	.resetn_i 			(resetn_i 			),

	// table initialization ports (write/remove values to table)
	.addr_i 			(llt_addr_i 		), 		// sized to total address space
	.wren_i 			(llt_wren_i 		), 		// write data_i to addr_i
	.data_i 			(llt_data_i 		), 		// data as word in (table will handle bus size conversion)
	.phase_refs_i       (refs_per_phase     ), 		//number of references in the current phase

	// cache ports
	.search_addr_i 		(llt_search_addr_i 	), 		// address of the ld/st making the memory request (for lease lookup) (address width is full system word-add width)
	.hit_o 				(llt_hit 			), 	 	// logic high if the searched address is in the table
	.lease0_o 			(llt_lease0 		) 		// resulting lease of match
);


// lease probability controller
// ------------------------------------------------------------------------------------------
reg 							lease_prob_en_reg;
wire [`LEASE_VALUE_BW-1:0] 		lease_result;

lease_probability_controller #(
	.BW_LEASE_VALUE		(`LEASE_VALUE_BW	)
	
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
reg     [BW_ENTRIES-1:0] refs_per_phase;
always @(posedge clock_i) begin
	if (!resetn_i) 	default_lease_reg <= 'b0;			//default_lease_reg <= 'b0;
	else begin
		if (con_wren_i) begin
			case(llt_addr_i)
				'b0: default_lease_reg<=llt_data_i[`LEASE_VALUE_BW-1:0];
				'b01: llt_lease1 <=llt_data_i[`LEASE_VALUE_BW-1:0];
				'b10: dual_lease_prob<=llt_data_i[`BW_PERCENTAGE-1:0];
				'b100: dual_lease_ref<=llt_data_i[`LEASE_VALUE_BW-1:0]; 
				'b11:  refs_per_phase<=llt_data_i[BW_ENTRIES-1:0]; 
			 	default: ;
			endcase
		end
	end
end
//select probability of short lease
assign llt_lease0_prob=(dual_lease_ref==llt_search_addr_i) ? dual_lease_prob : {`BW_PERCENTAGE{1'b1}};


// lease controller
// ------------------------------------------------------------------------------------------
reg 	[`LEASE_VALUE_BW-1:0] 		lease_registers [0:CACHE_BLOCK_CAPACITY-1]; 	// 1 lease register per cache line

reg 								done_reg,
									swap_reg;

reg   [BW_CACHE_CAPACITY-1:0] addr_reg;
reg 								expired_reg,
									default_reg,
									expired_multi_reg,
									random_eviction_reg;

// generic port maps
assign done_o 			= done_reg;
assign addr_o 			= addr_reg;
assign swap_o 			= swap_reg;
assign expired_o 		= expired_reg;
assign default_o 		= default_reg;
assign expired_multi_o 	= expired_multi_reg;
assign rand_evict_o  = random_eviction_reg;



// set pointer logic - 1 priority encoder per set of lines
// 1 expired bit per line (expired bits used to decode to an address)
// -----------------------------------------------------------------
reg 	[BW_GRP-1:0] 				cold_start_counter_regs [0:N_SET-1];
reg 	[N_SET-1:0] 				full_flags_reg; 		// 1: set filled from cold start
wire 	[CACHE_BLOCK_CAPACITY-1:0]	expired_flags;
reg 	[CACHE_BLOCK_CAPACITY-1:0]	default_flag_reg_array [0:N_SET-1];
genvar g,h;

// expired flags
generate
	for (g = 0; g < CACHE_BLOCK_CAPACITY; g = g + 1) begin: exp_flag_arr
		assign expired_flags[g] = ~|lease_registers[g];
	end
endgenerate

// address encodings from the expired flags
wire 	[BW_GRP-1:0]	replacement_addr_arr [0:N_SET-1];
wire    [BW_GRP-1:0]    defaulted_replacement_addr_array[0:N_SET-1];
wire    [BW_GRP-1:0]    defaulted_replacement_addr_valid_array[0:N_SET-1];
wire    [N_SET-1:0]    multi_vacancy_arr;
wire 	[N_SET-1:0]	replacement_addr_valid; 				// redux bit of enc inputs - indicates if there is an expired location 	
reg     [9:0] default_lease_counter;

generate
	if (CACHE_BLOCK_CAPACITY==CACHE_SET_SIZE)begin 
				
						multi_detect_priority_encoder lease_rep_encoder(.clk(clock_i),.rst(!resetn_i),.oht(expired_flags),
			 .bin(replacement_addr_arr[0]),.vld(replacement_addr_valid[0]),.multi_detect(multi_vacancy_arr[0]));
						priority_encoder lease_default_encoder(.clk() .reset(),.oht(default_flag_reg_array[0]),
							.vld(defaulted_replacement_addr_valid_array[0]),.bin(defaulted_replacement_addr_array[0]));
	end
	else begin
		for (g = 0; g < N_SET; g = g + 1) begin: lease_rep_encoder_arr

			wire [N_GROUPS-1:0] 	set_expired_flags;

			
			for (h=g;h<CACHE_BLOCK_CAPACITY;h=h+N_SET)begin: set_concatenating
			    assign set_expired_flags[(h-g)/N_SET]=expired_flags[h];
			end


			multi_detect_priority_encoder lease_rep_encoder(.clk(clock_i),.rst(!resetn_i),.oht(set_expired_flags),
			 .bin(replacement_addr_arr[g] ),.vld(replacement_addr_valid[g]),.multi_detect(multi_vacancy_arr[g]));
				priority_encoder lease_default_encoder(.clk() .reset(),.oht(default_flag_reg_array[g]),
							.vld(defaulted_replacement_addr_valid_array[g]),.bin(defaulted_replacement_addr_array[g]));
		end
	end
endgenerate
// line tracking hardware
// -----------------------------------------------------------------
`ifdef TRACKER
generate
	for (g = 0; g < CACHE_BLOCK_CAPACITY; g = g + 1) begin: exp_flag_discrete_arr
	

		// unpack register array
		wire [`LEASE_VALUE_BW-1:0] lease_register_bus;
		assign lease_register_bus = lease_registers[g];

		assign expired_flags_0_o[g] = |lease_register_bus[7:0];
		assign expired_flags_1_o[g] = |lease_register_bus[15:8];
		assign expired_flags_2_o[g] = |lease_register_bus[`LEASE_VALUE_BW-1:16];
	end
endgenerate
`endif


// backup policy address generator (LFSR)
// -----------------------------------------------------------------
wire 	[BW_CACHE_CAPACITY:0] 						lfsr_val;
wire 	[BW_GRP-1:0] 	lfsr_grp;
reg 								lfsr_en_reg;

assign lfsr_grp = lfsr_val[BW_GRP-1:0];

linear_shift_register_12b #(
	.SEED 			(12'b101000010001 ) 		
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
		addr_reg				<=1'b0;
		done_reg 			<= 1'b0;
		swap_reg 			<= 1'b0;
		expired_reg 		<= 1'b0;
		default_reg 		<= 1'b0;	
		expired_multi_reg 	<= 1'b0;
		random_eviction_reg <= 1'b0;

		// replacement signals
		for (j = 0; j < CACHE_BLOCK_CAPACITY; j = j + 1)	lease_registers[j] <= 'b0;
		for (j = 0; j < N_SET; j = j + 1) 				cold_start_counter_regs[j] <= 'b0;
		for (j = 0); j <N_SET; j = j + 1)               default_flag_reg_array<='b0;

		full_flags_reg 			<= 'b0;
		lease_saved_reg 		<= 'b0;
		lease_prob_en_reg 		<= 1'b0;
		lfsr_en_reg 			<= 1'b0;

		// sequencing signals
		miss_followup_reg 		<= 1'b0;
		miss_default_followup_reg <=1'b0;
		state_reg 				<= ST_NORMAL;
		default_lease_counter	<='b0;

	end
	else begin

		// default signals
		lease_prob_en_reg 	<= 1'b0;
		lfsr_en_reg 		<= 1'b0;
		expired_reg 		<= 1'b0;
		default_reg 		<= 1'b0;
		expired_multi_reg 	<= 1'b0;
		random_eviction_reg <= 1'b0;
		swap_reg 			<= 1'b1; //assume we are bringing in a new block to the cache upon a miss


		case(state_reg)

			ST_NORMAL: begin


				// hit condition
				// ---------------------------------------------------------
				// if the hit is not a followup servicing of a miss, decrement all lease registers
				// always renew the the accessed cache line's lease register
				if (hit_i) begin

					// miss->hit servicing - do not decrement (already done)
					if (miss_followup_reg) begin
						miss_followup_reg 				<= 1'b0;
						lease_registers[cache_addr_i] 	<= lease_saved_reg;
					
						if (miss_default_followup_reg)begin
							miss_default_followup_reg<=1'b0;
							default_flag_reg_array[cache_set_index][cache_addr_i]<=1'b1;
						end 
						else begin 
							default_flag_reg_array[cache_set_index][cache_addr_i]<=1'b0;
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
							lease_registers[cache_addr_i] 	<= lease_result; 			// reference instruction addr is a table match
							default_lease_counter<='b0; 
							default_flag_reg_array[cache_set_index][cache_addr_i]<=1'b0;
						end
						else begin
							if(~&(default_lease_counter))begin 
								default_lease_counter<=default_lease_counter+1'b1;
							end
							lease_registers[cache_addr_i] 			<= default_lease_reg; 		// reference instrction addr is not a table match so take default value
							default_reg 							<= 1'b1;
							default_flag_reg_array[cache_set_index][cache_addr_i] <=1'b1;
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
						default_lease_counter<='b0;
					end
					else if (!llt_hit & (default_lease_reg != 'b0)) begin
						state_reg 			<= ST_GENERATE_REPLACEMENT_ADDR;
						miss_followup_reg 	<= 1'b1;
						swap_reg 			<= 1'b1;
						lease_saved_reg 	<= default_lease_reg;
						default_reg 		<= 1'b1;
						miss_default_followup_reg<=1'b1;
						if(~&(default_lease_counter))begin 
							default_lease_counter<=default_lease_counter+1'b1;
						end
					end
					// if the reference that caused a miss has a zero lease then the request just needs to be serviced
					// this does not result in a follow up hit
					else begin
						done_reg 			<= 1'b1; 	// do not need additional cycles to generate a replacement address
						swap_reg 			<= 1'b0; 	// tell cache controller just to service the request, do not allocate it into cache
						if (!llt_hit) begin
							default_reg 	<= 1'b1; 	// if there was no table hit then a default lease of zero must have caused the condition so 
														// raise flag to record the occurrence
							if(~&(default_lease_counter))begin 
								default_lease_counter<=default_lease_counter+1'b1;
							end
						end
						else begin 
							default_lease_counter<='b0;
						end 
					end		
					
				end
			end

			ST_GENERATE_REPLACEMENT_ADDR: begin

				// no matter the selection method, address generation is finished in this step
				done_reg 	<= 1'b1;
				state_reg 	<= ST_NORMAL;

				// if the cache set is not full (from cold start) then use pointed to address
				if (!full_flags_reg[cache_set_index]) begin
					if(CACHE_SET_SIZE!=CACHE_BLOCK_CAPACITY)begin
						addr_reg<={cold_start_counter_regs[cache_set_index],cache_set_index};
					end
					else begin
						addr_reg<=cold_start_counter_regs[cache_set_index];
					end
					// determine if full
					if (cold_start_counter_regs[cache_set_index] == {(BW_CACHE_CAPACITY){1'b1}}) begin
						full_flags_reg[cache_set_index] <= 1'b1;
					end

					// arbitrarily increment
					cold_start_counter_regs[cache_set_index] <= cold_start_counter_regs[cache_set_index] + 1'b1;

				end
				// if cache is full, there is no expired leases, and there is a defaulted lease then replace the default
				else if (defaulted_replacement_addr_valid[cache_set_index] & !replacement_addr_valid[cache_set_index])
					if(CACHE_SET_SIZE!=CACHE_BLOCK_CAPACITY)begin
						addr_reg <= {defaulted_replacement_addr[cache_set_index],cache_set_index};
					end 
					else begin 
						addr_reg <= defaulted_replacement_addr[cache_set_index];
					end
				end
				// if the cache set is full (from cold start) and there is no expired line in the set then use random address
				else if (!replacement_addr_valid[cache_set_index]||&(default_lease_counter)) begin
					if(CACHE_SET_SIZE!=CACHE_BLOCK_CAPACITY)begin
						addr_reg<={lfsr_grp,cache_set_index};
					end
					else begin
						addr_reg<=lfsr_grp;
					end
					

					lfsr_en_reg 			<= 1'b1;
					random_eviction_reg    <=1'b1;
				end

				// if the cache set is full (from cold start) and there is at least one expired line in the set then 
				// use the replacement address generated from the encoding array
				else begin
					expired_reg 			<= 1'b1;
					if(CACHE_SET_SIZE!=CACHE_BLOCK_CAPACITY)begin
						addr_reg<={replacement_addr_arr[cache_set_index],cache_set_index};
					end
					else begin
						addr_reg<=replacement_addr_arr[cache_set_index];
					end
					
					// track multiple expired lines
					expired_multi_reg <= multi_vacancy_arr[cache_set_index];

				end
				
					

			end

		endcase
	end
end


endmodule