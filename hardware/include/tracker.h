`ifndef _TRACKER_H_
`define _TRACKER_H_

`ifdef MULTI_LEVEL_CACHE
`define TRACKER_BUFFER_LIMIT 11'h4Cf
`define TRACKER_OUT_SEL_WIDTH 6
`else
`define TRACKER_BUFFER_LIMIT 2**12
`define TRACKER_OUT_SEL_WIDTH 5
`endif
`include "../../../internal/sampler/cache_line_tracker_4.v"
`include "../../../internal/cache/lib/fa_cache_lease_policy_controller_tracker_2.v"


`endif