module srrip_line_controller #(
	parameter N_LOCATIONS = 0,
	parameter RRPV_REG_WIDTH = 0,
	parameter RRPV_REG_INS = 0
)(
	input 						clock_i,
	input 						resetn_i,
	input 						enable_i,  					// so that in set associative caches the controller can be disabled
	input 	[BW_LOCATIONS-1:0] 	addr_i,
	input 						hit_i,
	input 						miss_i,
	output 						done_o,
	output 	[BW_LOCATIONS-1:0] 	addr_o
);

// parameterizations
// ----------------------------------------------------------------
localparam BW_LOCATIONS = `CLOG2(N_LOCATIONS);


// SRRIP registers and logic
// ----------------------------------------------------------------
reg 						done_reg;
reg [BW_LOCATIONS-1:0]		addr_reg;

assign done_o = done_reg;
assign addr_o = addr_reg;

reg [N_LOCATIONS-1:0]		first_hit_reg; 		 		 	// stores a flag that indicates if a location has been referenced at least once	
reg [RRPV_REG_WIDTH-1:0] 	rrpv_regs[0:N_LOCATIONS-1]; 	// stores the running RRPV

wire [N_LOCATIONS-1:0] 		rrpv_flag;
genvar k;
generate
	for (k = 0; k < N_LOCATIONS; k = k + 1) begin :rrpv_flags_inst
		assign rrpv_flag[k] = &rrpv_regs[k]; 				// set a flag when an RRPV register is at capacity
	end
endgenerate

// priority encoder to find first occurrence of at capacity RRPV register
wire	[BW_LOCATIONS-1:0]	rrpv_encoder_addr;
priority_encoder lease_rep_encoder(.clk(),.rst(),.oht(rrpv_flag),.bin(rrpv_encoder_addr),.vld());


// SRRIP controller logic
// ----------------------------------------------------------------
reg 	state_reg,
		flag_increment_rrpv_reg;
integer i;

localparam ST_NOMINAL 				= 1'b0;
localparam ST_INCREMENT_RRPV_REGS 	= 1'b1;

always @(posedge clock_i) begin
	if (!resetn_i) begin
		state_reg 				= ST_NOMINAL;
		flag_increment_rrpv_reg = 1'b0;
		done_reg 				= 1'b0;
		addr_reg 				= 'b0;
		first_hit_reg 			= 'b0;
		for (i = 0; i < N_LOCATIONS; i = i + 1) rrpv_regs[i] = {RRPV_REG_WIDTH{1'b1}};
	end
	else begin

		// default signals
		flag_increment_rrpv_reg = 1'b0;

		if (enable_i) begin

			// sequencing control
			case(state_reg)
				ST_NOMINAL: begin
					// hit_i and miss_i drive done_reg low
					//if (hit_i | miss_i) done_reg = 1'b0;

					// cache hit
					if (hit_i) begin
						// if already had its first hit then reset counter to zero
						if (first_hit_reg[addr_i]) begin
							rrpv_regs[addr_i] = 'b0;
						end
						// if just brought into cache initialize to preset value
						else begin
							rrpv_regs[addr_i] 		= RRPV_REG_INS[RRPV_REG_WIDTH-1:0];
							first_hit_reg[addr_i] 	= 1'b1;
						end
					end

					// cache miss
					if (miss_i) begin
						// existing at capacity register - take encoder output
						if (|rrpv_flag) begin
							done_reg = 1'b1;
							addr_reg = rrpv_encoder_addr;
							first_hit_reg[rrpv_encoder_addr] = 1'b0; 	// location to be overwritten so reset first hit flag
						end
						// no existing expired register - must increment all
						else begin
							done_reg 				= 1'b0;
							state_reg 				= ST_INCREMENT_RRPV_REGS;
							flag_increment_rrpv_reg = 1'b1;
						end
					end
				end

				ST_INCREMENT_RRPV_REGS: begin
					if (|rrpv_flag) begin
						done_reg 							= 1'b1;
						addr_reg 							= rrpv_encoder_addr;
						state_reg 							= ST_NOMINAL;
						first_hit_reg[rrpv_encoder_addr] 	= 1'b0;
						
					end
					else flag_increment_rrpv_reg = 1'b1;
				end	
			endcase

			// rrpv_reg incrementing control
			if (flag_increment_rrpv_reg) begin
				for (i = 0; i < N_LOCATIONS; i = i + 1) begin
					if (rrpv_regs[i] != {RRPV_REG_WIDTH{1'b1}}) rrpv_regs[i] = rrpv_regs[i] + 1'b1;
				end
			end

		end

	end
end


endmodule