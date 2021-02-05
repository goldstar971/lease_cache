`ifndef _RISCV_H_
`define _RISCV_H_

// misc
// ------------------------------------------
`define BW_WORD	32


// RV32M Standard Extension
// ------------------------------------------
`define 	OPCODE_32M 			7'b0110011

`define 	FUNC7_32M 			7'b0000001

`define 	FUNC3_32M_MUL 		3'b000
`define 	FUNC3_32M_MULH 		3'b001
`define 	FUNC3_32M_MULHSU 	3'b010
`define 	FUNC3_32M_MULHU 	3'b011
`define 	FUNC3_32M_DIV 		3'b100
`define 	FUNC3_32M_DIVU 		3'b101
`define 	FUNC3_32M_REM 		3'b110
`define 	FUNC3_32M_REMU 		3'b111


// RV32I Standard 
// ------------------------------------------
`define 	OPCODE_R_32b 		7'b0110011
`define 	OPCODE_I_LOAD 		7'b0000011
`define 	OPCODE_I_FENCE 		7'b0001111
`define 	OPCODE_I_32b 		7'b0010011
`define 	OPCODE_I_64b 		7'b0011011
`define 	OPCODE_I_JALR 		7'b1100111
`define 	OPCODE_I_EOPS 		7'b1110011
`define 	OPCODE_S_STORE 		7'b0100011
`define 	OPCODE_SB_BRANCH 	7'b1100011
`define 	OPCODE_U_LUI 		7'b0110111
`define 	OPCODE_U_AUIPC 		7'b0010111
`define 	OPCODE_J_JAL 		7'b1101111

`define	 	FUNC_R_ADD  		3'b000
`define	 	FUNC_R_SUB  		3'b000		// difference in func7
`define	 	FUNC_R_SLL  		3'b001
`define	 	FUNC_R_SLT  		3'b010
`define	 	FUNC_R_SLTU  		3'b011
`define	 	FUNC_R_XOR  		3'b100
`define	 	FUNC_R_SRL  		3'b101
`define	 	FUNC_R_SRA  		3'b101		// difference in func7
`define	 	FUNC_R_OR  			3'b110
`define	 	FUNC_R_AND  		3'b111

`define 	FUNC_I_ADDI  		3'b000
`define 	FUNC_I_SLLI  		3'b001
`define 	FUNC_I_SLTI  		3'b010
`define 	FUNC_I_SLTIU  		3'b011
`define 	FUNC_I_XORI  		3'b100
`define 	FUNC_I_SRLI  		3'b101
`define 	FUNC_I_SRAI  		3'b101		// difference in func7
`define 	FUNC_I_ORI  		3'b110
`define 	FUNC_I_ANDI  		3'b111
`define 	FUNC_I_JALR  		3'b000
`define 	FUNC_I_LB  			3'b000
`define 	FUNC_I_LH  			3'b001
`define 	FUNC_I_LW  			3'b010
`define 	FUNC_I_LBU  		3'b100
`define 	FUNC_I_LHU  		3'b101
`define 	FUNC_I_LWU  		3'b110

`define 	FUNC_SB_BEQ  		3'b000
`define 	FUNC_SB_BNE  		3'b001
`define 	FUNC_SB_BLT  		3'b100
`define 	FUNC_SB_BGE 		3'b101
`define 	FUNC_SB_BLTU  		3'b110
`define 	FUNC_SB_BGEU  		3'b111

`define 	FUNC_S_SB  			3'b000
`define 	FUNC_S_SH  			3'b001
`define 	FUNC_S_SW  			3'b010


`endif // _RISCV_H_