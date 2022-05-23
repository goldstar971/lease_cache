module cache_performance_controller_all_L2 #(
	parameter CACHE_STRUCTURE 	=  	"",
	parameter CACHE_REPLACEMENT = 	"",
	parameter CACHE_BLOCK_CAPACITY = ""
)(	
	input 	[1:0]		clock_i,
	input 			resetn_i,
	`ifdef SAMPLER
	input[31:0] phase_i,   
	input [31:0]	 pc_ref_i,         
	input [`BW_CACHE_TAG-1:0] tag_ref_i,
	`endif
	input          swap_i,
	input 			req_i,
	input 			hit_i, 				// logic high when there is a cache hit
	input 			miss_i, 			// logic high when there is the initial cache miss
	input 			writeback_i, 		// logic high when the cache writes a block back to externa memory
	input 			expired_i,			// logic high when lease cache replaces an expired block
	input 			expired_multi_i, 	// logic high when multiple cache lines are expired
	input 			defaulted_i, 		// logic high when lease cache renews using a default lease value
	input           rand_evict_i,       // logic high when random eviction occurs in lease cache
	input 	[31:0]	comm_i, 			// configuration signal	
	output 	[31:0] 	comm_o, 	 		// return value of comm_i
	output 			stall_o,
`ifdef TRACKER
	input 	[CACHE_BLOCK_CAPACITY-1:0]	expired_flags_0_i,
	input 	[CACHE_BLOCK_CAPACITY-1:0]	expired_flags_1_i,
	input 	[CACHE_BLOCK_CAPACITY-1:0]	expired_flags_2_i,
`endif
	input  [1:0] select_data_record,
	input  [18:0]     rate_shift_seed_i
);
localparam REF_COUNT_BW = 48;

reg 	[31:0]	comm_o_reg0,comm_o_reg1,comm_o_reg2,comm_o_reg3;
reg swap_store;

wire enable_tracker, enable_eviction_tracker, enable_sampler, tracker_stall_o,sampler_stall_o, buffer_full_flag,table_full_flag,
eviction_tracker_stall_o;


`ifdef TRACKER
wire 	[CACHE_BLOCK_CAPACITY-1:0]	eviction_bit_0_bus,
				eviction_bit_1_bus,
				eviction_bit_2_bus;
				wire  [1:0] eviction_status_bus;
`endif

wire 	[REF_COUNT_BW-1:0]	trace_bus,trace_bus2;
wire 	[31:0]	count_bus,count_bus2;


reg 	[63:0]	counter_walltime_reg,	// when enabled counts "wall time" - actually it counts cycles
				counter_hit_reg,  		// when enabled counts times hit_i is logic high
				counter_miss_reg, 		// when enabled counts times miss_i is logic high
				counter_wb_reg, 		// when enabled counts times writeback_i is logic high
				counter_expired_reg, 	// counts times expired_i is logic high
				counter_mexpired_reg, 	// counts times multi_expired_i is logic high
`ifdef L2_POLICY_DLEASE
				counter_swap_reg, //counts the number of times a zero lease was assigned
`endif
				counter_defaulted_reg, 	// counts references that result in default leases
				counter_rand_evic_reg,
				counter_default_misses; //counts number of misses that are due to default leases
reg		[REF_COUNT_BW-1:0]		ref_count;

wire 	[31:0]		rui_interval, rui_refpc, rui_used, rui_count, rui_remaining, rui_target;
wire 	[63:0]		rui_trace;








`ifdef TRACKER 
	`ifdef SAMPLER
		assign enable_sampler = (!select_data_record[1] & select_data_record[0]);
		assign sampler_stall_o=buffer_full_flag | table_full_flag;
		assign enable_eviction_tracker= (select_data_record[1]&select_data_record[0]);
		assign enable_tracker = (select_data_record[1] & !select_data_record[0]);
		assign stall_o=(enable_tracker) ? tracker_stall_o : (enable_sampler) ? sampler_stall_o : (enable_eviction_tracker)
		? eviction_tracker_stall_o : 1'b0;
		
		//choose between cache statistics, sampler, tracker, or eviction_tracker
		assign comm_o = (select_data_record==2'b00) ? comm_o_reg0 : (select_data_record==2'b01) ? comm_o_reg1 :
	(select_data_record==2'b10) ? comm_o_reg2 : comm_o_reg3;
	`else 
	assign enable_eviction_tracker= (select_data_record[1]&select_data_record[0]);
		assign enable_tracker = (select_data_record[1] & !select_data_record[0]);
		assign stall_o=(enable_tracker) ? tracker_stall_o : (enable_eviction_tracker) ? eviction_tracker_stall_o
		: 1'b0;
		//choose between cache statistics,  tracker
		assign comm_o = (select_data_record==2'b00) ? comm_o_reg0 : (select_data_record==2'b11) ? comm_o_reg3 : comm_o_reg2; 
	`endif
`else
	`ifdef SAMPLER
		assign enable_sampler = (!select_data_record[1] & select_data_record[0]);
		assign sampler_stall_o=buffer_full_flag | table_full_flag;
		assign stall_o= (enable_sampler) ? sampler_stall_o : 1'b0;
		//choose between cache statistics or sampler
		assign comm_o = (select_data_record==2'b01) ? comm_o_reg1 : comm_o_reg0;
	`else 
	 	assign stall_o=1'b0;
	 	assign comm_o = comm_o_reg0;
	 `endif
`endif

`ifdef SAMPLER
	wire [31:0] pc_bus;
	assign pc_bus= {phase_i[7:0],pc_ref_i[23:0]};
`endif 

always @(posedge clock_i[0]) begin
	if (!resetn_i) begin
		comm_o_reg0 				<= 'b0; 				// no configuration given by comm_i so just set return val reg to zero
		counter_hit_reg 		<= 'b0; 
		counter_miss_reg 		<= 'b0; 
		counter_wb_reg 			<= 'b0; 
		counter_walltime_reg 	<= 'b0;
		counter_expired_reg 	<= 'b0;
		counter_mexpired_reg 	<= 'b0;
		counter_defaulted_reg 	<= 'b0;
		counter_rand_evic_reg 	<= 'b0;
		counter_default_misses  <= 'b0;
		ref_count <='b0;
		`ifdef L2_POLICY_DLEASE
		counter_swap_reg<='b0;
		swap_store <=1'b0;
		`endif
	end

	else begin
		//these metrics don't interfere with anything, so always record them.
		if (comm_i[24] == 1'b1) begin
			if 		(hit_i) 			counter_hit_reg 		<= counter_hit_reg + 1'b1;
			if 		(miss_i) 			counter_miss_reg 		<= counter_miss_reg + 1'b1;
			if 		(writeback_i) 		counter_wb_reg 			<= counter_wb_reg + 1'b1;
			if 		(expired_i) 		counter_expired_reg 	<= counter_expired_reg + 1'b1;
			if 		(expired_multi_i) 	counter_mexpired_reg 	<= counter_mexpired_reg + 1'b1;
			if 		(defaulted_i) 		counter_defaulted_reg 	<= counter_defaulted_reg + 1'b1;
			if      (rand_evict_i)      counter_rand_evic_reg   <= counter_rand_evic_reg + 1'b1;
			if      (miss_i&defaulted_i) counter_default_misses <=counter_default_misses+1'b1;
			`ifdef L2_POLICY_DLEASE
				swap_store<=swap_i;
			//always strobed even if no lease cache
			if       (!swap_i&&swap_store!=swap_i)     counter_swap_reg <=counter_swap_reg+1'b1;  //increments when there is a zero lease assigned (swaps is equal to the number of misses minus the number of zero leases)
			`endif
			// always increment wall-timer
			counter_walltime_reg <= counter_walltime_reg + 1'b1;
			if (req_i) ref_count<=ref_count+1'b1;
		end
		`ifdef SAMPLER
		case (comm_i[3:0])

			// primary outputs
			4'b0000: comm_o_reg1 <= counter_hit_reg[31:0];				// hits
			4'b0001: comm_o_reg1 <= counter_hit_reg[63:32];
			4'b0010: comm_o_reg1 <= counter_miss_reg[31:0]; 				// misses
			4'b0011: comm_o_reg1 <= counter_miss_reg[63:32];
			4'b0100: comm_o_reg1 <= counter_wb_reg[31:0]; 				// writebacks
			4'b0101: comm_o_reg1 <= counter_wb_reg[63:32];

			4'b0111: comm_o_reg1 <= rui_interval;
			4'b0110: comm_o_reg1 <= rui_refpc;
			4'b1000: comm_o_reg1 <= rui_used;
			4'b1001: comm_o_reg1 <= rui_count;
			4'b1010: comm_o_reg1 <= rui_remaining;
			4'b1011: comm_o_reg1 <= rui_trace[31:0];
			4'b1100: comm_o_reg1 <= rui_trace[63:32];
			4'b1101: comm_o_reg1 <= rui_target;

			4'b1110: comm_o_reg1 <= 'b0; 								// cache system id
			4'b1111: comm_o_reg1 <= buffer_full_flag;
			default comm_o_reg1 <= 'b0;
		endcase
		`endif
	`ifdef TRACKER
		case(comm_i[5:0])

			6'b000000: 	comm_o_reg2 <= eviction_bit_0_bus[31:0];
			6'b000001:	comm_o_reg2 <= eviction_bit_0_bus[63:32];
			6'b000010:	comm_o_reg2 <= eviction_bit_0_bus[95:64];
			6'b000011:	comm_o_reg2 <= eviction_bit_0_bus[127:96];
			6'b000100: 	comm_o_reg2 <= eviction_bit_0_bus[159:128];
			6'b000101:	comm_o_reg2 <= eviction_bit_0_bus[191:160];
			6'b000110:	comm_o_reg2 <= eviction_bit_0_bus[223:192];
			6'b000111:	comm_o_reg2 <= eviction_bit_0_bus[255:224];
			6'b001000: 	comm_o_reg2 <= eviction_bit_0_bus[287:256];
			6'b001001:	comm_o_reg2 <= eviction_bit_0_bus[319:288];
			6'b001010:	comm_o_reg2 <= eviction_bit_0_bus[351:320];
			6'b001011:	comm_o_reg2 <= eviction_bit_0_bus[383:352];
			6'b001100: 	comm_o_reg2 <= eviction_bit_0_bus[415:384];
			6'b001101:	comm_o_reg2 <= eviction_bit_0_bus[447:416];
			6'b001110:	comm_o_reg2 <= eviction_bit_0_bus[479:448];
			6'b001111:	comm_o_reg2 <= eviction_bit_0_bus[511:480];
			6'b010000: 	comm_o_reg2 <= eviction_bit_1_bus[31:0];
			6'b010001:	comm_o_reg2 <= eviction_bit_1_bus[63:32];
			6'b010010:	comm_o_reg2 <= eviction_bit_1_bus[95:64];
			6'b010011:	comm_o_reg2 <= eviction_bit_1_bus[127:96];
			6'b010100: 	comm_o_reg2 <= eviction_bit_1_bus[159:128];
			6'b010101:	comm_o_reg2 <= eviction_bit_1_bus[191:160];
			6'b010110:	comm_o_reg2 <= eviction_bit_1_bus[223:192];
			6'b010111:	comm_o_reg2 <= eviction_bit_1_bus[255:224];
			6'b011000: 	comm_o_reg2 <= eviction_bit_1_bus[287:256];
			6'b011001:	comm_o_reg2 <= eviction_bit_1_bus[319:288];
			6'b011010:	comm_o_reg2 <= eviction_bit_1_bus[351:320];
			6'b011011:	comm_o_reg2 <= eviction_bit_1_bus[383:352];
			6'b011100: 	comm_o_reg2 <= eviction_bit_1_bus[415:384];
			6'b011101:	comm_o_reg2 <= eviction_bit_1_bus[447:416];
			6'b011110:	comm_o_reg2 <= eviction_bit_1_bus[479:448];
			6'b011111:	comm_o_reg2 <= eviction_bit_1_bus[511:480];
			6'b100000: 	comm_o_reg2 <= eviction_bit_2_bus[31:0];
			6'b100001:	comm_o_reg2 <= eviction_bit_2_bus[63:32];
			6'b100010:	comm_o_reg2 <= eviction_bit_2_bus[95:64];
			6'b100011:	comm_o_reg2 <= eviction_bit_2_bus[127:96];
			6'b100100: 	comm_o_reg2 <= eviction_bit_2_bus[159:128];
			6'b100101:	comm_o_reg2 <= eviction_bit_2_bus[191:160];
			6'b100110:	comm_o_reg2 <= eviction_bit_2_bus[223:192];
			6'b100111:	comm_o_reg2 <= eviction_bit_2_bus[255:224];
			6'b101000: 	comm_o_reg2 <= eviction_bit_2_bus[287:256];
			6'b101001:	comm_o_reg2 <= eviction_bit_2_bus[319:288];
			6'b101010:	comm_o_reg2 <= eviction_bit_2_bus[351:320];
			6'b101011:	comm_o_reg2 <= eviction_bit_2_bus[383:352];
			6'b101100: 	comm_o_reg2 <= eviction_bit_2_bus[415:384];
			6'b101101:	comm_o_reg2 <= eviction_bit_2_bus[447:416];
			6'b101110:	comm_o_reg2 <= eviction_bit_2_bus[479:448];
			6'b101111:	comm_o_reg2 <= eviction_bit_2_bus[511:480];
			6'b110000: 	comm_o_reg2 <= trace_bus[31:0];
			6'b110001:	comm_o_reg2 <= trace_bus[47:32];
			6'b110100: 	comm_o_reg2 <= count_bus;
			6'b110101: 	comm_o_reg2 <= {{31'b0},tracker_stall_o};
			6'b110110: 	comm_o_reg2 <= counter_hit_reg[31:0];
			6'b110111: 	comm_o_reg2 <= counter_hit_reg[63:32];

			default: 	comm_o_reg2 <= 'b0;
		endcase
		case (comm_i[2:0]) 
			3'b000:  comm_o_reg3 <= eviction_status_bus;
			3'b001:  comm_o_reg3 <= trace_bus2[31:0];
			3'b010:  comm_o_reg3 <= trace_bus2[47:32];
			3'b011:  comm_o_reg3 <= count_bus2;
			3'b100:  comm_o_reg3 <= {{31'b0},eviction_tracker_stall_o};
			default: comm_o_reg3 <= 'b0;
		endcase 


	`endif

		case (comm_i[4:0])

			// primary outputs
			5'b00000: comm_o_reg0 <= counter_hit_reg[31:0];				// hits
			5'b00001: comm_o_reg0 <= counter_hit_reg[63:32];
			5'b00010: comm_o_reg0 <= counter_miss_reg[31:0]; 				// misses
			5'b00011: comm_o_reg0 <= counter_miss_reg[63:32];
			5'b00100: comm_o_reg0 <= counter_wb_reg[31:0]; 				// write0acks
			5'b00101: comm_o_reg0 <= counter_wb_reg[63:32];
			5'b00110: comm_o_reg0 <= counter_walltime_reg[31:0]; 			// duration (cycles)
			5'b00111: comm_o_reg0 <= counter_walltime_reg[63:32];
			5'b01000: comm_o_reg0 <= counter_expired_reg[31:0]; 			// expired lease replacements
			5'b01001: comm_o_reg0 <= counter_expired_reg[63:32];
			5'b01010: comm_o_reg0 <= counter_defaulted_reg[31:0]; 		// defaulted lease renewals
			5'b01011: comm_o_reg0 <= counter_defaulted_reg[63:32];
			5'b01100: comm_o_reg0 <= counter_mexpired_reg[31:0]; 			// multiple leases expired at eviction
			5'b01101: comm_o_reg0 <= counter_mexpired_reg[63:32];
			5'b10000: comm_o_reg0 <= counter_default_misses[31:0];
			5'b10001: comm_o_reg0 <= counter_default_misses[63:32];
			5'b10010: comm_o_reg0 <= counter_rand_evic_reg[31:0];
			5'b10011: comm_o_reg0 <= counter_rand_evic_reg[63:32]; 
			// cache identification
			5'b01111: comm_o_reg0 <= CACHE_STRUCTURE | CACHE_REPLACEMENT;
		

			default comm_o_reg0 <= 'b0;
		endcase
	end
end

//tracker
`ifdef TRACKER
cache_line_tracker_4 #(
	.COUNTER_BW         (REF_COUNT_BW),
	.FS 				( 0					),
	.N_LINES 	 		(CACHE_BLOCK_CAPACITY 	)
) tracker_inst (
	.clock_i  			(!clock_i[1]				), 		// phase = 90 deg		
	.clock_memory_i 	(clock_i[0]			), 	 	// phase = 180 deg
	.resetn_i 			(resetn_i 				),
	.config_i 			(comm_i 				), 		
	.request_i 			(req_i 				),
	.en_i               (enable_tracker),
	.expired_bits_0_i 	(expired_flags_0_i 		),
	.expired_bits_1_i 	(expired_flags_1_i 		),
	.expired_bits_2_i 	(expired_flags_2_i 		),
	.stall_o 			(tracker_stall_o 		),
	.count_o 			(count_bus 				),	 			
	.trace_o 			(trace_bus 				),
	.expired_bits_0_o 	(eviction_bit_0_bus 	),
	.expired_bits_1_o 	(eviction_bit_1_bus 	),
	.expired_bits_2_o 	(eviction_bit_2_bus 	),
	.rate_i 			(rate_shift_seed_i),
	.reference_counter_i(ref_count)

);
eviction_status_tracker #(
	.COUNTER_BW (REF_COUNT_BW)
	) eviction_tracker_inst (
	.clock_i  			(!clock_i[1]				), 		// phase = 90 deg		
	.clock_memory_i 	(clock_i[0]			), 	 	// phase = 180 deg
	.resetn_i 			(resetn_i 				),
	.config_i 			(comm_i 				), 		
	.request_i 			(req_i 				),
	.en_i               (enable_eviction_tracker),
	.stall_o 			(eviction_tracker_stall_o 		),
	.count_o 			(count_bus2 				),	 			
	.trace_o 			(trace_bus2 			),
	.reference_counter_i(ref_count),
	.multi_expiry_flag_i(expired_multi_i),
	.random_evict_flag_i(rand_evict_i),
	.eviction_status_o (eviction_status_bus),
	.expiry_flag_i      (expired_i)
);
`endif
//sampler
`ifdef SAMPLER
	lease_sampler_all #(
	.COUNTER_BW (REF_COUNT_BW)
	) inst0(
		.clock_bus_i 		(clock_i 		), 
		.resetn_i 			(resetn_i 			), 
		.comm_i 			(comm_i 			),
		.en_i     			(enable_sampler),
		.req_i 				(req_i 		), 
		.pc_ref_i 			(pc_bus 				), 
		.tag_ref_i 			(tag_ref_i			),
		.ref_address_o 		(rui_refpc 		), 
		.ref_target_o 		(rui_target 		),
		.ref_interval_o 	(rui_interval 			), 
		.ref_trace_o 		(rui_trace 			), 
		.used_o 			(rui_used 			), 
		.count_o 			(rui_count 			), 
		.remaining_o 		(rui_remaining 		),
		.full_flag_o 		(buffer_full_flag 	), 
		.reference_counter_i(ref_count),
		.rate_shift_seed_i     (rate_shift_seed_i),
		.stall_o 			(table_full_flag 		)
	);
`endif

endmodule






