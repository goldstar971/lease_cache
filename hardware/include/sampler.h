`ifndef _SAMPLER_H_
`define _SAMPLER_H_



`define 	BW_CACHE_TAG 		23 		// word address = [26:0] -> thus remove lower nibble to isolate block [26:4]

`define 	BW_CACHE_DATA 		32

`define 	BW_LEASE_REGISTER 	9



`define 	N_BUFFER_SAMPLER 	13'h1FFF 	// buffer size




`ifdef MULTI_LEVEL_CACHE
	`define SAMPLE_RATE_BW `CLOG2(256)
	`define 	N_SAMPLER			256 			// table entries
`define 	BW_SAMPLER 			8
`define TAG_MATCH_ENCODER_INST tag_match_encoder_8b
`else 
	`define SAMPLE_RATE_BW `CLOG2(256)
	`define 	N_SAMPLER			256 			// table entries
`define 	BW_SAMPLER 			8
`define TAG_MATCH_ENCODER_INST tag_match_encoder_8b
`endif


`include "../../../internal/sampler/lease_sampler_all.v"
`include "../../../internal/sampler/bram_64kB_32b.v"
`include "../../../internal/sampler/bram_128kB_64b.v"
`include "../../../internal/sampler/tag_match_encoder_6b.v"
`include "../../../internal/sampler/tag_match_encoder_7b.v"
`include "../../../internal/sampler/tag_match_encoder_8b.v"
`include "../../../internal/sampler/tag_match_encoder_9b.v"
`include "../../../internal/sampler/pe_valid_match.v"
`include "../../../internal/sampler/bram_2048_entries_32b.v"
`include "../../../utilities/linear_feedback_shift_register/linear_shift_register_12b.v"

`endif // _CACHE_H_
