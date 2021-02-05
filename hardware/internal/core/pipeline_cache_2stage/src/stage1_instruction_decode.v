//`include "riscv.h"

module stage1_instruction_decode(

	input 	[31:0]	instruction_i,
	output 	[8:0]	encoding_o, 		// one hot encoding of instruction type
	output 	[6:0] 	func7_o,
	output 	[2:0] 	func3_o,
	output 	[4:0]	fsrc2_o,
	output 	[4:0]	fsrc1_o,
	output 	[4:0]	fdest_o,
	output 	[31:0]	imm32_o, 			// generate immediate value during decode because 32b imm is consistent across all 32b extensions
	output 			exception_o 		// unknown opcode

);

// port mappings
// -----------------------------------------------------------------------------------
reg 	[8:0]	encoding_reg;
reg 	[6:0] 	func7_reg;
reg 	[2:0] 	func3_reg;
reg 	[4:0]	fsrc2_reg;
reg 	[4:0]	fsrc1_reg;
reg 	[4:0]	fdest_reg;
reg 	[31:0]	imm32_reg;
reg 			exception_reg;

assign encoding_o 	= encoding_reg;
assign func7_o 		= func7_reg;
assign func3_o 		= func3_reg;
assign fsrc2_o 		= fsrc2_reg;
assign fsrc1_o 		= fsrc1_reg;
assign fdest_o 		= fdest_reg;
assign imm32_o 		= imm32_reg;
assign exception_o 	= exception_reg;


// stage combinational logic
// -----------------------------------------------------------------------------------

always @(*) begin

	// default outputs
	// -------------------------------------------------------------------------------
	encoding_reg 	= `ENCODING_NONE;
	func7_reg  		= 'b0;
	func3_reg  		= 'b0;
	fsrc2_reg  		= 'b0;
	fsrc1_reg  		= 'b0;
	fdest_reg  		= 'b0;
	imm32_reg  		= 'b0;
	exception_reg 	= 1'b0;

	// instruction decoding - by opcode field
	// -------------------------------------------------------------------------------
	case(instruction_i[6:0])

		// RV32I extension instructions
		// ---------------------------------------------------------------------------
		// supported instructions
		`RV32I_OPCODE_LUI: begin
			encoding_reg 	= `ENCODING_LUI;		
			fdest_reg 		= instruction_i[11:7];
			imm32_reg 		= {instruction_i[31:12],12'h000};
		end

		`RV32I_OPCODE_AUIPC: begin
			encoding_reg 	= `ENCODING_AUIPC;		
			fdest_reg 		= instruction_i[11:7];
			imm32_reg 		= {instruction_i[31:12],12'h000};
		end

		`RV32I_OPCODE_JAL: 	begin												
			encoding_reg 	= `ENCODING_JAL;		
			fdest_reg 		= instruction_i[11:7];
			imm32_reg 		= {{11{instruction_i[31]}}, instruction_i[31], instruction_i[19:12], instruction_i[20], instruction_i[30:21], 1'b0};
		end

		`RV32I_OPCODE_JALR: begin
			encoding_reg 	= `ENCODING_JALR;
			fsrc1_reg 		= instruction_i[19:15];
			fdest_reg 		= instruction_i[11:7];
			imm32_reg 		= {{20{instruction_i[31]}},instruction_i[31:20]};
		end

		`RV32I_OPCODE_LOAD: begin
			encoding_reg 	= `ENCODING_LOAD;
			fsrc1_reg 		= instruction_i[19:15];
			func3_reg 		= instruction_i[14:12];
			fdest_reg 		= instruction_i[11:7];
			imm32_reg 		= {{20{instruction_i[31]}},instruction_i[31:20]};
		end 

		`RV32I_OPCODE_ARITH_IMM: begin
			encoding_reg 	= `ENCODING_ARITH_IMM;
			fsrc1_reg 		= instruction_i[19:15];
			func3_reg 		= instruction_i[14:12];
			fdest_reg 		= instruction_i[11:7];
			imm32_reg 		= {{20{instruction_i[31]}},instruction_i[31:20]};
		end

		`RV32I_OPCODE_BRANCH: begin
			encoding_reg 	= `ENCODING_BRANCH;
			fsrc2_reg 		= instruction_i[24:20]; 
			fsrc1_reg 		= instruction_i[19:15]; 
			func3_reg 		= instruction_i[14:12];
			imm32_reg 		= {{19{instruction_i[31]}},instruction_i[31],instruction_i[7],instruction_i[30:25],instruction_i[11:8],1'b0};
		end

		`RV32I_OPCODE_STORE: begin
			encoding_reg 	= `ENCODING_STORE;
			fsrc2_reg 		= instruction_i[24:20]; 
			fsrc1_reg 		= instruction_i[19:15]; 
			func3_reg 		= instruction_i[14:12];
			imm32_reg 		= {{20{instruction_i[31]}},instruction_i[31:25],instruction_i[11:7]};
		end


		// RV32I register-register and RV32M extension instructions
		// ---------------------------------------------------------------------------
		`RV32I_OPCODE_ARITH_REG: begin
			encoding_reg = `ENCODING_ARITH_REG;
			{func7_reg,fsrc2_reg,fsrc1_reg,func3_reg,fdest_reg} = instruction_i[31:7];
		end


		// Unknown instructions - raise exception
		// ---------------------------------------------------------------------------
		default: begin
			exception_reg 	= 1'b1;
		end

	endcase

end

endmodule