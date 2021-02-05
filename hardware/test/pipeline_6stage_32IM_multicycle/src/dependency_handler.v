`include "riscv.h"

module dependency_handler(

	input 	[8:0]	encoding_i, 			// encoded operation of this stage
	input 	[8:0] 	encoding_stage3_i,
	input 	[8:0] 	encoding_stage4_i,
	input 	[1023:0]register_file_vec_i, 	// register file regs vec'd to port
	input 	[4:0]	fsrc1_i,
	input 	[4:0]	fsrc2_i,
	input 	[4:0]	fdest_stage3_i, 		// destination register of stage 3
	input 	[4:0]	fdest_stage4_i, 		// destination register of stage 4
	input 	[31:0]	data_stage3_i, 			// data bus from stage 3 output
	input 	[31:0]	data_stage4_i, 			// data bus from stage 4 output
	output 			flag_dependency_o, 		// 1: unresolved dependency that requires a pipeline stall
	output 	[31:0]	src1_operand_o,
	output 	[31:0]	src2_operand_o
);

// port mappings
// ------------------------------------------------------------------------------------------------------------------
wire 	src1_dependency_bus, src2_dependency_bus;
assign flag_dependency_o = src1_dependency_bus | src2_dependency_bus;


// dependency logic
// ------------------------------------------------------------------------------------------------------------------
src_dependency_handler #( 
	.SRC 	 				(1 					 	) 
) src1_dependency_handler (
	.encoding_i 			(encoding_i 			),
	.encoding_stage3_i 		(encoding_stage3_i 		),
	.encoding_stage4_i 		(encoding_stage4_i 		),
	.register_file_flag_i	(register_file_vec_i 	),
	.fsrc_i 				(fsrc1_i 				),
	.fdest_stage3_i 		(fdest_stage3_i 		),
	.fdest_stage4_i 		(fdest_stage4_i 		),
	.data_stage3_i 			(data_stage3_i 			),
	.data_stage4_i 			(data_stage4_i 			),
	.flag_dependency_o 		(src1_dependency_bus 	),
	.src_operand_o 			(src1_operand_o 		)
);

src_dependency_handler #( 
	.SRC 	 				(2 					 	) 
) src2_dependency_handler (
	.encoding_i 			(encoding_i 			),
	.encoding_stage3_i 		(encoding_stage3_i 		),
	.encoding_stage4_i 		(encoding_stage4_i 		),
	.register_file_flag_i	(register_file_vec_i 	),
	.fsrc_i 				(fsrc2_i 				),
	.fdest_stage3_i 		(fdest_stage3_i 		),
	.fdest_stage4_i 		(fdest_stage4_i 		),
	.data_stage3_i 			(data_stage3_i 			),
	.data_stage4_i 			(data_stage4_i 			),
	.flag_dependency_o 		(src2_dependency_bus 	),
	.src_operand_o 			(src2_operand_o 		)
);

endmodule






// parameterized source register dependency checker
// ------------------------------------------------------------------------------------------------------------------

module src_dependency_handler #(
	parameter SRC = 1 						// 1 = src1, 2 = src2 - MUST BE CAREFUL OF SETTING THIS CAN ONLY BE "1" OR "2"
)(
	input 	[8:0]	encoding_i, 			// encoded operation of this stage
	input 	[8:0] 	encoding_stage3_i,
	input 	[8:0] 	encoding_stage4_i,
	input 	[1023:0]register_file_flag_i, 	// register file regs vec'd to port
	input 	[4:0]	fsrc_i,
	input 	[4:0]	fdest_stage3_i, 		// destination register of stage 3
	input 	[4:0]	fdest_stage4_i, 		// destination register of stage 4
	input 	[31:0]	data_stage3_i, 			// data bus from stage 3 output
	input 	[31:0]	data_stage4_i, 			// data bus from stage 4 output
	output 			flag_dependency_o, 		// 1: unresolved dependency that requires a pipeline stall
	output 	[31:0]	src_operand_o
);

// un-vec register file for import
wire 	[31:0]	RF 	[0:31];
genvar k;
generate 
	for (k = 0; k < 32; k = k + 1) begin: rf_unpack
		assign RF[k] = register_file_flag_i[32*k+31:32*k];
	end
endgenerate


// port mappings
// ------------------------------------------------------------------------------------------------------------------
reg 			flag_dependency_reg;
reg 	[31:0]	src_operand_reg;

assign flag_dependency_o 	= flag_dependency_reg;
assign src_operand_o 		= src_operand_reg;


// dependency forwarding logic
// ------------------------------------------------------------------------------------------------------------------
always @(*) begin

	// default outputs
	// --------------------------------------------------------------------------------------------------------------
	flag_dependency_reg 	= 1'b0;
	src_operand_reg 		= RF[fsrc_i];


	// universal no dependency conditions - for both src1 and src2 operands
	// ------------------------------------------------------------------------------------------------------------------

	// source register conditions
	if (fsrc_i == 'b0) 																flag_dependency_reg 	= 1'b0;
	else if ((fsrc_i == fdest_stage3_i) & (encoding_stage3_i == `ENCODING_NONE)) 	flag_dependency_reg 	= 1'b0;
	else if ((fsrc_i == fdest_stage4_i) & (encoding_stage4_i == `ENCODING_NONE)) 	flag_dependency_reg 	= 1'b0;

	// source encoding conditions
	else if (encoding_i == `ENCODING_NONE) 											flag_dependency_reg 	= 1'b0;
	else if (encoding_i == `ENCODING_LUI) 											flag_dependency_reg 	= 1'b0;
	else if (encoding_i == `ENCODING_AUIPC)											flag_dependency_reg 	= 1'b0;
	else if ((encoding_i == `ENCODING_LOAD) 		& (SRC == 2)) 					flag_dependency_reg 	= 1'b0;
	else if ((encoding_i == `ENCODING_ARITH_IMM) 	& (SRC == 2)) 					flag_dependency_reg 	= 1'b0;
	else if ((encoding_i == `ENCODING_JALR) 		& (SRC == 2)) 					flag_dependency_reg 	= 1'b0;
	else if ((encoding_i == `ENCODING_JAL) 			& (SRC == 2)) 					flag_dependency_reg 	= 1'b0;

	// dependency/hazard logic
	// ------------------------------------------------------------------------------------------------------------------
	else begin

		// stage 3 dependency - do not forward from loads, stores,  
		// ----------------------------------------------------------
		if (fsrc_i == fdest_stage3_i) begin

			// determine if a stall is necessary based on operation occuring in stage 3
			case(encoding_stage3_i)

				// dependencies are met if alu stage operation is jump, arith_imm, arith_reg
				`ENCODING_JAL, `ENCODING_JALR, `ENCODING_ARITH_IMM, `ENCODING_ARITH_REG, `ENCODING_LUI, `ENCODING_AUIPC: begin
					src_operand_reg = data_stage3_i;
				end

				// dependencies are not met if alu stage operation is load/store
				`ENCODING_LOAD: flag_dependency_reg = 1'b1;

				// branch and store instructions do not have a destination so no dependency
				default: flag_dependency_reg = 1'b0;
			endcase
		end

		// stage 4 dependency - only dependency to resolve here is load
		// ----------------------------------------------------------
		else if (fsrc_i == fdest_stage4_i) begin
			src_operand_reg 		= data_stage4_i;
			//if (encoding_stage4_i == `ENCODING_LOAD)	src_operand_reg 		= data_stage4_i;
		end
	end
end


endmodule