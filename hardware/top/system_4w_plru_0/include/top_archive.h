`ifndef _TOP_H_
`define _TOP_H_

// not used options but should be integrated
// -------------------------------------------------------------------------------------------------
//`define SIMULATION_SYNTHESIS_ONLY


// general directories
// -------------------------------------------------------------------------------------------------
//`include "../../../include/riscv_v2.h"
//`include "../../../include/riscv.h"
`include "../../../include/cache.h"
`include "../../../include/utilities.h"


// synthesis configuration parameters
// -------------------------------------------------------------------------------------------------

// core
// ----------------------------------------------------
`define RISCV_PIPELINE


// cache 
// ----------------------------------------------------

//`define INST_CACHE_FA
//`define INST_CACHE_2WAY
`define INST_CACHE_4WAY
//`define INST_CACHE_8WAY
//`define INST_POLICY_RANDOM
`define INST_POLICY_FIFO
//`define INST_POLICY_LRU
//`define INST_POLICY_PLRU
//`define INST_POLICY_SRRIP
//`define INST_POLICY_LEASE

//`define DATA_CACHE_FA
//`define DATA_CACHE_2WAY
`define DATA_CACHE_4WAY
//`define DATA_CACHE_8WAY
//`define DATA_POLICY_RANDOM
`define DATA_POLICY_FIFO
//`define DATA_POLICY_LRU
//`define DATA_POLICY_PLRU
//`define DATA_POLICY_SRRIP
//`define DATA_POLICY_LEASE

`define INST_CACHE_BLOCK_CAPACITY 	128
`define DATA_CACHE_BLOCK_CAPACITY 	128


// derived configurations
// -------------------------------------------------------------------------------------------------

// core 
// ----------------------------------------------------
`ifdef RISCV_PIPELINE
	`include "../../../include/riscv_v2.h"
`else
	`include "../../../include/riscv.h"
`endif


// cache
// ----------------------------------------------------
`ifdef INST_CACHE_FA
	`define INST_CACHE_STRUCTURE 		`ID_CACHE_4WAY_SET_ASSOCIATIVE
`elsif INST_CACHE_2WAY
`elsif INST_CACHE_4WAY
`elsif INST_CACHE_8WAY


//`define INST_CACHE_BLOCK_CAPACITY 	128
//`define INST_CACHE_POLICY 			`ID_CACHE_FIFO
`define INST_CACHE_POLICY 			`ID_CACHE_SRRIP
//`define INST_CACHE_STRUCTURE 		`ID_CACHE_FULLY_ASSOCIATIVE
`define INST_CACHE_STRUCTURE 		`ID_CACHE_4WAY_SET_ASSOCIATIVE
`define INST_CACHE_INIT 			1'b0

//`define DATA_CACHE_BLOCK_CAPACITY 	128
//`define DATA_CACHE_POLICY 			`ID_CACHE_FIFO
`define DATA_CACHE_POLICY 			`ID_CACHE_SRRIP
//`define DATA_CACHE_STRUCTURE 		`ID_CACHE_FULLY_ASSOCIATIVE
`define DATA_CACHE_STRUCTURE 		`ID_CACHE_4WAY_SET_ASSOCIATIVE
`define DATA_CACHE_INIT 			1'b1


`define RISCV_PIPELINE


// preprocessor directives for instantiations
//`define INST_CACHE_FA
//`define DATA_CACHE_FA
//`define INST_CACHE_2WAY
//`define DATA_CACHE_2WAY
`define INST_CACHE_4WAY
`define DATA_CACHE_4WAY
//`define INST_CACHE_8WAY
//`define DATA_CACHE_8WAY


// SRRIP cache policy specific parameters
// -------------------------------------------------------------------------------------------------
`define SRRIP_BW 					3
`define SRRIP_INIT 					6


// lease cache specific parameters
// -------------------------------------------------------------------------------------------------
`define LEASE_LLT_ENTRIES 			128
`define LEASE_CONFIG_ENTRIES 		4 			// 0: default lease
												// 1: backup policy - not used (05/12/2020)
												// 2: pool 			- not used (05/12/2020)
												// 3: null 			- not used (05/12/2020)
`define LEASE_CONFIG_VAL_BW 		16
`define LEASE_REGISTER_BW 			24
`define LEASE_REF_ADDR_BW 			16


`endif // _TOP_H_
