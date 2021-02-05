`ifndef _RISCV_H_
`define _RISCV_H_

// custom define encodings
// ------------------------------------------------
`define ENCODING_NONE 				9'b000000000
`define ENCODING_LUI 				9'b000000001
`define ENCODING_AUIPC 				9'b000000010
`define ENCODING_ARITH_REG 			9'b000000100
`define ENCODING_ARITH_IMM 			9'b000001000
`define ENCODING_JAL 				9'b000010000
`define ENCODING_JALR 				9'b000100000
`define ENCODING_BRANCH 			9'b001000000
`define ENCODING_LOAD 				9'b010000000
`define ENCODING_STORE 				9'b100000000
`define ENCODING_FLOAD               9'b000000111
`define ENCODING_FSTORE             9'b000100111
`define ENCODING_FMADD              9'b001000011
`define ENCODING_FMSUB              9`b000100111
`define ENCODING_FNMSUB             9'b001001011
`define ENCODING_FNMADD             9'b001001111
`define ENCODING_FARITH             9'b001010011
		
`ifdef SIMULATION_SYNTHESIS
	`define SP_BASE 				32'h0003F000
`else
	`define SP_BASE 				32'h03FFFFFC
`endif

//`define SP_BASE 					32'h03FFFFFC
`define OUTPUT_PERIPHERAL_BASE		32'h04000000	// byte addressible - read only
`define INPUT_PERIPHERAL_BASE 		32'h04000100 	// byte addressible - read and write

//`define STATE_HART_PIPELINE_DEPENDENCY_STALL	5'b10000
//`define STATE_HART_PIPELINE_JUMP 				5'b00001

//`define STATE_HART_PIPELINE_DEPENDENCY_STALL	6'b100000 	// on two stage dependency still enable stage 2
//`define STATE_HART_PIPELINE_JUMP 				6'b000001 	// enable writeback 

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

// func7 encodings
// ------------------------------------------------
`define RV32I_FUNC7_ARITH_REG0 		7'b0000000
`define RV32I_FUNC7_ARITH_REG1 		7'b0100000 		// SUB and SRA
`define RV32M_FUNC7 				7'b0000001 		// MUL, DIV, etc.

// source files
// ------------------------------------------------
`include "../internal/core/pipeline/dependency_handler.v"
`include "../internal/core/pipeline/memory_reference_controller.v"
`include "../internal/core/pipeline/port_switch.v"
`include "../internal/core/pipeline/riscv_32I_alu.v"
`include "../internal/core/pipeline/riscv_32M_alu_pipelined.v"
`include "../internal/core/pipeline/riscv_alu_32M_converter.v"
`include "../internal/core/pipeline/riscv_alu_pipelined.v"
`include "../internal/core/pipeline/stage1_instruction_decode.v"
`include "../internal/core/pipeline/stage4_memory_operation.v"
`include "../internal/core/pipeline/target_address_generator.v"
`include "../internal/core/pipeline/riscv_hart_6stage_pipeline.v"
`include "../internal/core/pipeline/riscv_hart_top.v"
`include "../internal/core/pipeline/udivider32b.v"
`include "../internal/core/pipeline/umultiplier32b.v"
`include "../internal/core/pipeline/pipeline_data_buffer.v"
`include "../internal/core/pipeline/memory_request_orderer.v"

`ifdef SAFE
	`define STATE_HART_PIPELINE_DEPENDENCY_STALL	5'b10000
	`define STATE_HART_PIPELINE_JUMP 				5'b00001
	`include "../internal/core/pipeline/riscv_hart_6stage_pipeline_semi_2stage_cache.v"

`else 
	`define STATE_HART_PIPELINE_DEPENDENCY_STALL	6'b100000 	// on two stage dependency still enable stage 2
	`define STATE_HART_PIPELINE_JUMP 				6'b000001
	//`include "../internal/core/pipeline/riscv_hart_6stage_pipeline_2stage_cache_semi2.v"
	`include "../internal/core/pipeline/riscv_hart_6stage_pipeline_2stage_cache.v"
	
`endif
//`include "../internal/core/pipeline/riscv_hart_6stage_pipeline_2stage_cache.v"
//`include "../internal/core/pipeline/riscv_hart_6stage_pipeline_2stage_cache_semi2.v"
//`include "../internal/core/pipeline/riscv_hart_6stage_pipeline_semi_2stage_cache.v"

`include "../internal/core/pipeline/riscv_hart_top.v"

`endif // RISCV_H_