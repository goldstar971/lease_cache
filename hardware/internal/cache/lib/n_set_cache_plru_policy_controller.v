// cache address in the following form
// -----------------------------------------------
//
// 		[set | group]
//
//
// controller timing
// -----------------------------------------------
//
// 			--------- 		---------
// 			|		| 		| 		| 							(core)
// ----------       --------- 		----------
//
//
//	 				--------- 		---------
// 					|		| 		| 		| 					(cache controller)
// 	   	   ----------       --------- 		----------
//
//
// 						--------- 		---------
// 						|		| 		| 		| 				(srrip set controllers) - this module is just combinational logic for routing
// 			   ----------       --------- 		----------
//
//

module n_set_cache_plru_policy_controller #(
	parameter CACHE_BLOCK_CAPACITY = 0,
	parameter CACHE_SET_SIZE = 0 						
)(
	input 								clock_i,
	input 								resetn_i,
	input 								hit_i, 			// modules plru counter values
	input 								miss_i, 		// not used
	input 	[BW_CACHE_CAPACITY-1:0]		addr_i,
	output 								done_o, 		// logic high when replacement address generated - no cycle latency for plru, always logic high
	output 	[BW_CACHE_CAPACITY-1:0] 	addr_o 			// replacement address generated
);


// parameterizations
// ------------------------------------------------------------------------------------------
localparam BW_CACHE_CAPACITY 	= `CLOG2(CACHE_BLOCK_CAPACITY); 				// block addressible cache addresses

localparam BW_GRP 				=`CLOG2(CACHE_SET_SIZE);				
localparam BW_SET 				= 	BW_CACHE_CAPACITY-BW_GRP;
localparam N_GROUPS = 2**BW_GRP;
localparam N_SET = 2**BW_SET;


//always output done
assign done_o = 1'b1;


// replacement controller
//  ------------------------------------------------------------------------------------------



genvar g;
generate if(N_SET!=1)begin 
	// generic extractions
		wire 	[BW_SET-1:0]	addr_set_bus;
		wire 	[BW_GRP-1:0] 	addr_group_bus;
		assign addr_group_bus 	= addr_i[BW_SET+BW_GRP-1:BW_SET];
		assign addr_set_bus 	= addr_i[BW_SET-1:0];


	/// routing signals per each set
	wire 	[N_SET-1:0] 	enable_bus;
	wire 	[N_SET-1:0]	done_bus; 						// when high indicates that set_ptr_bus is valid
	wire 	[BW_GRP-1:0] 	group_ptr_bus [0:N_SET-1]; 	// individual line controllers produce this value, it is a pointer to the 
															// cache set item to be replaced


	// use a one-hot decoder to create control signals that drive the individual line controllers enable_i port
	one_hot_decoder #(
		.INPUT_BW 		(BW_SET 		)
	) group_dec_inst (
		.binary_i 		(addr_set_bus	),
		.encoding_o 	(enable_bus 	)
	);

	// route the individual controllers done signals (do not need to register because 
	// done signal only matters on a cache miss in which the inputs to this component are static)
	reg 				done_reg; 
	reg [BW_GRP-1:0]	grp_reg;

	
	assign addr_o = {grp_reg,addr_set_bus};

	integer i;

	always @(*) begin
		// default
		grp_reg		= 'b0;

		for (i = 0; i < N_SET; i = i + 1) begin
			if (i == addr_set_bus) begin
				grp_reg 	= group_ptr_bus[i];
			end
		end
	end


// array of individual PLRU controllers - 1 per each set
	for (g = 0; g < N_SET; g = g + 1) begin : Plru_controller_inst_array

	plru_line_controller #( 
		.N_LOCATIONS 		(CACHE_SET_SIZE 		) 
	) plru_branch_0(
		.clock_i 			(clock_i 				),
		.resetn_i 			(resetn_i 				),
		.enable_i 			(hit_i & enable_bus[g] 	),	
		.miss_i  			(miss_i),
		.addr_i 			(addr_group_bus 			), 	// set to update relative to
		.addr_o 			(group_ptr_bus[g] 		)
	);
	end
end
else begin 
		plru_line_controller #( 
		.N_LOCATIONS 		(CACHE_SET_SIZE 		) 
	) plru_branch_0(
		.clock_i 			(clock_i 				),
		.resetn_i 			(resetn_i 				),
		.enable_i 			(hit_i 				 	),	
		.miss_i  			(miss_i),
		.addr_i 			(addr_i 				), 	// set to update relative to
		.addr_o 			(addr_o	 				)
	);
end

endgenerate

endmodule 