`ifndef _PERIPHERAL_H_
`define _PERIPHERAL_H_

// peripheral mapping
// ----------------------------------------------------

// read only
`define TIMER0 					32'h04000000
`define TIMER1 					32'h04000004
`define EXCEPTION_REGISTER 		32'h04000010
`define PC0				 		32'h04000020
`define PC1				 		32'h04000024
`define PC2				 		32'h04000028
`define PC3				 		32'h0400002C
`define PC4				 		32'h04000030
`define PC5				 		32'h04000034
`define PC6				 		32'h04000038
`define PC7				 		32'h0400003C
`define IR0 					32'h04000040 
`define IR1 					32'h04000044
`define IR2 					32'h04000048
`define IR3 					32'h0400004C
`define IR4 					32'h04000050
`define IR5 					32'h04000054
`define IR6 					32'h04000058
`define IR7 					32'h0400005C

`define CACHE0_HIT 				32'h04000060
`define CACHE0_MISS 			32'h04000064
`define CACHE0_WB 				32'h04000068
`define CACHE0_DEBUG0 			32'h0400006C
`define CACHE0_DEBUG1 			32'h04000070
`define CACHE0_DEBUG2 			32'h04000074

`define COMM_CACHE0 			32'h04000080 		// read cache0 comm stuff here
`define COMM_CACHE1 			32'h04000084 		// read cache1 comm stuff here

// read and write
`define TIMER_CONTROL 			32'h04000100
`define COMM_REGISTER0 			32'h04000104
`define COMM_REGISTER1 			32'h04000108
`define COMM_REGISTER2 			32'h0400010C

`define COMM_CONTROL			32'h04000110 		// processor controls upper 2B, user lower 2B

`define PHASE_REG 	 			32'h04000150

`endif // _PERIPHERAL_H_