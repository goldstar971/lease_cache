`ifndef _PERIPHERAL_H_
`define _PERIPHERAL_H_

// peripheral mapping
// ----------------------------------------------------
`ifndef BW_BYTE_ADDR
	`define BW_BYTE_ADDR 						29 					// 512MB
`endif

`define COMM_CACHE0 			30'h20000080 		// read cache0 comm stuff here
`define COMM_CACHE1 			30'h20000084 		// read cache1 comm stuff here
`define COMM_CACHE2             30'h20000092        // read cache L2 comm stuff here
`define CPC_METRIC_SWITCH  		30'h20000088      //switch between tracker, sampler, and L1 cache statistics

// read and write
`define TIMER_CONTROL 			30'h20000100
`define COMM_REGISTER0 			30'h20000104
`define COMM_REGISTER1 			30'h20000108
`define COMM_REGISTER2 			30'h2000010C
`define STATS_BASE              30'h20000120

`define COMM_CONTROL			30'h20000110 		// processor controls upper 2B, user lower 2B

`define PHASE_REG 	 			30'h20000150

`endif // _PERIPHERAL_H_