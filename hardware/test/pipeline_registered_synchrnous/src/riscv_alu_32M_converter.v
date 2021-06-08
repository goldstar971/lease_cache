//`include "riscv.h"

module riscv_alu_32M_converter(

	// first stage ports (pre mult/div)
	input 	[2:0] 	func3_i,
	input 	[31:0]	Tsrc1_i,
	input 	[31:0]	Tsrc2_i,
	output 	[31:0]	umult_op1_o,
	output	[31:0]	umult_op2_o,

	// second stage ports (post mult/div)
	input 	[63:0]	mult_product_i,
	input 	[31:0]	div_quotient_i,
	input 	[31:0]	div_remain_i,
	output 	[31:0] 	alu_result_o
);

// port mapping
reg 	[31:0] 	umult_op1_reg;
reg 	[31:0]	umult_op2_reg;
reg 	[31:0]	alu_result_reg;

assign umult_op1_o = umult_op1_reg;
assign umult_op2_o = umult_op2_reg;
assign alu_result_o = alu_result_reg;

// second stage conversion logic
// -----------------------------------------------------------------------------------
reg 		flag_invert;
wire [63:0]	mult_product_inverted;
wire [31:0]	div_quotient_inverted;
wire [31:0]	div_remain_inverted;

assign mult_product_inverted = ~mult_product_i + 1'b1;
assign div_quotient_inverted = ~div_quotient_i + 1'b1;
assign div_remain_inverted = ~div_remain_i + 1'b1;

always @(*) begin
	case(func3_i)
		
		`RV32M_FUNC3_MUL: begin
			if (!flag_invert) 	alu_result_reg = mult_product_i[31:0];
			else 	 			alu_result_reg = mult_product_inverted[31:0];
		end
		`RV32M_FUNC3_MULH, `RV32M_FUNC3_MULHSU, `RV32M_FUNC3_MULHU: begin
			if (!flag_invert) 	alu_result_reg = mult_product_i[63:32];
			else 	 			alu_result_reg = mult_product_inverted[63:32];
		end

		`RV32M_FUNC3_DIV, `RV32M_FUNC3_DIVU: begin
			if (!flag_invert)	alu_result_reg = div_quotient_i;
			else 				alu_result_reg = div_quotient_inverted;
		end

		`RV32M_FUNC3_REM, `RV32M_FUNC3_REMU: begin
			if (!flag_invert)	alu_result_reg = div_remain_i;
			else 				alu_result_reg = div_remain_inverted;
		end

	endcase
end

// first stage conversion logic
// -----------------------------------------------------------------------------------
always @(*) begin
	case(func3_i)

		// signed - signed operations
		`RV32M_FUNC3_MUL, `RV32M_FUNC3_MULH, `RV32M_FUNC3_DIV, `RV32M_FUNC3_REM: begin
			// both unsigned do nothing
			if (!Tsrc1_i[31] & !Tsrc2_i[31]) begin
				flag_invert = 1'b0;
				umult_op1_reg = Tsrc1_i;
				umult_op2_reg = Tsrc2_i;
			end
			// operand 1 is signed so invert
			else if (Tsrc1_i[31] & !Tsrc2_i[31]) begin
				flag_invert = 1'b1;
				umult_op1_reg = ~Tsrc1_i + 1'b1;
				umult_op2_reg = Tsrc2_i;
			end
			// operand 2 is signed so invert
			else if (!Tsrc1_i[31] & Tsrc2_i[31]) begin
				flag_invert = 1'b1;
				umult_op1_reg = Tsrc1_i;
				umult_op2_reg = ~Tsrc2_i + 1'b1;
			end
			// both signed so invert both, invert cancel out
			else begin
				flag_invert = 1'b0;
				umult_op1_reg = Tsrc1_i;
				umult_op2_reg = Tsrc2_i;
			end
		end

		// signed - unsigned mult.
		`RV32M_FUNC3_MULHSU: begin
			// operand 1 - signed, invert if necessary
			if (Tsrc1_i[31]) begin
				umult_op1_reg = ~Tsrc1_i + 1'b1;
				flag_invert = 1'b1;
			end
			else begin
				umult_op1_reg = Tsrc1_i;
				flag_invert = 1'b0;
			end

			// operand 2 - unsigned, do nothing
			umult_op2_reg = Tsrc2_i;
		end

		// unsigned - unsigned operations
		`RV32M_FUNC3_MULHU, `RV32M_FUNC3_DIVU, `RV32M_FUNC3_REMU: begin
			// both operands unsigned, do nothing
			flag_invert = 1'b0;
			umult_op1_reg = Tsrc1_i;
			umult_op2_reg = Tsrc2_i;
		end

	endcase
end

endmodule