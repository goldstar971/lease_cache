`ifndef _PROCESSOR_H_
`define _PROCESSOR_H_

// machine cycle states
// ----------------------------------------------
`define		MC0 	5'b00000

`define	 	MC1_R 	5'b00001
`define	 	MC1_I 	5'b00010
`define	 	MC1_SB 	5'b00011
`define	 	MC1_S 	5'b00100
`define	 	MC1_U 	5'b00101
`define	 	MC1_J 	5'b00110

`define	 	MC2_R 	5'b00111
`define	 	MC2_I 	5'b01000
`define	 	MC2_SB 	5'b01001
`define	 	MC2_S 	5'b01010
`define	 	MC2_U 	5'b01011
`define	 	MC2_J 	5'b01100

`define		MC3_R 	5'b01101
`define 	MC3_I 	5'b01110
`define 	MC3_SB 	5'b01111
`define 	MC3_S 	5'b10000
`define 	MC3_U 	5'b10001
`define 	MC3_J 	5'b10010

`define 	MC_EXCEPTION	5'b11111


`endif // _PROCESSOR_H_