`ifndef _TOP_H_
`define _TOP_H_


// general directories
// -------------------------------------------------------------------------------------------------
`include "../../../include/cache.h"
`include "../../../include/utilities.h"
`include "../../../include/logic_components.h"
`include "../../../utilities/embedded_memory/memory_embedded.v"



// cache 
// ----------------------------------------------------

`define INST_CACHE_FA
//`define INST_CACHE_2WAY
//`define INST_CACHE_4WAY
//`define INST_CACHE_8WAY
//`define INST_POLICY_RANDOM
//`define INST_POLICY_FIFO
//`define INST_POLICY_LRU
`define INST_POLICY_PLRU
//`define INST_POLICY_SRRIP

`define DATA_CACHE_FA
//`define DATA_CACHE_2WAY
//`define DATA_CACHE_4WAY
//`define DATA_CACHE_8WAY
//`define DATA_POLICY_RANDOM
//`define DATA_POLICY_FIFO
//`define DATA_POLICY_LRU
//`define DATA_POLICY_PLRU
//`define DATA_POLICY_SRRIP
`define DATA_POLICY_DLEASE

//`define MULTI_LEVEL_CACHE

`ifdef MULTI_LEVEL_CACHE
	`define L2_CACHE_INST_FA
	`define L2_CACHE_STRUCTURE  `ID_CACHE_FULLY_ASSOCIATIVE
	`define L2_CACHE_POLICY_PLRU
	//`define L2_CACHE_POLICY_DLEASE
	
`endif



//`define LEASE_PRIORITY 							// gives eviction priority to defaulted leases

`define INST_CACHE_BLOCK_CAPACITY 		128
`define DATA_CACHE_BLOCK_CAPACITY 		128
`define L2_CACHE_BLOCK_CAPACITY         512

`define FLOAT_INSTRUCTIONS 


// derived configurations L2 cache
// -------------------------------------------------------------------------------------------------


`ifdef L2_CACHE_POLICY_DLEASE
	`define L2_CACHE_POLICY  `ID_CACHE_DLEASE
	`define LEASE_POLICY_CONTROLLER_INST 	fa_cache_lease_policy_controller_tracker_2
	`define L2_CACHE_INST                    L2_cache_fa_all
	`define L2_CACHE_CONTROLLER            lease_dynamic_cache_fa_controller_tracker_L2
	`define L2_CACHE_INIT 1'b0
`endif
`ifdef L2_CACHE_POLICY_PLRU
	`define L2_CACHE_POLICY  `ID_CACHE_PLRU
	`define L2_CACHE_INST                   L2_cache_fa_all
	`define L2_CACHE_CONTROLLER             cache_fa_controller_L2
	`define L2_CACHE_INIT 1'b1
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
	`define LEASE_POLICY_CONTROLLER_INST 	fa_cache_lease_policy_controller_tracker_2
	// check lease cache
	`ifdef 	DATA_POLICY_DLEASE
		`define DATA_CACHE_INST 				cache_fa_all
		`define DATA_CACHE_CONTROLLER           lease_dynamic_cache_fa_controller_tracker
	`elsif MULTI_LEVEL_CACHE
		`define DATA_CACHE_CONTROLLER           cache_fa_controller_multi_level
		`define DATA_CACHE_INST                 cache_fa
	`else 
		`define DATA_CACHE_CONTROLLER           cache_fa_controller
		`define DATA_CACHE_INST 				cache_fa_all

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
`define LEASE_CONFIG_ENTRIES 			5			//0: default lease
													//1: long lease value
													//2: short lease probability
													//3: num of references in phase
													//4: dual lease ref (word address)
`define LEASE_CONFIG_VAL_BW 			32
`define LEASE_VALUE_BW 					32
`define LEASE_REF_ADDR_BW 				29
`define BW_PERCENTAGE                   9




`include "../../../include/sampler.h"




//adding cache level and cache type specific files
`ifdef MULTI_LEVEL_CACHE
	`include "../../../internal/system/internal_system_2_multi_level.v"
	`include "../../../internal/system_controller/src/memory_controller_internal_2level.v"
	`include "../../../internal/cache_2level/L2_cache_fa_all.v"
	`ifdef L2_CACHE_POLICY_DLEASE
		`include "../../../include/tracker.h"
		`include "../../../internal/cache_2level/lease_dynamic_cache_fa_controller_tracker_L2.v"
		`include "../../../internal/cache/lib/lease_lookup_table.v"
		`include "../../../internal/cache/lib/lease_probability_controller.v"
	`endif
	`ifdef L2_CACHE_POLICY_PLRU
		`include "../../../internal/cache_2level/cache_fa_controller_L2.v"
	`endif
	`include "../../../internal/cache_2level/cache_performance_controller_all_L2.v"
	`include "../../../peripheral/src/peripheral_system_3.v"
	`include "../../../internal/cache_2level/tag_memory_fa_L2.v"
	`include "../../../internal/system_controller/src/txrx_buffer_L2_L1.v"
	`include "../../../internal/system_controller/src/txrx_buffer.v"
	`include "../../../internal/cache/lib/plru_line_controller.v"
	`ifdef INST_CACHE_FA
		`include "../../../internal/cache_2level/cache_fa_controller_multi_level.v"
		`include "../../../internal/cache_2level/cache_fa.v"
		`include "../../../internal/cache/fully_associative/src/tag_memory_fa.v"
	`else 
		`include "../../../internal/cache_2level/cache_2way_controller_multi_level.v"
		`include "../../../internal/cache_2level/cache_2way_multi_level.v"
		`include "../../../internal/cache/lib/set_cache_plru_policy_controller.v"
		`include "../../../internal/cache/two_way_set_associative/src/tag_memory_2way.v"
	`endif
`else 
	`ifdef DATA_POLICY_DLEASE
		`include "../../../include/tracker.h"
		`include "../../../internal/cache/lib/lease_lookup_table.v"
		`include "../../../internal/cache/lib/lease_probability_controller.v"
		`include "../../../internal/cache/fully_associative/lease_scope/lease_dynamic_cache_fa_controller_tracker.v"
	`endif
	`include "../../../internal/cache/lib/plru_line_controller.v"
	`include "../../../internal/cache/fully_associative/src/cache_fa_controller.v"
	`include "../../../internal/cache/fully_associative/src/cache_fa.v"
	`include "../../../internal/system_controller/src/txrx_buffer.v"
	`include "../../../peripheral/src/peripheral_system_3.v"
	`include "../../../internal/system/internal_system_2.v"
	`include "../../../internal/cache/fully_associative/src/cache_fa_all.v"
	`include "../../../internal/cache/lib/cache_performance_controller_all.v"
	`include "../../../internal/cache/fully_associative/src/tag_memory_fa.v"
	`include "../../../internal/system_controller/src/memory_controller_internal.v"
`endif

//comms stuff
`include "../../../include/comms.h"








`endif // _TOP_H_
