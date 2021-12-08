`ifndef _TOP_H_
`define _TOP_H_


// general directories
// -------------------------------------------------------------------------------------------------
`include "../../../include/mem.h"
`include "../../../include/utilities.h"
`include "../../../include/logic_components.h"
`include "../../../utilities/embedded_memory/memory_embedded.v"
`include "../../../include/cache.h"


// cache 
// ----------------------------------------------------
//Uncomment desired eviction policy and cache associativity

`define INST_CACHE_FA
//`define INST_CACHE_2WAY
//`define INST_CACHE_4WAY
//`define INST_CACHE_8WAY
//`define INST_CACHE_16WAY
//`define INST_POLICY_RANDOM
//`define INST_POLICY_FIFO
//`define INST_POLICY_LRU
`define INST_POLICY_PLRU
//`define INST_POLICY_SRRIP
//`define INST_POLICY_MRU

`define DATA_CACHE_FA
//`define DATA_CACHE_2WAY
//`define DATA_CACHE_4WAY
//`define DATA_CACHE_8WAY
//`define DATA_CACHE_16WAY
//`define DATA_POLICY_RANDOM
//`define DATA_POLICY_FIFO
//`define DATA_POLICY_LRU
`define DATA_POLICY_PLRU
//`define DATA_POLICY_SRRIP
//`define DATA_POLICY_MRU
//`define DATA_POLICY_DLEASE

//`define MULTI_LEVEL_CACHE

`ifdef MULTI_LEVEL_CACHE
	`define L2_CACHE_FA
//`define L2_CACHE_2WAY
//`define L2_CACHE_4WAY
//`define L2_CACHE_8WAY
//`define L2_CACHE_16WAY
//`define L2_POLICY_RANDOM
//`define L2_POLICY_FIFO
//`define L2_POLICY_LRU
//`define L2_POLICY_PLRU
//`define L2_POLICY_SRRIP
//`define L2_POLICY_MRU
  `define L2_POLICY_DLEASE
	
`endif



//`define LEASE_PRIORITY 							// gives eviction priority to defaulted leases




// derived configurations L2 cache
// -------------------------------------------------------------------------------------------------

`define L2_CACHE_INST                    cache_n_set_L2_all

`ifdef L2_POLICY_DLEASE
	`define L2_CACHE_CONTROLLER            n_set_lease_dynamic_cache_controller_tracker_L2
`else
	`define L2_CACHE_CONTROLLER            n_set_cache_controller_L2
`endif

//true for both levels
`define LEASE_POLICY_CONTROLLER_INST 	n_set_cache_lease_policy_controller_tracker
//define L1 
`ifndef MULTI_LEVEL_CACHE
`define INSTRUCTION_CACHE_INST cache_n_set_all
`define DATA_CACHE_INST cache_n_set_all
`else 
`define INSTRUCTION_CACHE_INST n_set_cache_multi_level
`define DATA_CACHE_INST n_set_cache_multi_level
`endif
// core 
// ----------------------------------------------------

	`define RISCV_HART_INST riscv_hart_top 			// module name
	`include "../../../include/riscv_v2_2.h" 			// path to module dependencies



// cache
// ----------------------------------------------------

// instruction cache structure
`ifdef INST_CACHE_FA
	`define INST_CACHE_STRUCTURE 		`ID_CACHE_FULLY_ASSOCIATIVE
`elsif INST_CACHE_2WAY
	`define INST_CACHE_STRUCTURE 		`ID_CACHE_2WAY_SET_ASSOCIATIVE
`elsif INST_CACHE_4WAY
	`define INST_CACHE_STRUCTURE 		`ID_CACHE_4WAY_SET_ASSOCIATIVE
`elsif INST_CACHE_8WAY
	`define INST_CACHE_STRUCTURE 		`ID_CACHE_8WAY_SET_ASSOCIATIVE
`elsif INST_CACHE_16WAY
	`define INST_CACHE_STRUCTURE 		`ID_CACHE_16WAY_SET_ASSOCIATIVE
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
`elsif INST_POLICY_MRU
	`define INST_CACHE_POLICY 			`ID_CACHE_MRU
	`define INST_CACHE_INIT 			1'b0
`endif






// data cache structure
`ifdef DATA_CACHE_FA
	`define DATA_CACHE_STRUCTURE 		`ID_CACHE_FULLY_ASSOCIATIVE
`elsif DATA_CACHE_2WAY
	`define DATA_CACHE_STRUCTURE 		`ID_CACHE_2WAY_SET_ASSOCIATIVE
`elsif DATA_CACHE_4WAY
	`define DATA_CACHE_STRUCTURE 		`ID_CACHE_4WAY_SET_ASSOCIATIVE
`elsif DATA_CACHE_8WAY
	`define DATA_CACHE_STRUCTURE 		`ID_CACHE_8WAY_SET_ASSOCIATIVE
`elsif DATA_CACHE_16WAY
	`define DATA_CACHE_STRUCTURE 		`ID_CACHE_16WAY_SET_ASSOCIATIVE
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
`elsif DATA_POLICY_MRU
	`define DATA_CACHE_POLICY 			`ID_CACHE_MRU
	`define DATA_CACHE_INIT 			1'b1
`elsif DATA_POLICY_DLEASE
	`define DATA_CACHE_POLICY 			`ID_CACHE_DLEASE
	`define DATA_CACHE_INIT 			1'b0
`endif


`ifdef MULTI_LEVEL_CACHE
	///L2 cache structure
	`ifdef L2_CACHE_FA
		`define L2_CACHE_STRUCTURE 		`ID_CACHE_FULLY_ASSOCIATIVE
	`elsif L2_CACHE_2WAY
		`define L2_CACHE_STRUCTURE 		`ID_CACHE_2WAY_SET_ASSOCIATIVE
	`elsif L2_CACHE_4WAY
		`define L2_CACHE_STRUCTURE 		`ID_CACHE_4WAY_SET_ASSOCIATIVE
	`elsif L2_CACHE_8WAY
		`define L2_CACHE_STRUCTURE 		`ID_CACHE_8WAY_SET_ASSOCIATIVE
	`elsif L2_CACHE_16WAY
		`define L2_CACHE_STRUCTURE 		`ID_CACHE_16WAY_SET_ASSOCIATIVE
	`endif

	//L2 cache replacement policy
	`ifdef L2_POLICY_RANDOM
		`define L2_CACHE_POLICY 			`ID_CACHE_RANDOM
		`define L2_CACHE_INIT 			1'b1
	`elsif L2_POLICY_FIFO
		`define L2_CACHE_POLICY 			`ID_CACHE_FIFO
		`define L2_CACHE_INIT 			1'b1
	`elsif L2_POLICY_LRU
		`define L2_CACHE_POLICY 			`ID_CACHE_LRU
		`define L2_CACHE_INIT 			1'b1
	`elsif L2_POLICY_PLRU
		`define L2_CACHE_POLICY 			`ID_CACHE_PLRU
		`define L2_CACHE_INIT 			1'b1
	`elsif L2_POLICY_SRRIP
		`define L2_CACHE_POLICY 			`ID_CACHE_SRRIP
		`define L2_CACHE_INIT 			1'b1
	`elsif L2_POLICY_MRU
		`define L2_CACHE_POLICY 			`ID_CACHE_MRU
		`define L2_CACHE_INIT 			1'b1
	`elsif L2_POLICY_DLEASE
		`define L2_CACHE_POLICY 			`ID_CACHE_DLEASE
		`define L2_CACHE_INIT 			1'b0
	`endif
`endif


// SRRIP cache policy specific parameters
// -------------------------------------------------------------------------------------------------
`define SRRIP_BW 						3
`define SRRIP_INIT 						6


// lease cache specific parameters
// -------------------------------------------------------------------------------------------------
`define LEASE_LLT_ENTRIES 				128
`define LEASE_CONFIG_ENTRIES 			5			//0: default lease
													//1: long lease value
													//2: short lease probability
													//3: num of references in phase
													//4: dual lease ref (word address)
`define LEASE_CONFIG_VAL_BW 			32
`define LEASE_VALUE_BW					24
`define LEASE_REF_ADDR_BW 				27
`define BW_PERCENTAGE                   9



`define INST_CACHE_BLOCK_CAPACITY 		128
`define DATA_CACHE_BLOCK_CAPACITY 		128
`define L2_CACHE_BLOCK_CAPACITY         512


//figure out set size
`ifdef INST_CACHE_FA
	`define INST_CACHE_SET_SIZE	`INST_CACHE_BLOCK_CAPACITY
`else 
	`define INST_CACHE_SET_SIZE	`INST_CACHE_STRUCTURE>>24
`endif
`ifdef L2_CACHE_FA
	`define L2_CACHE_SET_SIZE	`L2_CACHE_BLOCK_CAPACITY
`else 
	`define L2_CACHE_SET_SIZE	`L2_CACHE_STRUCTURE>>24
`endif
`ifdef DATA_CACHE_FA
	`define DATA_CACHE_SET_SIZE	`DATA_CACHE_BLOCK_CAPACITY
`else 
	`define DATA_CACHE_SET_SIZE	`DATA_CACHE_STRUCTURE>>24
`endif

//adding tracker and sampler stuff

//only meaningful for lease cache 
//`define TRACKER
`ifdef TRACKER
	`include "../../../include/tracker.h"
`endif

`define SAMPLER
`ifdef SAMPLER
	`include "../../../include/sampler.h"
`endif 


//adding lease cache stuff
`ifdef L2_POLICY_DLEASE  
		`include "../../../internal/cache/lib/lease_lookup_table.v"
		`include "../../../internal/cache/lib/lease_probability_controller.v"
`elsif DATA_POLICY_DLEASE
		`include "../../../internal/cache/lib/lease_lookup_table.v"
		`include "../../../internal/cache/lib/lease_probability_controller.v"
`endif
`include "../../../include/cache_components.h"


//adding cache level  specific files
`ifdef MULTI_LEVEL_CACHE
	`include "../../../internal/system/internal_system_2_multi_level.v"
	`include "../../../internal/system_controller/src/memory_controller_internal_2level.v"
	`include "../../../internal/system_controller/src/txrx_buffer_L2_L1.v"
`else 
	`include "../../../internal/system/internal_system_2.v"
	`include "../../../internal/system_controller/src/memory_controller_internal.v"
`endif

//mischelaneous stuff used by both levels

	`include "../../../internal/system_controller/src/txrx_buffer.v"
	`include "../../../peripheral/src/peripheral_system_3.v"


//comms stuff
`include "../../../include/comms.h"








`endif // _TOP_H_
