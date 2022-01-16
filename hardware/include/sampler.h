`ifndef _SAMPLER_H_
`define _SAMPLER_H_



`define 	BW_CACHE_TAG 		23 		// word address = [26:0] -> thus remove lower nibble to isolate block [26:4]

`define 	BW_CACHE_DATA 		32



`define 	N_BUFFER_SAMPLER 	13'h1FFF 	// buffer size



`ifdef MULTI_LEVEL_CACHE
	`define LSFR_PERIOD        65536
	`define SAMPLE_RATE_BW `CLOG2(`LSFR_PERIOD) 
//there are not enough resources on the cyclone V gt for the multi level lease cache 
	`ifndef L2_POLICY_DLEASE
		`define 	N_SAMPLER			256 			// table entries
		`define 	BW_SAMPLER 			8
		
	`else 
		`define 	N_SAMPLER			64 			// table entries
		`define 	BW_SAMPLER 			6

	`endif

`else 
	`define LSFR_PERIOD       65536
	`define SAMPLE_RATE_BW `CLOG2(`LSFR_PERIOD)+1
	`define 	N_SAMPLER			256 			// table entries
`define 	BW_SAMPLER 			8

`endif

`include "../../../internal/sampler_tracker/lease_sampler_all.v"
`include "../../../internal/sampler_tracker/bram_64kB_32b.v"
`include "../../../internal/sampler_tracker/bram_128kB_64b.v"
`include "../../../utilities/linear_feedback_shift_register/seeded_linear_shift_register_12b.v"
`include "../../../utilities/linear_feedback_shift_register/seeded_linear_shift_register_16b.v"


`endif // _CACHE_H_
