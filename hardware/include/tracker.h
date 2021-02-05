`ifndef _TRACKER_H_
`define _TRACKER_H_

`include "../../../internal/sampler/cache_line_tracker_2.v"
`include "../../../internal/cache/lib/fa_cache_lease_policy_controller_tracker_2.v"
`include "../../../internal/cache/lib/cache_performance_controller_tracker_2.v"
`ifdef DATA_POLICY_DLEASE
	`include "../../../internal/cache/fully_associative/lease_scope/lease_dynamic_cache_fa_tracker.v"
	`include "../../../internal/cache/fully_associative/lease_scope/lease_dynamic_cache_fa_controller_tracker.v"
`else 
	`include "../../../internal/cache/fully_associative/src/lease_cache_fa_tracker_2.v"
	`include "../../../internal/cache/fully_associative/src/lease_cache_fa_controller_tracker_2.v"
`endif





`endif