`include "riscv.h"

module riscv_32M_alu(

	input 		[31:0]	in0_i, 		// Tsrc1
	input 		[31:0]	in1_i, 		// Tsrc2
	input 		[2:0]	func3_i, 	// operation switch
	output 		[31:0] 	result_o 	// modulated output (2's Comp if necessary)

);

// unsigned - unsigned multiplier hardware
wire [31:0]	umult_inA, umult_inB; 	// inA is Tsrc1, inB is Tsrc2
wire [63:0] umult_result;

umultiplier32b umult_inst(
	.dataa 			(umult_inA 		), 
	.datab 			(umult_inB 		), 
	.result 		(umult_result 	)
);

// unsigned - unsignend divider hardware
wire [31:0] udiv_result, udiv_remain;
//assign udiv_result = 'b0;
//assign udiv_remain = 'b0;

udivider32b udiv_inst( 		
	.denom 			(umult_inB 		), 	// denom is src2 => inB
	.numer 			(umult_inA 		), 
	.quotient 		(udiv_result 	), 
	.remain 		(udiv_remain 	)
);

// operand converter (signed to unsigned forms)
riscv_alu_32M_converter alu_32M_converter_inst(

	// first stage ports (pre mult/div)
	.func3_i 		(func3_i 		),
	.Tsrc1_i 		(in0_i 			),
	.Tsrc2_i 		(in1_i 			),	
	.umult_op1_o 	(umult_inA		), 	// Tsrc1 -> op1
	.umult_op2_o 	(umult_inB 		), 	// Tsrc2 -> op2

	// second stage ports (post mult/div)
	.mult_product_i	(umult_result 	),
	.div_quotient_i (udiv_result 	),
	.div_remain_i 	(udiv_remain 	),
	.alu_result_o	(result_o 		)
);

endmodule