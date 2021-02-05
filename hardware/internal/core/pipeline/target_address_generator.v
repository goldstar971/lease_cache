// for jump and branch instructions generates a target address
//`include "riscv.h"

module target_address_generator(

	input 	[8:0]		encoding_i,
	input 	[31:0]		instruction_addr_i, 	// address of current instruction being evaluated
	input 	[31:0]		instruction_next_addr_i,// address of next instruction in the pipeline - to determine jump exception
	input 	[2:0]		func3_i,
	input 	[31:0]		src1_operand_i,
	input 	[31:0]		src2_operand_i,
	input 	[31:0]		immediate_i, 			// immediate value to modulate jump
	output  			flag_jump_o, 			// 1: jump/branch operation
	output 	[31:0] 		addr_target_o, 			// target address of operation
	output 	[31:0]		addr_writeback_o, 		// address/value to writeback to register file 	
	output 	[3:0]		exception_o  			// [3] - unknown/unsupported func3 if branch operation
												// [2] - if jump/branch goes high if next instruction addr is not == target of operation
												// [1] - target address word misaligned
												// [0] - target address half-word misaligned
);

// port mappings
// ---------------------------------------------------------------------------------------------------------------
reg 			flag_jump_reg;
reg 	[31:0]	addr_target_reg;
reg 	[31:0]	addr_writeback_reg;
reg 			exception_reg; 			// unknown func3 exception
wire 	[2:0] 	exception_bus; 			// target address exceptions

assign flag_jump_o 		= flag_jump_reg;
assign addr_target_o 	= addr_target_reg;
assign addr_writeback_o = addr_writeback_reg;
assign exception_o 		= {exception_reg, exception_bus};


// exception logic
// ---------------------------------------------------------------------------------------------------------------
assign exception_bus[2] = 	(flag_jump_reg) ? 
								(addr_target_reg != instruction_next_addr_i) ? 1'b1 : 1'b0
							: 1'b0;																// make sure following address is correctly 
																								// applied, throw exception if out of order
																								// or mispredicted or error

//assign exception_bus[2] = ((flag_jump_reg & (addr_target_reg != instruction_next_addr_i)) ? 1'b1 : 1'b0; 	
																											
																											
assign exception_bus[1] = (flag_jump_reg & addr_target_reg[1]) ? 1'b1 : 1'b0;
assign exception_bus[0] = (flag_jump_reg & addr_target_reg[0]) ? 1'b1 : 1'b0;


// module logic
// ---------------------------------------------------------------------------------------------------------------
always @(*) begin

	// default outputs
	// -----------------------------------------------------------------------------------------------------------
	flag_jump_reg 		= 1'b0;
	addr_target_reg 	= 'b0;
	addr_writeback_reg 	= 'b0;
	exception_reg 		= 1'b0;


	// encoding combinational logic
	// -----------------------------------------------------------------------------------------------------------
	case(encoding_i) 

		`ENCODING_JAL: begin
			flag_jump_reg = 1'b1;
			addr_writeback_reg = instruction_addr_i + 4; 			// store addr. of instruction following jump 
			addr_target_reg = instruction_addr_i + immediate_i; 	// address already in terms of hword offset (stage1 handles it)
		end

		`ENCODING_JALR: begin
			flag_jump_reg = 1'b1;
			addr_writeback_reg = instruction_addr_i + 4; 						// store addr. of instruction following jump 
			addr_target_reg = (src1_operand_i + immediate_i) & 32'hFFFFFFFE; 	// register relative, set LSb to zero according to RISCV-ISA
		end

		`ENCODING_BRANCH: begin

			// switch based on branch variant
			case(func3_i)

				`RV32I_FUNC3_BRANCH_BEQ: begin	
					flag_jump_reg = 1'b1;
					addr_writeback_reg = 'b0;
					if (src1_operand_i == src2_operand_i) 	addr_target_reg = instruction_addr_i + immediate_i;
					else 									addr_target_reg = instruction_addr_i + 4;
				end

				`RV32I_FUNC3_BRANCH_BNE: begin
					flag_jump_reg = 1'b1;
					addr_writeback_reg = 'b0;
					if (src1_operand_i != src2_operand_i) 	addr_target_reg = instruction_addr_i + immediate_i;
					else 									addr_target_reg = instruction_addr_i + 4;
				end

				`RV32I_FUNC3_BRANCH_BLT: begin
					flag_jump_reg = 1'b1;
					addr_writeback_reg = 'b0;
					if ($signed(src1_operand_i) < $signed(src2_operand_i)) 	addr_target_reg = instruction_addr_i + immediate_i;
					else 													addr_target_reg = instruction_addr_i + 4;
				end

				`RV32I_FUNC3_BRANCH_BLTU: begin
					flag_jump_reg = 1'b1;
					addr_writeback_reg = 'b0;
					if (src1_operand_i < src2_operand_i) 	addr_target_reg = instruction_addr_i + immediate_i;
					else 									addr_target_reg = instruction_addr_i + 4;
				end

				`RV32I_FUNC3_BRANCH_BGE: begin
					flag_jump_reg = 1'b1;
					addr_writeback_reg = 'b0;
					if ($signed(src1_operand_i) >= $signed(src2_operand_i)) addr_target_reg = instruction_addr_i + immediate_i;
					else 													addr_target_reg = instruction_addr_i + 4;
				end

				`RV32I_FUNC3_BRANCH_BGEU: begin
					flag_jump_reg = 1'b1;
					addr_writeback_reg = 'b0;
					if (src1_operand_i > src2_operand_i) 	addr_target_reg = instruction_addr_i + immediate_i;
					else 									addr_target_reg = instruction_addr_i + 4;
				end

				// unknown branch derivative so throw exception
				default: exception_reg = 1'b1; 

			endcase
		end

		default: exception_reg = 1'b0;

	endcase

end

endmodule