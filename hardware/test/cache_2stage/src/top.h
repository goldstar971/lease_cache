`ifndef _TOP_H_
`define _TOP_H_

// simulation/emulation control
`define SIMULATION_SYNTHESIS


// macro/function libraries
`include "../../../include/utilities.h"


// universal hardware libraries
`include "../../../include/logic_components.h"
`include "../../../utilities/embedded_memory/memory_embedded.v"
 

// top level libraries and source
`include "../../../internal/cache_2stage/cache.h"
`include "../../../internal/cache_2stage/cache_fa_fifo.h"


// testbench specific libraries
`include "test_memory_controller.v"
`include "../../../internal/cache_2stage/src/cache_request_buffer.v"



`endif