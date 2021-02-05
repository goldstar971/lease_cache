//`include "riscv.h"

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

// create a bus that determines if the fedback signal is routable
// i.e. has a destination register
// easier to specify what doesn't have a destination
wire stage3_fdest_valid_bus;
wire stage4_fdest_valid_bus;

assign stage3_fdest_valid_bus = (encoding_stage3_i == `ENCODING_NONE	) ? 1'b0 : 
								(encoding_stage3_i == `ENCODING_BRANCH	) ? 1'b0 : 
								(encoding_stage3_i == `ENCODING_STORE	) ? 1'b0 : 
								1'b1;
assign stage4_fdest_valid_bus = (encoding_stage4_i == `ENCODING_NONE	) ? 1'b0 : 
								(encoding_stage4_i == `ENCODING_BRANCH	) ? 1'b0 : 
								(encoding_stage4_i == `ENCODING_STORE	) ? 1'b0 : 
								1'b1;

always @(*) begin

	// default outputs
	// --------------------------------------------------------------------------------------------------------------
	flag_dependency_reg 	= 1'b0;
	src_operand_reg 		= RF[fsrc_i];


	// universal no dependency conditions - for both src1 and src2 operands
	// ------------------------------------------------------------------------------------------------------------------

	// source register conditions
	if (fsrc_i == 'b0) 																flag_dependency_reg 	= 1'b0;

	// source encoding conditions (no source register/s)
	else if (encoding_i == `ENCODING_NONE) 											flag_dependency_reg 	= 1'b0;
	else if (encoding_i == `ENCODING_LUI) 											flag_dependency_reg 	= 1'b0;
	else if (encoding_i == `ENCODING_AUIPC)											flag_dependency_reg 	= 1'b0;
	else if ((encoding_i == `ENCODING_LOAD) 		& (SRC == 2)) 					flag_dependency_reg 	= 1'b0;
	else if ((encoding_i == `ENCODING_ARITH_IMM) 	& (SRC == 2)) 					flag_dependency_reg 	= 1'b0;
	else if ((encoding_i == `ENCODING_JALR) 		& (SRC == 2)) 					flag_dependency_reg 	= 1'b0;
	else if ((encoding_i == `ENCODING_JAL) 			& (SRC == 2)) 					flag_dependency_reg 	= 1'b0;


	// dependency/hazard logic - only route if the operation has a destination register specified
	// ------------------------------------------------------------------------------------------------------------------
	else begin

		// stage 4 dependency - must check here first? - need to check this (store issue)
		// has to be operations only with a destination
		// -------------------------------------------------------------------
		if ((fsrc_i == fdest_stage4_i) & stage4_fdest_valid_bus) begin
			src_operand_reg 		= data_stage4_i;
		end

		// possible that a more recent operation resulted in a hazard (consequ. same destinations)
		if ((fsrc_i == fdest_stage3_i) & stage3_fdest_valid_bus) begin

			// determine if a stall is necessary based on operation occuring in stage 3
			case(encoding_stage3_i)

				// only time a stall is necessary is if operation is a load
				// the controller will let the operation propagate and insert an ENCODING_NONE to prevent
				// returning to this point (dependency will be caught in preceeding conditional)
				`ENCODING_LOAD: flag_dependency_reg = 1'b1;

				// all other operations are valid to be fedback
				default: begin
					flag_dependency_reg = 1'b0;
					src_operand_reg = data_stage3_i;
				end
			endcase
		end
	end
end


endmodule