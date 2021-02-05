//`include "riscv.h"

module riscv_32I_alu(
	input 		[31:0]	in0_i,
	input 		[31:0]	in1_i,
	input 		[31:0]	imm0_i,
	input 		[31:0]	addr_i,
	input 		[8:0]	encoding_i,
	input 		[2:0]	func3_i,
	input		[6:0]	func7_i,
	output	reg [31:0]	out_o
);

always @(*) begin

	// defaults
	out_o = 'b0;

	// 32I instruction set
	case(encoding_i)

		`ENCODING_LUI: 					out_o = imm0_i;
		`ENCODING_AUIPC:				out_o = imm0_i + addr_i;

		`ENCODING_ARITH_IMM: begin
			case(func3_i)
				`RV32I_FUNC3_ARITH_ADDI: 							out_o = in0_i + imm0_i;
				`RV32I_FUNC3_ARITH_SLTI: begin
					if ($signed(in0_i) < $signed(in1_i)) 			out_o = 32'h00000001;
					else 											out_o = 32'h00000000;
				end
				`RV32I_FUNC3_ARITH_SLTIU: begin
					if ($unsigned(in0_i) < $unsigned(in1_i)) 		out_o = 32'h00000001;
					else 											out_o = 32'h00000000;
				end	


				`RV32I_FUNC3_ARITH_XORI:							out_o = in0_i ^ imm0_i;
				`RV32I_FUNC3_ARITH_ORI:								out_o = in0_i | imm0_i;
				`RV32I_FUNC3_ARITH_ANDI:							out_o = in0_i & imm0_i;
				`RV32I_FUNC3_ARITH_SLLI:							out_o = in0_i << imm0_i[4:0];


				`RV32I_FUNC3_ARITH_SRLI, `RV32I_FUNC3_ARITH_SRAI: begin
					if (func7_i[5] == 1'b0)							out_o = in0_i >> imm0_i[4:0]; 	// SRLI
					else 											out_o = in0_i >>> imm0_i[4:0]; 	// SRAI
				end		
			endcase
		end

		`ENCODING_ARITH_REG: begin
			// need to check for mult/div first
			case(func3_i)
				`RV32I_FUNC3_ARITH_ADD, `RV32I_FUNC3_ARITH_SUB: begin
					if (func7_i[5] == 1'b0) 						out_o = in0_i + in1_i;			// ADD
					else 											out_o = in0_i - in1_i; 			// SUB
				end
				`RV32I_FUNC3_ARITH_SLL: 							out_o = in0_i << in1_i[4:0];
				`RV32I_FUNC3_ARITH_SLT: begin
					if ($signed(in0_i) < $signed(in1_i)) 			out_o = 32'h00000001;
					else 											out_o = 32'h00000000;
				end
				`RV32I_FUNC3_ARITH_SLTU: begin
					if ($unsigned(in0_i) < $unsigned(in1_i)) 		out_o = 32'h00000001;
					else 											out_o = 32'h00000000;
				end
				`RV32I_FUNC3_ARITH_XOR:								out_o = in0_i ^ in1_i;
				`RV32I_FUNC3_ARITH_OR:								out_o = in0_i | in1_i;
				`RV32I_FUNC3_ARITH_AND:								out_o = in0_i & in1_i;

				`RV32I_FUNC3_ARITH_SRL, `RV32I_FUNC3_ARITH_SRA: begin
					if (func7_i[5] == 1'b0)							out_o = in0_i >> in1_i[4:0]; 	// SRL
					else 											out_o = in0_i >>> in1_i[4:0]; 	// SRA
				end
			endcase
		end

		// branch, none, jump
		default:;

	endcase

end

endmodule