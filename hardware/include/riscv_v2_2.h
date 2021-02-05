`ifndef _RISCV_H_
`define _RISCV_H_

// custom define encodings
// ------------------------------------------------
`define ENCODING_NONE 				16'b0000000000000000
`define ENCODING_LUI 				16'b0000000000000001
`define ENCODING_AUIPC 				16'b0000000000000010
`define ENCODING_ARITH_REG 			16'b0000000000000100
`define ENCODING_ARITH_IMM 			16'b0000000000001000
`define ENCODING_JAL 				16'b0000000000010000
`define ENCODING_JALR 				16'b0000000000100000
`define ENCODING_BRANCH 			16'b0000000001000000
`define ENCODING_LOAD 				16'b0000000010000000
`define ENCODING_STORE 				16'b0000000100000000
`define ENCODING_FLOAD              16'b0000001000000000
`define ENCODING_FSTORE             16'b0000010000000000
`define ENCODING_FMADD              16'b0000100000000000
`define ENCODING_FMSUB              16'b0001000000000000
`define ENCODING_FNMSUB             16'b0010000000000000
`define ENCODING_FNMADD             16'b0100000000000000
`define ENCODING_FARITH             16'b1000000000000000

`define SP_BASE 					32'h03FFFFFC
`define OUTPUT_PERIPHERAL_BASE		32'h04000000	// byte addressible - read only
`define INPUT_PERIPHERAL_BASE 		32'h04000100 	// byte addressible - read and write

`define STATE_HART_PIPELINE_DEPENDENCY_STALL	5'b10000
`define STATE_HART_PIPELINE_JUMP 				5'b00001

// opcode encodings
// ------------------------------------------------
`define RV32I_OPCODE_LUI 			7'b0110111
`define RV32I_OPCODE_AUIPC 			7'b0010111
`define RV32I_OPCODE_JAL 			7'b1101111
`define RV32I_OPCODE_JALR 			7'b1100111
`define RV32I_OPCODE_BRANCH 		7'b1100011
`define RV32I_OPCODE_LOAD 			7'b0000011
`define RV32I_OPCODE_STORE 			7'b0100011
`define RV32I_OPCODE_ARITH_IMM 		7'b0010011
`define RV32I_OPCODE_ARITH_REG 		7'b0110011 	// note also opcode for RV32M
/*`define RV32I_OPCODE_FENCE		7'b0001111
`define RV32I_OPCODE_ENVCALL 		7'b1110011*/




`define RV32M_OPCODE				7'b0110011

`define RV32F_OPCODE_LOAD			7'b0000111
`define RV32F_OPCODE_STORE 			7'b0100111
`define RV32F_OPCODE_FMADD 			7'b1000011
`define RV32F_OPCODE_FMSUB 			7'b1000111
`define RV32F_OPCODE_FNMSUB 		7'b1001011
`define RV32F_OPCODE_FNMADD 		7'b1001111
`define RV32F_OPCODE_ARITH  		7'b1010011

// func3 encodings
// ------------------------------------------------
`define RV32I_FUNC3_ARITH_ADDI		3'b000
`define RV32I_FUNC3_ARITH_SLLI		3'b001
`define RV32I_FUNC3_ARITH_SLTI		3'b010
`define RV32I_FUNC3_ARITH_SLTIU		3'b011
`define RV32I_FUNC3_ARITH_XORI		3'b100
`define RV32I_FUNC3_ARITH_SRLI		3'b101
`define RV32I_FUNC3_ARITH_SRAI		3'b101
`define RV32I_FUNC3_ARITH_ORI		3'b110
`define RV32I_FUNC3_ARITH_ANDI		3'b111

`define RV32I_FUNC3_ARITH_ADD		3'b000
`define RV32I_FUNC3_ARITH_SUB		3'b000
`define RV32I_FUNC3_ARITH_SLL		3'b001
`define RV32I_FUNC3_ARITH_SLT		3'b010
`define RV32I_FUNC3_ARITH_SLTU		3'b011
`define RV32I_FUNC3_ARITH_XOR		3'b100
`define RV32I_FUNC3_ARITH_SRL		3'b101
`define RV32I_FUNC3_ARITH_SRA		3'b101
`define RV32I_FUNC3_ARITH_OR		3'b110
`define RV32I_FUNC3_ARITH_AND		3'b111

`define RV32I_FUNC3_BRANCH_BEQ 		3'b000
`define RV32I_FUNC3_BRANCH_BNE 		3'b001
`define RV32I_FUNC3_BRANCH_BLT 		3'b100
`define RV32I_FUNC3_BRANCH_BGE 		3'b101
`define RV32I_FUNC3_BRANCH_BLTU 	3'b110
`define RV32I_FUNC3_BRANCH_BGEU 	3'b111

`define RV32I_FUNC3_LOAD_BYTE 		3'b000
`define RV32I_FUNC3_LOAD_HWORD 		3'b001
`define RV32I_FUNC3_LOAD_WORD 		3'b010
`define RV32I_FUNC3_LOAD_UBYTE 		3'b100
`define RV32I_FUNC3_LOAD_UHWORD 	3'b101

`define RV32I_FUNC3_STORE_BYTE 		3'b000
`define RV32I_FUNC3_STORE_HWORD 	3'b001
`define RV32I_FUNC3_STORE_WORD 		3'b010

`define RV32M_FUNC3_MUL 			3'b000
`define RV32M_FUNC3_MULH 			3'b001
`define RV32M_FUNC3_MULHSU 			3'b010
`define RV32M_FUNC3_MULHU 			3'b011
`define RV32M_FUNC3_DIV 			3'b100
`define RV32M_FUNC3_DIVU 			3'b101
`define RV32M_FUNC3_REM 			3'b110
`define RV32M_FUNC3_REMU 			3'b111


 // func5 encodings
 //------------------------------------------------
`define RV32F_FUNC5_ADD          	5'b00000
`define RV32F_FUNC5_SUB 			5'b00001
`define RV32F_FUNC5_MUL 			5'b00010
`define RV32F_FUNC5_DIV 			5'b00011
`define RV32F_FUNC5_SGNJ 			5'b00100 
`define RV32F_FUNC5_CMP  			5'b10100
`define RV32F_FUNC5_FCVT_FTI 		5'b11000
`define RV32F_FUNC5_SQRT 			5'b01011
`define RV32F_FUNC5_FMIN_MAX 		5'b00101
`define RV32F_FUNC5_MV_WX       	5'b11110
`define RV32F_FUNC5_CLASS        	5'b11100
`define RV32F_FUNC5_FCVT_ITF 		5'b11010 

`define RV32F_FUNC5_RM_EQ          3'b010
`define RV32F_FUNC5_RM_LT          3'b001
`define RV32F_FUNC5_RM_LE          3'b000
`define RV32F_FUNC5_RM_CLASS       3'b001
`define RV32F_FUNCS_RM_MV_WX       3'b000
`define RV32F_FUNC5_RM_MV_XW       3'b000
`define RV32F_FUNC5_RM_MIN         3'b000
`define RV32F_FUNC5_RM_MAX         3'b001
`define RV32F_FUNC5_RS2_SGN        5'b00000
`define RV32F_FUNC5_RS2_USGN       5'b00001
`define RV32F_FUNC5_RM_SGNJ        3'b000
`define RV32F_FUNC5_RM_SGNJN       3'b001
`define RV32F_FUNC5_RM_SGNJX       3'b010

`define RV32F_OPCODE_LOAD			7'b0000111
`define RV32F_OPCODE_STORE 			7'b0100111
`define RV32F_OPCODE_FMADD 			7'b1000011
`define RV32F_OPCODE_FMSUB 			7'b1000111
`define RV32F_OPCODE_FNMSUB 		7'b1001011
`define RV32F_OPCODE_FNMADD 		7'b1001111
`define RV32F_OPCODE_ARITH  		7'b1010011



// func7 encodings
// ------------------------------------------------
`define RV32I_FUNC7_ARITH_REG0 		7'b0000000
`define RV32I_FUNC7_ARITH_REG1 		7'b0100000 		// SUB and SRA
`define RV32M_FUNC7 				7'b0000001 		// MUL, DIV, etc.

// source files
// ------------------------------------------------
`ifdef FLOAT_INSTRUCTIONS
	`include "../internal/core/pipeline_f/dependency_handler.v"
	`include "../internal/core/pipeline_f/memory_reference_controller.v"
	`include "../internal/core/pipeline_f/port_switch.v"
	`include "../internal/core/pipeline_f/riscv_32I_alu.v"
	`include "../internal/core/pipeline_f/riscv_32M_alu_pipelined.v"
	`include "../internal/core/pipeline_f/riscv_32F_alu_pipelined.v"
	`include "../internal/core/pipeline_f/riscv_alu_32M_converter.v"
	`include "../internal/core/pipeline_f/riscv_alu_pipelined.v"
	`include "../internal/core/pipeline_f/riscv_hart_6stage_pipeline.v"
	`include "../internal/core/pipeline_f/riscv_hart_top.v"
	`include "../internal/core/pipeline_f/stage1_instruction_decode.v"
	`include "../internal/core/pipeline_f/stage4_memory_operation.v"
	`include "../internal/core/pipeline_f/target_address_generator.v"
	`include "../internal/core/pipeline_f/udivider32b.v"
	`include "../internal/core/pipeline_f/umultiplier32b.v"
`else
	`include "../internal/core/pipeline/dependency_handler.v"
	`include "../internal/core/pipeline/memory_reference_controller.v"
	`include "../internal/core/pipeline/port_switch.v"
	`include "../internal/core/pipeline/riscv_32I_alu.v"
	`include "../internal/core/pipeline/riscv_32M_alu_pipelined.v"
	`include "../internal/core/pipeline/riscv_alu_32M_converter.v"
	`include "../internal/core/pipeline/riscv_alu_pipelined.v"
	`include "../internal/core/pipeline/riscv_hart_6stage_pipeline.v"
	`include "../internal/core/pipeline/riscv_hart_top.v"
	`include "../internal/core/pipeline/stage1_instruction_decode.v"
	`include "../internal/core/pipeline/stage4_memory_operation.v"
	`include "../internal/core/pipeline/target_address_generator.v"
	`include "../internal/core/pipeline/udivider32b.v"
	`include "../internal/core/pipeline/umultiplier32b.v"
`endif

`endif // RISCV_H_