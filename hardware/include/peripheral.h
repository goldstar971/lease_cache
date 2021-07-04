`ifndef _PERIPHERAL_H_
`define _PERIPHERAL_H_

// peripheral mapping
// ----------------------------------------------------


`define COMM_CACHE0 			27'h4000080 		// read cache0 comm stuff here
`define COMM_CACHE1 			27'h4000084 		// read cache1 comm stuff here
`define COMM_CACHE2             27'h4000092        // read cache L2 comm stuff here
`define CPC_METRIC_SWITCH  32'h04000088      //switch between tracker, sampler, and L1 cache statistics

// read and write
`define TIMER_CONTROL 			27'h4000100
`define COMM_REGISTER0 			27'h4000104
`define COMM_REGISTER1 			27'h4000108
`define COMM_REGISTER2 			27'h400010C

`define COMM_CONTROL			27'h4000110 		// processor controls upper 2B, user lower 2B

`define PHASE_REG 	 			27'h4000150

`endif // _PERIPHERAL_H_