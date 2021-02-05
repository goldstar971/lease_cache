`ifndef _MEMORY_H_
`define _MEMORY_H_

// memory partitioning
// -------------------------------------------------
`define 	OUTPUT_PERIPHERAL_BASE	32'h04000000	// byte addressible - read only
`define 	INPUT_PERIPHERAL_BASE 	32'h04000100 	// byte addressible - read and write
`define 	RAS_BASE 				5'b11111 		// top of return-address-stack (hardware implemented stack)
`define 	SP_BASE 				26'h3FFFFFC		// top of stack (memory implemented) 

`endif // _MEMORY_H_