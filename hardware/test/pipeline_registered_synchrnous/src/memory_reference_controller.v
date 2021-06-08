// note - module does not really support the byte, hword deviations
//`include "riscv.h"

module memory_reference_controller(
	input	[15:0] 	encoding_i,
	input 	[2:0]	func3_i,
	input 	[31:0]	src1_operand_i,
	input 	[31:0]	src2_operand_i,
	input 	[31:0]	immediate_i,
	output 			flag_load_o, 		// 1: operation is load
	output 			flag_store_o,  		// 1: operation is store
	output 	[31:0]	addr_target_o, 		// target address of load/store
	output 	[31:0]	data_target_o,		// data to write if store operation
	output 	[2:0]	exception_o 		// [2] - unknown func3
										// [1] - target addr word misaligned
										// [0] - target addr hword misaligned

);

// port mappings
// ---------------------------------------------------------------------------------------------------------------
reg 		flag_load_reg;
reg 		flag_store_reg;
reg [31:0]	addr_target_reg;
reg [31:0]	data_target_reg;
reg 		exception_reg;

assign flag_load_o 		= flag_load_reg;
assign flag_store_o 	= flag_store_reg;
assign addr_target_o 	= addr_target_reg;
assign data_target_o 	= data_target_reg;


// exception logic
// ---------------------------------------------------------------------------------------------------------------
assign exception_o[2] 	= exception_reg;
assign exception_o[1] 	= ((flag_load_reg | flag_store_reg) & addr_target_reg[1]) ? 1'b1 : 1'b0;
assign exception_o[0] 	= ((flag_load_reg | flag_store_reg) & addr_target_reg[0]) ? 1'b1 : 1'b0;


// operation logic
// ---------------------------------------------------------------------------------------------------------------

always @(*) begin

	// default outputs
	// -----------------------------------------------------------------------------------------------------------
	flag_load_reg 	= 1'b0;
	flag_store_reg 	= 1'b0;
	addr_target_reg	= 'b0;
	data_target_reg = 'b0;
	exception_reg 	= 1'b0;

	// operation logic
	// -----------------------------------------------------------------------------------------------------------
	case(encoding_i)

		// if load just need to set the target address and flag
		`ENCODING_LOAD: begin
			flag_load_reg 	= 1'b1;
			addr_target_reg = src1_operand_i + immediate_i;
		end

		// switch based on different variations of store operation
		`ENCODING_STORE: begin

			case(func3_i)

				`RV32I_FUNC3_STORE_BYTE: begin
					flag_store_reg 	= 1'b1;
					addr_target_reg = src1_operand_i + immediate_i;
					data_target_reg = src2_operand_i & 32'h000000FF;
				end

				`RV32I_FUNC3_STORE_HWORD: begin
					flag_store_reg 	= 1'b1;
					addr_target_reg = src1_operand_i + immediate_i;
					data_target_reg = src2_operand_i & 32'h0000FFFF;
				end

				`RV32I_FUNC3_STORE_WORD: begin
					flag_store_reg 	= 1'b1;
					addr_target_reg = src1_operand_i + immediate_i;
					data_target_reg = src2_operand_i;
				end

				default: exception_reg = 1'b1;

			endcase
		end
		`ENCODING_FLOAD: begin
			flag_load_reg 	= 1'b1;
			addr_target_reg = src1_operand_i + immediate_i;
		end
		`ENCODING_FSTORE: begin
			flag_store_reg 	= 1'b1;
			addr_target_reg = src1_operand_i + immediate_i;
			data_target_reg = src2_operand_i;
		end
		// incomplete case for one-hot so arbitrary default to avoid warning
		default: exception_reg = 1'b0;

	endcase

end

endmodule
