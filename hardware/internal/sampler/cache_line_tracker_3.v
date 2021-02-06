module cache_line_tracker_3 #(
	parameter FS 		= 0,
	parameter N_LINES 	= 0
)(
	input 					clock_i, 			// controller updates on this clock (90 deg phase - so that it can stall the cache controller)
	input 					clock_memory_i, 	// embedded memories updates on this clock (180 deg phase - so that it updates prior to eviction bit update)
	input 					resetn_i,
	input 	[31:0]			config_i, 			// comm_i
	input 					request_i,
	input                 en_i, //if we are using the sampler or the standard cache metrics.
	input 	[N_LINES-1:0] 	expired_bits_0_i,
	input 	[N_LINES-1:0] 	expired_bits_1_i,
	input 	[N_LINES-1:0] 	expired_bits_2_i,

	output 					stall_o,
	output 	[31:0]			count_o,	 		// number of buffer entries to pull	

	// ports to performance controller comm_o switch
	output 	[127:0]			trace_o,
	output 	[N_LINES-1:0] 	expired_bits_0_o,
	output 	[N_LINES-1:0] 	expired_bits_1_o,
	output 	[N_LINES-1:0] 	expired_bits_2_o
);

// parameterizations
// --------------------------------------------------------------------------------------------------
//localparam BUFFER_LIMIT = 256*(2*10) / (512 / 8); 	// buffer capacity (B) divided by size of one sample
localparam BUFFER_LIMIT = 2**12;
localparam BW_BUFFER 	= `CLOG2(BUFFER_LIMIT);


// port mapping
// --------------------------------------------------------------------------------------------------
reg 	stall_reg;

assign stall_o 			= stall_reg;
assign count_o 			= buffer_addr_next_reg;
assign trace_o 			= trace_data_bus;

assign expired_bits_0_o = eviction_data_0_bus;
assign expired_bits_1_o = eviction_data_1_bus;
assign expired_bits_2_o = eviction_data_2_bus;


// internal signals
// --------------------------------------------------------------------------------------------------

// buffer control logic
// --------------------------------------
reg 				buffer_rw_bus,
					buffer_rw_reg;
reg [BW_BUFFER-1:0] buffer_addr_bus,
					buffer_addr_reg;

reg [BW_BUFFER:0]	buffer_addr_next_reg;

reg 				stall_delay_flag; 			// need a flag to stall the address switch so that last entry gets recorded


always @(posedge clock_memory_i) begin
	if (!resetn_i) begin
		buffer_rw_bus 	= 1'b0;
		buffer_addr_bus = 1'b0;
		stall_delay_flag = 1'b0;
	end
	else begin

		// access control
		// hardware has normal access to the buffer - can only be externally pulled from if
		// - no longer tracking (config[24] == 1'b0)
		// - is full (so that the host can read it and then clear it)
		if (config_i[24]) begin

			// if the buffer is not full then sampler has access to the buffer
			if (!stall_reg) begin
				stall_delay_flag = 1'b0;
				buffer_rw_bus 	= buffer_rw_reg;
				buffer_addr_bus = buffer_addr_reg;
			end

			else if (stall_reg & !stall_delay_flag) begin
				stall_delay_flag = 1'b1;
				buffer_rw_bus 	= buffer_rw_reg;
				buffer_addr_bus = buffer_addr_reg;
			end

			else begin
				buffer_rw_bus 	= 1'b0;
				buffer_addr_bus = config_i[BW_BUFFER-1+5:5];
			end
		end
		else begin
			buffer_rw_bus 	= 1'b0;
			buffer_addr_bus = config_i[BW_BUFFER-1+5:5];
		end
	end
end


// tracker logic
// --------------------------------------
reg [31:0]	sampling_counter_reg;
reg [127:0]	trace_counter_reg;

always @(posedge clock_i) begin
	if (!resetn_i) begin
		stall_reg 				= 1'b0;
		sampling_counter_reg 	= FS;
		buffer_addr_reg 		= 'b0;
		buffer_addr_next_reg 	= 'b0;
		trace_counter_reg 		<= 'b0;
		buffer_rw_reg 			= 1'b0;
	end
	else begin

		// defaults 
		buffer_rw_reg = 1'b0;

		// stall clear control
		if (config_i[23]) begin
			stall_reg 				= 1'b0;
			buffer_addr_reg 		= 'b0;
			buffer_addr_next_reg 	= 'b0;
		end

		// enable
		//
		// ---------------------------------
		if (config_i[24] & !stall_reg & en_i) begin

			// if there is a request then increment sampling counter
			if (request_i) begin
				trace_counter_reg 		<= trace_counter_reg + 1'b1;
				sampling_counter_reg 	= sampling_counter_reg - 1'b1; 
			end

			// if the counter is up then store the expired bit trace
			if (sampling_counter_reg == 'b0) begin

				// reset counter
				sampling_counter_reg 	= FS;

				// store into memory
				buffer_addr_reg 		= buffer_addr_next_reg[BW_BUFFER-1:0];
				buffer_addr_next_reg 	= buffer_addr_next_reg + 1'b1;
				//eviction_data_reg 		= expired_bits_i;

				eviction_data_0_reg 	= expired_bits_0_i;
				eviction_data_1_reg 	= expired_bits_1_i;
				eviction_data_2_reg 	= expired_bits_2_i;


				trace_data_reg 			= trace_counter_reg;
				buffer_rw_reg 			= 1'b1;

				// if buffer is full then stall the cache until it gets pulled
				if (buffer_addr_next_reg == BUFFER_LIMIT) begin
					stall_reg 			= 1'b1;
				end
			end
		end
	end
end

// memory instantiations
// --------------------------------------------------------------------------------------------------
wire 	[127:0]	eviction_data_0_bus,
				eviction_data_1_bus,
				eviction_data_2_bus;

reg 	[127:0]	eviction_data_0_reg,
				eviction_data_1_reg,
				eviction_data_2_reg;

memory_embedded #(
	.N_ENTRIES 	(BUFFER_LIMIT			), 	
	.BW_DATA 	(128					),
	.DEBUG 		(1						)
)mem_evictionbits0_inst(
	.clock_i 	(clock_memory_i 		),
	.wren_i 	(buffer_rw_bus 			),
	.addr_i 	(buffer_addr_bus 		),
	.data_i 	(eviction_data_0_reg 	),
	.data_o 	(eviction_data_0_bus 	)
);

memory_embedded #(
	.N_ENTRIES 	(BUFFER_LIMIT			), 	
	.BW_DATA 	(128					),
	.DEBUG 		(1						)
)mem_evictionbits1_inst(
	.clock_i 	(clock_memory_i 		),
	.wren_i 	(buffer_rw_bus 			),
	.addr_i 	(buffer_addr_bus 		),
	.data_i 	(eviction_data_1_reg 	),
	.data_o 	(eviction_data_1_bus 	)
);

memory_embedded #(
	.N_ENTRIES 	(BUFFER_LIMIT			), 	
	.BW_DATA 	(128					),
	.DEBUG 		(1						)
)mem_evictionbits2_inst(
	.clock_i 	(clock_memory_i 		),
	.wren_i 	(buffer_rw_bus 			),
	.addr_i 	(buffer_addr_bus 		),
	.data_i 	(eviction_data_2_reg 	),
	.data_o 	(eviction_data_2_bus 	)
);


wire 	[127:0]	trace_data_bus;
reg 	[127:0]	trace_data_reg;

memory_embedded #(
	.N_ENTRIES 	(BUFFER_LIMIT			),
	.BW_DATA 	(128					),
	.DEBUG 		(1						)
)mem_trace_inst(
	.clock_i 	(clock_memory_i 		),
	.wren_i 	(buffer_rw_bus 			),
	.addr_i 	(buffer_addr_bus 		),
	.data_i 	(trace_data_reg 		),
	.data_o 	(trace_data_bus 		)
);

endmodule