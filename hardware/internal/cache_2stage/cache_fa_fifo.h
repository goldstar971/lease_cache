`ifndef _CACHE_FA_FIFO_H_
`define _CACHE_FA_FIFO_H_

// top level hierarchy
`include "./src/cache_level_1.v" 			


// cache top level architecture components
`include "./src/cache_request_buffer.v"
`include "./src/tag_lookup_table_fa.v"
`include "./src/cache_memory.v"
`include "./src/cache_performance_monitor.v"


// cache controller components
`include "./src/cache_fa_controller.v"
`include "./src/hart_request_buffer.v"


// cache replacement policy components
`include "./src/fa_cache_fifo_policy_controller.v"


`endif