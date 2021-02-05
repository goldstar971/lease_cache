`ifndef _TOP_H_
`define _TOP_H_

// general directories
// -------------------------------------------------------------------------------------------------
`include "../../../include/cache.h"
`include "../../../include/utilities.h"
`include "../../../external/uart_jtag/include/uart_jtag.h"

// synth. configuration parameters
// -------------------------------------------------------------------------------------------------

// not used but should be implemented in future
// ----------------------------------------------------
//`define SIMULATION_SYNTHESIS_ONLY


// core
// ----------------------------------------------------
`define RISCV_PIPELINE


// cache 
// ----------------------------------------------------

`define INST_CACHE_FA
//`define INST_CACHE_2WAY
//`define INST_CACHE_4WAY
//`define INST_CACHE_8WAY
//`define INST_POLICY_RANDOM
`define INST_POLICY_FIFO
//`define INST_POLICY_LRU
//`define INST_POLICY_PLRU
//`define INST_POLICY_SRRIP

//`define DATA_CACHE_FA
//`define DATA_CACHE_2WAY
//`define DATA_CACHE_4WAY
`define DATA_CACHE_8WAY
//`define DATA_POLICY_RANDOM
//`define DATA_POLICY_FIFO
//`define DATA_POLICY_LRU
//`define DATA_POLICY_PLRU
//`define DATA_POLICY_SRRIP
//`define DATA_POLICY_LEASE
`define DATA_POLICY_DLEASE

//`define LEASE_PRIORITY 							// gives eviction priority to defaulted leases

`define INST_CACHE_BLOCK_CAPACITY 		128
`define DATA_CACHE_BLOCK_CAPACITY 		128


// derived configurations (no touchy)
// -------------------------------------------------------------------------------------------------

// core 
// ----------------------------------------------------
`ifdef RISCV_PIPELINE
	`define RISCV_HART_INST riscv_hart_top 			// module name
	`include "../../../include/riscv_v2.h" 			// path to module dependencies
`else
	`define RISCV_HART_INST riscv_core_split 		// module name
	`include "../../../include/riscv.h" 			// path to module dependencies
`endif


// cache
// ----------------------------------------------------

// instruction cache structure
`ifdef INST_CACHE_FA
	`define INST_CACHE_STRUCTURE 		`ID_CACHE_FULLY_ASSOCIATIVE
	`define INSTRUCTION_CACHE_INST 		cache_fa
`elsif INST_CACHE_2WAY
	`define INST_CACHE_STRUCTURE 		`ID_CACHE_2WAY_SET_ASSOCIATIVE
	`define INSTRUCTION_CACHE_INST 		cache_2way
`elsif INST_CACHE_4WAY
	`define INST_CACHE_STRUCTURE 		`ID_CACHE_4WAY_SET_ASSOCIATIVE
	`define INSTRUCTION_CACHE_INST 		cache_4way
`elsif INST_CACHE_8WAY
	`define INST_CACHE_STRUCTURE 		`ID_CACHE_8WAY_SET_ASSOCIATIVE
	`define INSTRUCTION_CACHE_INST 		cache_8way
`endif


// instruction cache replacement policy
`ifdef INST_POLICY_RANDOM
	`define INST_CACHE_POLICY 			`ID_CACHE_RANDOM
	`define INST_CACHE_INIT 			1'b0
`elsif INST_POLICY_FIFO
	`define INST_CACHE_POLICY 			`ID_CACHE_FIFO
	`define INST_CACHE_INIT 			1'b0
`elsif INST_POLICY_LRU
	`define INST_CACHE_POLICY 			`ID_CACHE_LRU
	`define INST_CACHE_INIT 			1'b0
`elsif INST_POLICY_PLRU
	`define INST_CACHE_POLICY 			`ID_CACHE_PLRU
	`define INST_CACHE_INIT 			1'b0
`elsif INST_POLICY_SRRIP
	`define INST_CACHE_POLICY 			`ID_CACHE_SRRIP
	`define INST_CACHE_INIT 			1'b0
`endif


// data cache structure
`ifdef DATA_CACHE_FA
	`define DATA_CACHE_STRUCTURE 		`ID_CACHE_FULLY_ASSOCIATIVE

	// check lease cache
	`ifdef 	DATA_POLICY_LEASE
		`define DATA_CACHE_INST 				lease_cache_fa
		`define LEASE_POLICY_CONTROLLER_INST 	fa_cache_lease_policy_controller
	`elsif 	DATA_POLICY_DLEASE
		`define DATA_CACHE_INST 				lease_dynamic_cache_fa
		`define LEASE_POLICY_CONTROLLER_INST 	fa_cache_lease_policy_controller
	`else
		`define DATA_CACHE_INST 		cache_fa
	`endif

`elsif DATA_CACHE_2WAY
	`define DATA_CACHE_STRUCTURE 		`ID_CACHE_2WAY_SET_ASSOCIATIVE
	`ifdef 	DATA_POLICY_LEASE
		`define DATA_CACHE_INST 				lease_cache_2way
		`define LEASE_POLICY_CONTROLLER_INST 	set_cache_lease_policy_controller
	`elsif 	DATA_POLICY_DLEASE
		`define DATA_CACHE_INST 				lease_dynamic_cache_2w
		`define LEASE_POLICY_CONTROLLER_INST 	set_cache_lease_policy_controller
	`else
		`define DATA_CACHE_INST 		cache_2way
	`endif

`elsif DATA_CACHE_4WAY
	`define DATA_CACHE_STRUCTURE 		`ID_CACHE_4WAY_SET_ASSOCIATIVE
	`ifdef 	DATA_POLICY_LEASE
		`define DATA_CACHE_INST 				lease_cache_4way
		`define LEASE_POLICY_CONTROLLER_INST 	set_cache_lease_policy_controller
	`elsif 	DATA_POLICY_DLEASE
		`define DATA_CACHE_INST 				lease_dynamic_cache_4w
		`define LEASE_POLICY_CONTROLLER_INST 	set_cache_lease_policy_controller
	`else
		`define DATA_CACHE_INST 		cache_4way
	`endif

`elsif DATA_CACHE_8WAY
	`define DATA_CACHE_STRUCTURE 		`ID_CACHE_8WAY_SET_ASSOCIATIVE
	`ifdef 	DATA_POLICY_LEASE
		`define DATA_CACHE_INST 				lease_cache_8way
		`define LEASE_POLICY_CONTROLLER_INST 	set_cache_lease_policy_controller
	`elsif 	DATA_POLICY_DLEASE
		`define DATA_CACHE_INST 				lease_dynamic_cache_8w
		`define LEASE_POLICY_CONTROLLER_INST 	set_cache_lease_policy_controller
	`else
		`define DATA_CACHE_INST 		cache_8way
	`endif
`endif

// data cache replacement policy
`ifdef DATA_POLICY_RANDOM
	`define DATA_CACHE_POLICY 			`ID_CACHE_RANDOM
	`define DATA_CACHE_INIT 			1'b1
`elsif DATA_POLICY_FIFO
	`define DATA_CACHE_POLICY 			`ID_CACHE_FIFO
	`define DATA_CACHE_INIT 			1'b1
`elsif DATA_POLICY_LRU
	`define DATA_CACHE_POLICY 			`ID_CACHE_LRU
	`define DATA_CACHE_INIT 			1'b1
`elsif DATA_POLICY_PLRU
	`define DATA_CACHE_POLICY 			`ID_CACHE_PLRU
	`define DATA_CACHE_INIT 			1'b1
`elsif DATA_POLICY_SRRIP
	`define DATA_CACHE_POLICY 			`ID_CACHE_SRRIP
	`define DATA_CACHE_INIT 			1'b1
`elsif DATA_POLICY_LEASE
	`define DATA_CACHE_POLICY 			`ID_CACHE_LEASE
	`define DATA_CACHE_INIT 			1'b0
`elsif DATA_POLICY_DLEASE
	`define DATA_CACHE_POLICY 			`ID_CACHE_DLEASE
	`define DATA_CACHE_INIT 			1'b0
`endif


// SRRIP cache policy specific parameters
// -------------------------------------------------------------------------------------------------
`define SRRIP_BW 						3
`define SRRIP_INIT 						6


// lease cache specific parameters
// -------------------------------------------------------------------------------------------------
`define LEASE_LLT_ENTRIES 				128
`define LEASE_CONFIG_ENTRIES 			4 			// 0: default lease
													// 1: backup policy - not used (05/12/2020)
													// 2: pool 			- not used (05/12/2020)
													// 3: null 			- not used (05/12/2020)
`define LEASE_CONFIG_VAL_BW 			16
`define LEASE_VALUE_BW 					24
`define LEASE_REF_ADDR_BW 				16


`endif // _TOP_H_
