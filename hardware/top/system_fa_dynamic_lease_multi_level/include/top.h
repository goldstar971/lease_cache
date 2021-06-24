`ifndef _TOP_H_
`define _TOP_H_


// general directories
// -------------------------------------------------------------------------------------------------
`include "../../../include/cache.h"
`include "../../../include/utilities.h"
`include "../../../include/logic_components.h"
`include "../../../utilities/embedded_memory/memory_embedded.v"





// core
// ----------------------------------------------------
`define RISCV_PIPELINE


// cache 
// ----------------------------------------------------

//`define INST_CACHE_FA
`define INST_CACHE_2WAY
//`define INST_CACHE_4WAY
//`define INST_CACHE_8WAY
//`define INST_POLICY_RANDOM
//`define INST_POLICY_FIFO
//`define INST_POLICY_LRU
`define INST_POLICY_PLRU
//`define INST_POLICY_SRRIP


`define DATA_CACHE_2WAY
//`define DATA_CACHE_4WAY
//`define DATA_CACHE_8WAY
//`define DATA_POLICY_RANDOM
//`define DATA_POLICY_FIFO
//`define DATA_POLICY_LRU
`define DATA_POLICY_PLRU
//`define DATA_POLICY_SRRIP
//define DATA_POLICY_DLEASE
//`define DATA_POLICY_LEASE

`define MULT_LEVEL_CACHE

`ifdef MULT_LEVEL_CACHE
	`define L2_CACHE_INST_FA
	`define L2_CACHE_STRUCTURE  `ID_CACHE_FULLY_ASSOCIATIVE
	//`define L2_CACHE_POLICY_PLRU
	`define L2_CACHE_POLICY_DLEASE
	`define COMM_CONTROLLER comm_controller_v3
`else 
	`define COMM_CONTROLLER comm_controller_v2
`endif



//`define LEASE_PRIORITY 							// gives eviction priority to defaulted leases

`define INST_CACHE_BLOCK_CAPACITY 		128
`define DATA_CACHE_BLOCK_CAPACITY 		128
`define L2_CACHE_BLOCK_CAPACITY         512

`define FLOAT_INSTRUCTIONS 


// derived configurations (no touchy)
// -------------------------------------------------------------------------------------------------


`ifdef L2_CACHE_POLICY_DLEASE
	`define L2_CACHE_POLICY  `ID_CACHE_DLEASE
	`define LEASE_POLICY_CONTROLLER_INST 	fa_cache_lease_policy_controller_tracker_2
	`define L2_CACHE_INST                    L2_cache_fa_all
	`define L2_CACHE_CONTROLLER            lease_dynamic_cache_fa_controller_tracker_L2
	`define L2_CACHE_INIT 1'b0
`else
	`define L2_CACHE_POLICY  `ID_CACHE_PLRU
	`define LEASE_POLICY_CONTROLLER_INST 	fa_cache_lease_policy_controller_tracker_2
	`define L2_CACHE_INST                   L2_cache_fa_all
	`define L2_CACHE_CONTROLLER             cache_fa_controller_L2
	`define L2_CACHE_INIT 1'b1
`endif

// core 
// ----------------------------------------------------


`ifdef RISCV_PIPELINE
	`define RISCV_HART_INST riscv_hart_top 			// module name
	`include "../../../include/riscv_v2_2.h" 			// path to module dependencies
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










`ifdef DATA_CACHE_FA
	`define DATA_CACHE_STRUCTURE 		`ID_CACHE_FULLY_ASSOCIATIVE

	// check lease cache
	`ifdef 	DATA_POLICY_LEASE
		`define DATA_CACHE_INST 				cache_fa_all
		`define LEASE_POLICY_CONTROLLER_INST 	fa_cache_lease_policy_controller_tracker_2
		`define DATA_CACHE_CONTROLLER           lease_cache_fa_controller_tracker_2
	`elsif 	DATA_POLICY_DLEASE
		`define DATA_CACHE_INST 				cache_fa_all
		`define LEASE_POLICY_CONTROLLER_INST 	fa_cache_lease_policy_controller_tracker_2
		`define DATA_CACHE_CONTROLLER           lease_dynamic_cache_fa_controller_tracker
	`else 
		`define DATA_CACHE_CONTROLLER           cache_fa_controller
		`define DATA_CACHE_INST 				cache_fa_all
		`define LEASE_POLICY_CONTROLLER_INST 	fa_cache_policy_controller
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



	
	`include "../../../include/sampler.h"
	`include "../../../include/tracker.h"
	


`ifdef MULT_LEVEL_CACHE
	`include "../../../internal/system/internal_system_2_multi_level.v"
	`include "../../../internal/system_controller/src/memory_controller_internal_2level.v"
	`include "../../../internal/cache_2level/L2_cache_fa_all.v"
	`include "../../../internal/cache_2level/cache_line_tracker_4.v"
	`include "../../../internal/cache_2level/cache_performance_controller_all.v"
	`ifdef L2_CACHE_POLICY_DLEASE
		`include "../../../internal/cache_2level/lease_dynamic_cache_fa_controller_tracker_L2.v"
	`else 
		`include "../../../internal/cache_2level/cache_fa_controller_L2.v"
	`endif
	`include "../../../internal/cache_2level/cache_2way_controller_multi_level.v"
	`include "../../../internal/cache_2level/cache_2way.v"
	`include "../../../internal/sampler/lease_sampler_all.v"
	`include "../../../utilities/linear_feedback_shift_register/linear_shift_register_12b.v"
	`include "../../../peripheral/src/peripheral_system_3.v"
	`include "../../../external/jtag_uart/src/comm_controller_v3.v"
	`include "../../../internal/cache_2level/tag_memory_fa.v"
	`include "../../../internal/system_controller/src/txrx_buffer_L2_L1.v"
	`include "../../../internal/cache/two_way_set_associative/src/tag_memory_2way.v"
	`include "../../../internal/sampler/tag_match_encoder_9b.v"
	`include "../../../internal/cache/lib/set_cache_plru_policy_controller.v"
	`include "../../../internal/cache/lib/plru_line_controller.v"
`else 
	`include "../../../utilities/linear_feedback_shift_register/linear_shift_register_12b.v"
	`include "../../../peripheral/src/peripheral_system_2.v"
	`include "../../../internal/system/internal_system_2.v"
	`include "../../../internal/cache/fully_associative/src/cache_fa_all.v"
	`include "../../../include/cpc_all.h"
	`include "../../../external/jtag_uart/src/comm_controller_v2.v"
	`include "../../../internal/cache/fully_associative/src/tag_memory_fa.v"
	`include "../../../internal/system_controller/src/memory_controller_internal.v"
`endif








`endif // _TOP_H_
