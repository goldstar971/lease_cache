module cache_performance_controller_sampler #(
	parameter CACHE_STRUCTURE 	=  	"",
	parameter CACHE_REPLACEMENT = 	""
)(
	input 	[1:0]		clock_i,
	input 			resetn_i,
	`ifdef DATA_POLICY_DLEASE
		input[31:0] phase_i,
	`endif    
	input [31:0]	 pc_ref_i,         
	input [`BW_CACHE_TAG-1:0] tag_ref_i,			
	input req_i,
	input 			hit_i, 				// logic high when there is a cache hit
	input 			miss_i, 			// logic high when there is the initial cache miss
	input 			writeback_i, 		// logic high when the cache writes a block back to externa memory
	input 			expired_i,			// logic high when lease cache replaces an expired block
	input 			expired_multi_i, 	// logic high when multiple cache lines are expired
	input 			defaulted_i, 		// logic high when lease cache renews using a default lease value
	input 	[31:0]	comm_i, 			// configuration signal	
	output 	[31:0] 	comm_o, 	 		// return value of comm_i
	output 			stall_o
);

// cache performance controller 
// ------------------------------------------------------------------------------
reg 	[31:0]	comm_o_reg;
reg 	[63:0]	counter_hit_reg,  		// when enabled counts times hit_i is logic high
				counter_miss_reg, 		// when enabled counts times miss_i is logic high
				counter_wb_reg; 		// when enabled counts times writeback_i is logic high

wire 	[31:0]		rui_interval, rui_refpc, rui_used, rui_count, rui_remaining, rui_target;
wire 	[63:0]		rui_trace;

wire buffer_full_flag,table_full_flag;
assign stall_o=buffer_full_flag | table_full_flag;
assign comm_o = comm_o_reg;

always @(posedge clock_i[0]) begin
	// reset state
	if (!resetn_i) begin
		comm_o_reg 				<= 'b0; 				// no configuration given by comm_i so just set return val reg to zero
		counter_hit_reg 		<= 'b0; 
		counter_miss_reg 		<= 'b0; 
		counter_wb_reg 			<= 'b0; 
	end
	// active state
	else begin

		// if enabled then upcount depending on flag thrown by cache
		if (comm_i[24] == 1'b1) begin
			if 		(hit_i) 			counter_hit_reg 		<= counter_hit_reg + 1'b1;
			if 		(miss_i) 			counter_miss_reg 		<= counter_miss_reg + 1'b1;
			if 		(writeback_i) 		counter_wb_reg 			<= counter_wb_reg + 1'b1;
		end

		// return value control
		// -------------------------------------------------------------------------
		case (comm_i[3:0])

			// primary outputs
			4'b0000: comm_o_reg <= counter_hit_reg[31:0];				// hits
			4'b0001: comm_o_reg <= counter_hit_reg[63:32];
			4'b0010: comm_o_reg <= counter_miss_reg[31:0]; 				// misses
			4'b0011: comm_o_reg <= counter_miss_reg[63:32];
			4'b0100: comm_o_reg <= counter_wb_reg[31:0]; 				// writebacks
			4'b0101: comm_o_reg <= counter_wb_reg[63:32];

			4'b0111: comm_o_reg <= rui_interval;
			4'b0110: comm_o_reg <= rui_refpc;
			4'b1000: comm_o_reg <= rui_used;
			4'b1001: comm_o_reg <= rui_count;
			4'b1010: comm_o_reg <= rui_remaining;
			4'b1011: comm_o_reg <= rui_trace[31:0];
			4'b1100: comm_o_reg <= rui_trace[63:32];
			4'b1101: comm_o_reg <= rui_target;

			4'b1110: comm_o_reg <= 'b0; 								// cache system id
			4'b1111: comm_o_reg <= buffer_full_flag;

			default comm_o_reg <= 'b0;
		endcase

	end
end

`ifdef DATA_POLICY_DLEASE
	lease_sampler_phase inst0(
		.clock_bus_i 		(clock_i 		), 
		.resetn_i 			(resetn_i 			), 
		.comm_i 			(comm_i 			), 
		.phase_i 			(phase_i 			),
		.req_i 				(req_i 		), 
		.pc_ref_i 			(pc_ref_i 				), 
		.tag_ref_i 			(tag_ref_i			),
		.ref_address_o 		(rui_refpc 		), 
		.ref_target_o 		(rui_target 		),
		.ref_interval_o 	(rui_interval 			), 
		.ref_trace_o 		(rui_trace 			), 
		.used_o 			(rui_used 			), 
		.count_o 			(rui_count 			), 
		.remaining_o 		(rui_remaining 		),
		.full_flag_o 		(buffer_full_flag 	), 
		.stall_o 			(table_full_flag 		)
	);
`else
	lease_sampler_final inst0(
		.clock_bus_i 		(clock_i 		), 
		.resetn_i 			(resetn_i 			), 
		.comm_i 			(comm_i 			), 
		.req_i 				(req_i 		), 
		.pc_ref_i 			(pc_ref_i 				), 
		.tag_ref_i 			(tag_ref_i			),
		.ref_address_o 		(rui_refpc 		), 
		.ref_target_o 		(rui_target 		),
		.ref_interval_o 	(rui_interval 			), 
		.ref_trace_o 		(rui_trace 			), 
		.used_o 			(rui_used 			), 
		.count_o 			(rui_count 			), 
		.remaining_o 		(rui_remaining 		),
		.full_flag_o 		(buffer_full_flag 	), 
		.stall_o 			(table_full_flag 		)
	);
`endif

endmodule