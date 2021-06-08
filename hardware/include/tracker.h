`ifndef _TRACKER_H_
`define _TRACKER_H_

`include "../../../internal/cache/lib/fa_cache_lease_policy_controller_tracker_2.v"
`ifdef DATA_POLICY_DLEASE
	`include "../../../internal/cache/fully_associative/lease_scope/lease_dynamic_cache_fa_controller_tracker.v"
`else 

	`include "../../../internal/cache/fully_associative/src/lease_cache_fa_controller_tracker_2.v"
`endif





`endif