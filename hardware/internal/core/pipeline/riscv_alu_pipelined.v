//`include "riscv.h"

module riscv_alu_pipelined #(
	parameter RV32M = 0,
	parameter DIV_STAGES = 1
)(
	input 				clock_div_i,
	input 		[31:0]	in0_i,
	input 		[31:0]	in1_i,
	input 		[31:0]	imm0_i,
	input 		[31:0]	addr_i,
	input 		[8:0]	encoding_i,
	input 		[2:0]	func3_i,
	input		[6:0]	func7_i,
	output		[31:0]	out_o,
	output 				flag_mult_o,
	output 				flag_div_o
);

// RISCV 32I extension
wire [31:0] alu_32i_result;
riscv_32I_alu riscv_32i_alu_inst(
	.in0_i 		(in0_i			), 		// Tsrc1
	.in1_i		(in1_i			), 		// Tsrc2
	.imm0_i		(imm0_i			), 		// immediate for type I 
	.addr_i		(addr_i			), 		// for auipc
	.encoding_i	(encoding_i		), 		// switch control
	.func3_i	(func3_i		), 		// switch control
	.func7_i	(func7_i		), 		// switch control
	.out_o		(alu_32i_result	)
);

// RISCV 32M extension
generate 
	if (RV32M) begin

		wire [31:0] alu_32m_result;
		riscv_32M_alu_pipelined  #(
			.DIV_STAGES	(DIV_STAGES 	)
		) riscv_32m_alu_inst (
			.clock_div_i(clock_div_i 	),
			.in0_i 		(in0_i 			), 		// Tsrc1
			.in1_i 		(in1_i 			), 		// Tsrc2
			.func3_i 	(func3_i 		), 		// operation switch
			.result_o 	(alu_32m_result	) 		// modulated output (2's Comp if necessary)
		);

		// mux the correct result
		assign out_o = ( (encoding_i == `ENCODING_ARITH_REG) & (func7_i == `RV32M_FUNC7) ) ? alu_32m_result : alu_32i_result;
		assign flag_mult_o = ( (encoding_i == `ENCODING_ARITH_REG) & (func7_i == `RV32M_FUNC7) & (!func3_i[2]) ) ? 1'b1 : 1'b0;
		assign flag_div_o =  ( (encoding_i == `ENCODING_ARITH_REG) & (func7_i == `RV32M_FUNC7) & (func3_i[2]) ) ? 1'b1 : 1'b0;
	end
	else begin
		assign out_o = alu_32i_result;
		assign flag_mult_o = 1'b0;
		assign flag_div_o = 1'b0;
	end
endgenerate

endmodule