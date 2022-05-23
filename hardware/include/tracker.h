`ifndef _TRACKER_H_
`define _TRACKER_H_

`ifdef MULTI_LEVEL_CACHE
`define TRACKER_BUFFER_LIMIT 11'h52C
`define TRACKER_OUT_SEL_WIDTH 6
`else
`define TRACKER_BUFFER_LIMIT 12'h1249
`define TRACKER_OUT_SEL_WIDTH 5
`endif

`define EVICTION_TRACKER_BUFFER_LIMIT 16'hA3D7
`include "../../../internal/sampler_tracker/cache_line_tracker_4.v"
`include "../../../internal/sampler_tracker/eviction_status_tracker.v"
`endif