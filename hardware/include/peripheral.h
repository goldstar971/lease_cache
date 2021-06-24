`ifndef _PERIPHERAL_H_
`define _PERIPHERAL_H_

// peripheral mapping
// ----------------------------------------------------


`define COMM_CACHE0 			32'h04000080 		// read cache0 comm stuff here
`define COMM_CACHE1 			32'h04000084 		// read cache1 comm stuff here
`define COMM_CACHE2             32'h04000092        // read cache L2 comm stuff here
`define CPC_METRIC_SWITCH  32'h04000088      //switch between tracker, sampler, and L1 cache statistics

// read and write
`define TIMER_CONTROL 			32'h04000100
`define COMM_REGISTER0 			32'h04000104
`define COMM_REGISTER1 			32'h04000108
`define COMM_REGISTER2 			32'h0400010C

`define COMM_CONTROL			32'h04000110 		// processor controls upper 2B, user lower 2B

`define PHASE_REG 	 			32'h04000150

`endif // _PERIPHERAL_H_