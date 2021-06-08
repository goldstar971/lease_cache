//`include "riscv.h"
`include "../../../../include/float.h"
module riscv_alu_pipelined #(
	parameter RV32F =0,
	parameter RV32M = 0,
	parameter DIV_STAGES = 1,
	parameter MUL_STAGES = 0
)(
	input             clock_float_i,
	input 				clock_div_i,
	input 		[31:0]	in0_i,
	input 		[31:0]	in1_i,
	input       [31:0]  in2_i,
	input 		[31:0]	imm0_i,
	input 		[31:0]	addr_i,
	input 		[15:0]	encoding_i,
	input 		[2:0]	func3_i,
	input       [4:0] fsrc2_i,
	input       [2:0] rm_i,
	input		[6:0]	func7_i,
	input       [4:0]   func5_i,
	output		[31:0]	out_o,
	output      [4:0]   stall_cycles
	
);

// RISCV 32I extension
wire [31:0] alu_32i_result;
riscv_32I_alu riscv_32i_alu_inst(
	.in0_i 		(in0_i			), 		// Tsrc1
	.in1_i		(in1_i			), 		// Tsrc2
	.imm0_i		(imm0_i			), 		// immediate for type I 
	.addr_i		(addr_i			), 		// for auipc
	.encoding_i	(encoding_i), 		// switch control
	.func3_i	(func3_i		), 		// switch control
	.func7_i	(func7_i		), 		// switch control
	.out_o		(alu_32i_result	)
);
//will be optimized away if not used
wire [31:0] alu_32m_result;
wire [31:0] alu_32f_result;
wire [3:0] falu_stall_cycles;
wire [3:0] malu_stall_cycles;




generate 
	// RISCV 32M extension
	
	if (RV32M) begin
		riscv_32M_alu_pipelined  #(
			.DIV_STAGES	(DIV_STAGES 	),
			.MUL_STAGES (MUL_STAGES     )
		) riscv_32m_alu_inst (
			.clock_div_i(clock_div_i 	),
			.in0_i 		(in0_i 			), 		// Tsrc1
			.in1_i 		(in1_i 			), 		// Tsrc2
			.func3_i 	(func3_i 		), 		// operation switch
			.result_o 	(alu_32m_result	), 		// modulated output (2's Comp if necessary)
			.stall_cycles(malu_stall_cycles)
		);
	end
	// RISCV 32F Extension
	if (RV32F) begin

		riscv_32F_alu_pipelined riscv_32f_alu_inst(
		.clock_float_i(clock_div_i),
		.in0_i 		(in0_i			), 		// Tsrc1
		.in1_i		(in1_i			), 		// Tsrc2
		.in2_i      (in2_i          ),
		.encoding_i	(encoding_i), 		// switch control
		.func5_i    (func5_i        ),       //switch control
		.rm_i       (rm_i),
		.fsrc2_i    (fsrc2_i),
		.stall_cycles(falu_stall_cycles),
		.out_o		(alu_32f_result	));
	end 
	

		
	if(RV32F && RV32M) begin
		assign stall_cycles =(encoding_i[15:11]) ? falu_stall_cycles : ((encoding_i ==`ENCODING_ARITH_REG) &(func7_i== `RV32M_FUNC7)) ?
		malu_stall_cycles : 'b0;
		assign out_o = ( (encoding_i == `ENCODING_ARITH_REG) & (func7_i == `RV32M_FUNC7) ) ? alu_32m_result : (encoding_i[15:11]) ?
		alu_32f_result : alu_32i_result;
	end 
	else if(RV32F) begin   
		assign stall_cycles =(encoding_i[15:11]) ? falu_stall_cycles :'b0;
		assign out_o =(encoding_i[15:11]) ? alu_32f_result : alu_32i_result;
	end
	else if(RV32M) begin
		assign stall_cycles = ((encoding_i ==`ENCODING_ARITH_REG) &(func7_i== `RV32M_FUNC7)) ? malu_stall_cycles : 'b0;
		assign out_o =  ( (encoding_i == `ENCODING_ARITH_REG) & (func7_i == `RV32M_FUNC7) ) ? alu_32m_result : alu_32i_result;
	end
	else begin 
		assign stall_cycles = 'b0;
		assign out_o = alu_32i_result;
	end

		
endgenerate

endmodule