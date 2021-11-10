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
// 						|		| 		| 		| 				(LSFR set controllers) - this module is just combinational logic for routing
// 			   ----------       --------- 		----------


module n_set_cache_random_policy_controller #(
	parameter CACHE_BLOCK_CAPACITY = 0,
	parameter CACHE_SET_SIZE = 0 						
)(
	input 								clock_i,
	input 								resetn_i,
	input 								hit_i, 			// modulates lru counter values
	input 								miss_i, 		// pulse trigger to generate a replacement address
	input 	[BW_CACHE_CAPACITY-1:0]		addr_i,
	output 								done_o, 		// logic high when replacement address generated
	output 	[BW_CACHE_CAPACITY-1:0] 	addr_o 			// replacement address generated
);

// parameterizations
// ------------------------------------------------------------------------------------------
localparam BW_CACHE_CAPACITY 	= `CLOG2(CACHE_BLOCK_CAPACITY); 				// block addressible cache addresses

localparam BW_SET 				=BW_CACHE_CAPACITY-`CLOG2(CACHE_SET_SIZE);				
localparam BW_GRP 				= 	BW_CACHE_CAPACITY-BW_SET;
localparam N_GROUPS = 2**BW_GRP;
localparam N_SET = 2**BW_SET;

// port mappings



// replacement controller
//  ------------------------------------------------------------------------------------------

// generic extractions


generate if(N_SET!=1) begin
	wire 	[BW_SET-1:0]	addr_set_bus;
	assign addr_set_bus 	= addr_i[BW_SET-1:0];
	assign addr_o = {lfsr_grp,addr_set_bus};
end
else begin
	assign addr_o = lfsr_grp;
end
endgenerate


assign done_o = 1'b1;




// only need 1 LFSR no matter how many sets


// -----------------------------------------------------------------
wire 	[11:0] 						lfsr_val;
wire 	[BW_GRP-1:0] 	lfsr_grp;
reg 								lfsr_en_reg;

assign lfsr_grp = lfsr_val[BW_GRP-1:0];

linear_shift_register_12b #(
	.SEED 			(12'b101000010001 ) 		
) lfsr_inst (
	.clock_i 		(~clock_i 			), 
	.resetn_i 		(resetn_i 			), 
	.enable_i 		(miss_i 		), 
	.result_o 		(lfsr_val 			)
);


endmodule 