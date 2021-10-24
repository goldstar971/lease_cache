`ifndef _TRACKER_H_
`define _TRACKER_H_
`include "../../../internal/sampler/cache_line_tracker_4.v"

`ifdef MULTI_LEVEL_CACHE
`define TRACKER_BUFFER_LIMIT 11'h4Cf
`define TRACKER_OUT_SEL_WIDTH 6
`else
`define TRACKER_BUFFER_LIMIT 2**12
`define TRACKER_OUT_SEL_WIDTH 5
`endif


`endif