`ifndef _CACHE_COMPONENTS_H_
`define _CACHE_COMPONENTS_H_

//cache compoments

`include "../../../internal/cache/lib/cache_performance_controller.v"
`include "../../../internal/cache/lib/cache_performance_controller_all.v"
`include "../../../internal/cache/lib/mru_line_controller.v"
`include "../../../internal/cache/lib/lru_line_controller.v"
`include "../../../internal/cache/lib/srrip_line_controller.v"
`include "../../../internal/cache/lib/plru_line_controller.v"
`include "../../../internal/cache/lib/n_set_cache_mru_policy_controller.v"
`include "../../../internal/cache/lib/n_set_cache_lru_policy_controller.v"
`include "../../../internal/cache/lib/n_set_cache_srrip_policy_controller.v"
`include "../../../internal/cache/lib/n_set_cache_plru_policy_controller.v"
`include "../../../internal/cache/lib/n_set_cache_fifo_policy_controller.v"
`include "../../../internal/cache/lib/n_set_cache_random_policy_controller.v"
`include "../../../internal/cache/lib/n_set_cache_controller.v"
`include "../../../internal/cache/lib/n_set_dynamic_controller_tracker.v"
`include "../../../internal/cache/lib/tag_memory_n_set.v"
`include "../../../internal/cache/lib/cache_n_set_all.v"

//multilevel cache stuff
`ifdef MULTI_LEVEL_CACHE
`include "../../../internal/cache_2level/n_set_lease_dynamic_cache_controller_tracker_L2.v"
`include "../../../internal/cache_2level/tag_memory_n_set_L2.v"
`include "../../../internal/cache_2level/n_set_cache_controller_L2.v"
`include "../../../internal/cache_2level/L1_n_set_cache_controller_multi_level.v"
`include "../../../internal/cache_2level/cache_performance_controller_all_L2.v"
`include "../../../internal/cache_2level/cache_n_set_L2_all.v"
`include "../../../internal/cache_2level/n_set_cache_multi_level.v"
`endif




`endif //_CACHE_COMPONENTS_H_