
// Random sampling - LFSR
// unused RI's denoted by random numbers 
module lease_sampler_all(

	// general pins
	input 	[1:0]				clock_bus_i, 		// clock[0] = 180deg, clock[1] = 270deg
	input 						resetn_i, 			// active low
	input 	[31:0]				comm_i, 			// generic comm port in
	input    en_i,  //if tracking or gathering cache statistics don't sample
	`ifdef DATA_POLICY_DLEASE
		input 	[31:0] 				phase_i,
	`endif
	//input 	[31:0]				offset_i, 			// sample offset 
	//input 						clear_i,			// when high clears out the buffer

	// input pins
	input 						req_i,						
	input 	[31:0]				pc_ref_i,
	input 	[23:0] 				addr_ref_i,
	input 	[`BW_CACHE_TAG-1:0]	tag_ref_i,

	// output pins
	output 	[31:0]				ref_address_o,
	output 	[31:0]				ref_interval_o,
	output 	[63:0]				ref_trace_o,
	output 	[31:0] 				ref_target_o,
	output 	[31:0]				used_o,				// number of total rui's generated - limited by capacity
	output 	[31:0]				count_o, 			// number of total rui's generated - ignoring capacity
	output 	[31:0]				remaining_o,
	output 						full_flag_o, 		// goes high when buffer is full
	output 						stall_o 			// goes high when the table is full
);

// internal signals
// -------------------------------------------------------------

// mux control of the buffer
wire 	[31:0]	ref_interval, ref_address, ref_target;
wire 	[63:0]	ref_trace;
reg 	[12:0]	add_sampler;
reg 	[12:0]	add_sampler_reg;
reg 			rw_sampler;

reg 			table_writeout_flag;

// input control
always @(*) begin

	// if enabled processor has priority to write, if buffer full then permission switches to allow user to read out the buffer
	if (comm_i[24]) begin
		// if buffer full then give priority to comm
		if (full_flag_o) begin
			add_sampler = comm_i[16:4];
			rw_sampler = 1'b0;
		end
		else begin
			add_sampler = add_sampler_reg;
			rw_sampler = rw_reg;
		end
	end
	// when logging not enabled by core, user has full permission if writeout flag not set
	else begin
		if (!table_writeout_flag) begin
			add_sampler = comm_i[16:4];
			rw_sampler = 1'b0;
		end
		else begin
			add_sampler = add_sampler_reg;
			rw_sampler = rw_reg;
		end
	end

end

//assign add_sampler = (comm_i[24] == 1'b1) ? add_sampler_reg : comm_i[18:4];

// output control logic - if requested address is not filled then overwrite output to null to prevent false positive
// (bram retains value even when reset - fpga needs to be reconfig'd)
assign ref_interval_o 	= (add_sampler <= add_sampler_reg) ? ref_interval 	: 'b0; 
assign ref_address_o 	= (add_sampler <= add_sampler_reg) ? ref_address 	: 'b0; 
assign ref_trace_o 		= (add_sampler <= add_sampler_reg) ? ref_trace 		: 'b0; 
assign ref_target_o 	= (add_sampler <= add_sampler_reg) ? ref_target 	: 'b0; 

// buffer memory
reg 							rw_reg;
reg 	[31:0]					data_interval_reg, data_address_reg, target_address_reg;
reg 	[63:0]					data_trace_reg;

bram_64kB_32b interval_fifo	(.address(add_sampler), .clock(clock_bus_i[1]), .data(data_interval_reg), .wren(rw_sampler), .q(ref_interval));
bram_64kB_32b address_fifo	(.address(add_sampler), .clock(clock_bus_i[1]), .data(data_address_reg), .wren(rw_sampler), .q(ref_address));
bram_128kB_64b trace_fifo 	(.address(add_sampler), .clock(clock_bus_i[1]), .data(data_trace_reg), .wren(rw_sampler), .q(ref_trace));

bram_64kB_32b target_fifo	(.address(add_sampler), .clock(clock_bus_i[1]), .data(target_address_reg), .wren(rw_sampler), .q(ref_target));

// tag translation
// -----------------------------------------------------

// memory components
integer 						i;
reg 	[`BW_CACHE_TAG-1:0] 	tag_mem[0:`N_SAMPLER-1]; 	// for tag -> $add translation
//reg 	[31:0]					target_mem[0:`N_SAMPLER-1];	// rui recording
reg 	[31:0]					pc_mem[0:`N_SAMPLER-1];		// rui recording
reg 	[31:0] 					counters[0:`N_SAMPLER-1];	// rui recording

reg 	[`BW_SAMPLER-1:0]		add_stack[0:`N_SAMPLER-1]; 	// open address stack for cache
reg 	[`N_SAMPLER-1:0]		valid_bits;
wire 	[`N_SAMPLER-1:0] 		match_bits;
wire 							hit_flag, full_flag, actual_match;
//reg	[`BW_SAMPLER-1:0] 		match_index;
wire 	[`BW_SAMPLER-1:0] 		match_index;
reg 	[`BW_SAMPLER-1:0] 		add_stack_ptr;

genvar j;
generate 
	for (j = 0; j < `N_SAMPLER; j = j + 1'b1) begin : tag_lookup_array
		comparator_identity_20b comp_inst(tag_ref_i, tag_mem[j], match_bits[j]);
	end
endgenerate

tag_match_encoder tag_match((match_bits&valid_bits),match_index);


//match_index==0 both when no bit in match_bits is set i.e., no match and when the match is the bottom entry i.e., match_bits[0]=1
	assign actual_match=|({match_index,match_bits[0]});
assign hit_flag = (actual_match)? valid_bits[match_index] : 1'b0;
/* always @(*) begin
	match_index = 'b0;
	for (i = 0; i < `N_SAMPLER; i = i + 1'b1) begin
		if (match_bits[i] & valid_bits[i]) match_index = i[`BW_SAMPLER-1:0];
	end
end

assign hit_flag = |(match_bits & valid_bits); */


// full flag dependent on table entries
assign full_flag = &(valid_bits);
assign stall_o = full_flag;

reg 			lfsr_enable;
wire 	[8:0]	lfsr_output;
linear_shift_register_9b shift_reg0(.clock_i(clock_bus_i[0]), .resetn_i(resetn_i), .enable_i(lfsr_enable), .result_o(lfsr_output));


// sampling rate controller
// ----------------------------------------------------------------------
reg 	[8:0]	fs_counter_reg;			// controls when a new ref is brought into LAT
reg 	[31:0]	n_rui_total_reg; 		// total number of intervals generated
reg 	[12:0]	n_rui_buffer_reg;		// number of intervals stored in buffer - resets when clearing the table
reg 	[31:0]	n_remaining_reg;

reg 	[63:0]	data_trace_running_reg;



reg 	[1:0]				state_reg;
reg 	[31:0]				rui_oldest_value_reg;
reg 	[`BW_SAMPLER-1:0]	rui_oldest_index_reg;
reg 	[`BW_SAMPLER-1:0]	rui_oldest_index_search_reg;

localparam ST_NORMAL 		=	1'b0;
localparam ST_FIND_OLDEST	= 	1'b1;

assign count_o 		= n_rui_total_reg;
assign used_o 		= add_sampler_reg + 1'b1;	// indexed from zero so add one
assign remaining_o 	= n_remaining_reg;

// full flag out dependent on add_sampler_reg
assign full_flag_o = (add_sampler_reg == `N_BUFFER_SAMPLER) ? 1'b1 : 1'b0; 		// when this goes high, stalls the cache which in turn stalls the core
																				// so that the host can pull the buffer data


wire [31:0] pc_bus;
assign pc_bus=pc_ref_i;
always @(posedge clock_bus_i[0]) begin
	// reset state
	if (!resetn_i) begin
		for (i = 0; i < `N_SAMPLER; i = i + 1'b1) begin
			tag_mem[i] = 'b0;
			pc_mem[i] = 'b0;
			counters[i] = 'b0;
			add_stack[i] = i[`BW_SAMPLER-1:0];
		end

		valid_bits = 'b0;
		rw_reg = 1'b0;
		data_interval_reg 	= 'b0;
		data_address_reg 	= 'b0;
		target_address_reg 	= 'b0;
		add_sampler_reg = 'b0;
		add_stack_ptr = 'b0;
		//rand_rep_ptr = 'b0;
		//add_ptr = 'b0;

		fs_counter_reg = 'b0;
		n_rui_total_reg = 'b0;
		n_rui_buffer_reg = 'b0;
		//offset_counter_reg = 'b0;
		n_remaining_reg = 'b0;

		data_trace_reg = 'b0;
		data_trace_running_reg = 'b0;
		lfsr_enable = 'b0;

		// upon a full sampler dump of the oldest value, these registers are used to store the pertinent data
		rui_oldest_value_reg = 'b0;
		rui_oldest_index_reg = 'b0;
		state_reg 			 = ST_NORMAL;
		table_writeout_flag <= 1'b0;
	end

	// active state
	else begin

		// clear condition
		if (comm_i[23]) begin
			add_sampler_reg = 'b0;
			n_rui_buffer_reg = 'b0;
		end

		if (comm_i[22]) begin
			//state_reg = ST_DUMP_TABLE;
			table_writeout_flag <= 1'b1;
			rui_oldest_index_reg <= 'b0; 	// use this to writeout the entire table to buffer
		end

		// default signals
		rw_reg = 1'b0;
		lfsr_enable = 1'b0;

		if(en_i) begin
			// only operate if metrics are enabled by processor
			// -----------------------------------------------------------------------
			if (comm_i[24] == 1'b1) begin

				case(state_reg)

					ST_NORMAL: begin

						// only execute this substate sequence if not full
						if (!full_flag) begin

							// reference is valid so track
							if (req_i) begin

								// increment intervals of all valid lines
								for (i = 0; i < `N_SAMPLER; i = i + 1) begin
									if (valid_bits[i] == 1'b1) begin
										if (counters[i] != 32'h7FFFFFFF) begin
											counters[i] = counters[i] + 1'b1;
										end
									end
								end

								// check hit/miss
								if (hit_flag) begin

									// record metric
									//n_rui_total_reg = n_rui_total_reg + 1'b1; 		// don't think it is necessary

									// if the buffer is not yet full then write result to it
									// note: this is a precautionary guard, if running RUN_SAMPLER command
									// then the host should see the full flag and clear the buffer from its commands


									if (add_sampler_reg != `N_BUFFER_SAMPLER) begin

										// point to next buffer address
										add_sampler_reg 	= n_rui_buffer_reg;
										n_rui_buffer_reg 	= n_rui_buffer_reg + 1'b1;

										// write result to buffer
										rw_reg 				= 1'b1;
										data_address_reg 	= pc_mem[match_index];
										data_interval_reg 	= counters[match_index];
										data_trace_reg 		= data_trace_running_reg;
									
										target_address_reg  = tag_mem[match_index];
									
									end



									// honestly don't remember what this is used for, pretty sure its not important 
									// for sampler variants that signal when it is full
									//else begin
									//	n_remaining_reg = n_remaining_reg + 1'b1;
									//end

									// invalidate entry in LAT
									valid_bits[match_index] = 1'b0;

									// push address onto stack
									add_stack_ptr = add_stack_ptr - 1'b1;
									add_stack[add_stack_ptr] = match_index;
									
								end

								// post increment trace
								data_trace_running_reg = data_trace_running_reg + 1'b1;


								// fifo replacement check - full scale is 9b - 256 avg
								// --------------------------------------------------------
							
								if (fs_counter_reg[8:0] == lfsr_output[8:0]) begin

									// generate new random number
									lfsr_enable 	= 1'b1;
									fs_counter_reg 	= 'b0;

									// import in a new entry - add_stack_ptr points to next open location
									if (!full_flag) begin
									
										tag_mem	[ add_stack[add_stack_ptr] ] 	= tag_ref_i;
										
										`ifdef DATA_POLICY_DLEASE
											pc_mem	[ add_stack[add_stack_ptr] ] 	= {phase_i[7:0],pc_bus[23:0]};
										`else 
											pc_mem[ add_stack[add_stack_ptr] ] 	= pc_bus;
										`endif

										counters[ add_stack[add_stack_ptr] ] 	= 'b0;
										valid_bits[ add_stack[add_stack_ptr] ] 	= 1'b1;
										add_stack_ptr = add_stack_ptr + 1'b1;
									end
									
								end
								else begin
									fs_counter_reg = fs_counter_reg + 1'b1;
								end
							end
						end

						// special case - full
						// ------------------------------------------------------------------------------------------------------
						// upon reaching capacity scan through the table entries and find the largest entries - negate them
						// and write them to the buffer
						else begin
							state_reg 					= ST_FIND_OLDEST;
							rui_oldest_index_reg 		<= 'b0; 				// initialize to first table value
							rui_oldest_value_reg 		<= counters['b0]; 		// 
							rui_oldest_index_search_reg <= 'b1; 				// begin checking at first entry
						end
					end

					ST_FIND_OLDEST: begin
						// overwrite saved value if greater
						if (counters[rui_oldest_index_search_reg] > rui_oldest_value_reg) begin
							rui_oldest_index_reg <= rui_oldest_index_search_reg;
							rui_oldest_value_reg <= counters[rui_oldest_index_search_reg];
						end

						// if checked the entire table then evict the oldest entry, and throw the address on the stack
						if (rui_oldest_index_search_reg == 'b0) begin

							// point to next buffer address
							//n_rui_total_reg 	= n_rui_total_reg + 1'b1;
							add_sampler_reg 	= n_rui_buffer_reg;
							n_rui_buffer_reg 	= n_rui_buffer_reg + 1'b1;

							// save value to stack as a negative number
							rw_reg 				= 1'b1;
							data_address_reg 	= pc_mem[rui_oldest_index_reg];
							data_interval_reg 	= ~counters[rui_oldest_index_reg]+1'b1; 	// 2's complement
							data_trace_reg 		= data_trace_running_reg;
							target_address_reg  = tag_mem[rui_oldest_index_reg];

							// invalidate the entry and put it on the address stack
							valid_bits[rui_oldest_index_reg] = 1'b0;
							add_stack_ptr = add_stack_ptr - 1'b1;
							add_stack[add_stack_ptr] = rui_oldest_index_reg;

							// cycle back to nominal operation
							state_reg = ST_NORMAL;
						end

						// if not checked then reincrement (will recheck the zero-ith entry but no issue with doing so)
						else begin
							rui_oldest_index_search_reg <= rui_oldest_index_search_reg + 1'b1;
						end

					end

				endcase
				
			end

			// ----------------------------------------------------------------------------------------------------------------
			// table writout
			// ----------------------------------------------------------------------------------------------------------------
			else begin

				if (table_writeout_flag) begin

					// only store table entry if valid
					if (valid_bits[rui_oldest_index_reg]) begin

						//n_rui_total_reg = n_rui_total_reg + 1'b1; 		// don't think it is necessary

						// register buffer address
						add_sampler_reg 	= n_rui_buffer_reg;
						n_rui_buffer_reg 	= n_rui_buffer_reg + 1'b1;

						// write it to buffer
						rw_reg 				= 1'b1;
						data_address_reg 	= pc_mem[rui_oldest_index_reg];
						data_interval_reg 	= ~counters[rui_oldest_index_reg]+1'b1; 	// 2's complement
						//data_interval_reg 	= 32'hFFFFFFFF;
						data_trace_reg 		= data_trace_running_reg;
						target_address_reg  = tag_mem[rui_oldest_index_reg];

						valid_bits[rui_oldest_index_reg] = 1'b0; 			// prevent double read out

					end

					// increment index
					rui_oldest_index_reg <= rui_oldest_index_reg + 1'b1;

					// if done writing all out then just return to idle
					if (rui_oldest_index_reg == {`BW_SAMPLER{1'b1}}) begin
						table_writeout_flag <= 1'b0;
					end

				end
			end // if (comm[24])
		end
	end
end

endmodule