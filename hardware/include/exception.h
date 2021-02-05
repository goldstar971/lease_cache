`ifndef _EXCEPTION_H_
`define _EXCEPTION_H_

// core exceptions
// ----------------------------------------------------------
`define CORE_UNKNOWN_OPCODE 			4'b0001
`define CORE_UNKNOWN_FUNC3 				4'b0010


// internal memory controller exceptions
// ----------------------------------------------------------
`define MEM_INT_WALIGN 					4'b0001
`define MEM_INT_HALIGN 					4'b0010

`define MEM_INT_BUFFER_TX_OVERFLOW 		4'b0001
`define MEM_INT_BUFFER_TX_UNDERFLOW 	4'b0010
`define MEM_INT_BUFFER_RX_OVERFLOW 		4'b0100
`define MEM_INT_BUFFER_RX_UNDERFLOW 	4'b1000


// external memory controller exceptions
// ----------------------------------------------------------



`endif // _EXCEPTION_H_