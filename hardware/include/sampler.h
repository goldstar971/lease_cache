`ifndef _SAMPLER_H_
`define _SAMPLER_H_



`define 	BW_CACHE_TAG 		20 		// word address = [23:0] -> thus remove lower nibble to isolate block [23:4]

`define 	BW_CACHE_DATA 		32

`define 	BW_LEASE_REGISTER 	9

//`define 	LEASE_VALUE_BASE_B 	26'h01FFFF00
//`define 	LEASE_VALUE_BASE_W 	24'h007FFFC0

`define 	LEASE_SAMPLER_FS_WADDR 	24'h007FFF79 	// last word in .lease_config section


//`define 	N_BUFFER_SAMPLER 	14'h3FFF 	// max number of pairs buffer can hold (256kB = 64kW, 64kW / 4words per pair )
`define 	N_BUFFER_SAMPLER 	13'h1FFF 	// buffer size


`define 	N_SAMPLER			64 			// table entries
`define 	BW_SAMPLER 			6



`include "../../../internal/sampler/cache_performance_controller_sampler.v"
`include "../../../internal/sampler/bram_64kB_32b.v"
`include "../../../internal/sampler/bram_128kB_64b.v"
`include "../../../internal/sampler/comparator_identity_20b.v"
`include "../../../internal/sampler/tag_match_encoder.v"

`ifdef DATA_POLICY_DLEASE
	`include "../../../internal/sampler/lease_sampler_phase.v"
	`include "../../../internal/cache/fully_associative/lease_scope/lease_dynamic_cache_fa_sampler.v"
	`include "../../../internal/cache/fully_associative/src/lease_cache_fa_controller.v"
`else
	`include "../../../internal/sampler/lease_sampler_final.v"
	`include "../../../internal/cache/fully_associative/src/lease_cache_fa_sampler.v"
	`include "../../../internal/cache/fully_associative/src/lease_cache_fa_controller.v"
`endif

`endif // _CACHE_H_
