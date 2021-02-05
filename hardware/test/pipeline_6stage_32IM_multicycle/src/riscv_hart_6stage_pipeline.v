`include "riscv.h"

module riscv_hart_6stage_pipeline(

	// system ports
	input 				clock_i,
	input 				reset_i,

	// instruction memory ports - just read
	input 				inst_done_i,
	input 	[31:0] 		inst_data_i,
	output 				inst_req_o,
	output 	[31:0]		inst_addr_o,

	// data memory ports - read and write
	input 				data_done_i,
	input 	[31:0] 		data_data_i,
	output 				data_req_o,
	output 				data_wren_o,
	output 	[31:0]		data_addr_o,
	output 	[31:0]		data_data_o
);

// port mapping
// --------------------------------------------------------------------------------------------
reg 			inst_req_reg;
reg 	[31:0]	inst_addr_reg;
reg 			data_req_reg;
reg 			data_wren_reg;
reg 	[31:0]	data_addr_reg;
reg 	[31:0]	data_data_reg;

assign inst_req_o 	= inst_req_reg;
assign inst_addr_o 	= inst_addr_reg;
assign data_req_o 	= data_req_reg;
assign data_wren_o 	= data_wren_reg;
assign data_addr_o 	= data_addr_reg;
assign data_data_o 	= data_data_reg;


// HART internal signals
// --------------------------------------------------------------------------------------------

// generic internal signals
reg 	[31:0]	RF 	[0:31];
reg 	[31:0]	PC;

// stage 1 
reg 	[31:0]	IR_1_reg, inst_addr_1_reg;

wire 	[31:0]	imm32_1;
wire 	[8:0]	inst_encoding_1;
wire 	[4:0]	fsrc1_1, fsrc2_1, fdest_1;
wire 	[6:0]	func7_1;
wire 	[2:0]	func3_1;

// stage 2
reg 	[31:0]	inst_addr_2_reg;
reg 	[8:0]	inst_encoding_2_reg;
reg 	[6:0]	func7_2_reg;
reg 	[2:0]	func3_2_reg;
reg 	[4:0]	fsrc1_2_reg, fsrc2_2_reg, fdest_2_reg;
reg 	[31:0]	imm32_2_reg;

wire 	[31:0]	Tsrc1_2, Tsrc2_2;
wire 		flag_dependency_2;
wire 			flag_jump_2;//, flag_jump_taken_2;
wire 	[31:0]	jump_addr_target_2, jump_addr_wb_2;

// stage 3
reg 	[31:0]	inst_addr_3_reg;
reg 	[8:0]	inst_encoding_3_reg;
reg 	[6:0]	func7_3_reg;
reg 	[2:0]	func3_3_reg;
reg 	[4:0]	fdest_3_reg;
reg 	[31:0]	Tsrc1_3_reg, Tsrc2_3_reg;
reg 	[31:0]	imm32_3_reg;
reg 	[31:0]	jump_addr_wb_3_reg;

wire 	[31:0] 	alu_result_3;
reg 	[31:0]	mux_output_3;
//reg 			flag_ldst_3, flag_ldst_rw_3;
//wire 	[31:0]	ldst_addr_3, ldst_data_3;
wire 	[31:0]	ldst_addr_2, ldst_data_2;

// stage 4
reg 	[8:0]	inst_encoding_4_reg;
reg 	[2:0]	func3_4_reg;
reg 	[4:0]	fdest_4_reg;
reg 	[31:0]	mux_output_4_reg;

reg 	[31:0]	wb_val_4;
reg 			flag_wb_4;
//reg 			flag_mem_data_mux;

reg 	[31:0] 	data_ldst_reg;

// ------------------------------------------------------------------------------------------------------------------------------
// Stage 5 - Register Writeback
// ------------------------------------------------------------------------------------------------------------------------------
// nothing required here -  the controller will handle in previous step?

// ------------------------------------------------------------------------------------------------------------------------------
// Stage 4 - Memory Operation
// ------------------------------------------------------------------------------------------------------------------------------
// if flow control then do nothing
// if load then mux the value to output
// if store then do nothing
// if ALU then mux the input to output

always @(*) begin

	// only route non-zero register destinations
	if (fdest_4_reg != 5'b00000) begin

		// mux through depending on type of instruction
		case(inst_encoding_4_reg)

			// arithmetic and jumps
			`ENCODING_LUI, `ENCODING_AUIPC, `ENCODING_ARITH_IMM, `ENCODING_ARITH_REG, `ENCODING_JAL, `ENCODING_JALR: begin
				flag_wb_4 = 1'b1;
				wb_val_4 = mux_output_4_reg;
			end

			// load - adjust per instruction
			`ENCODING_LOAD: begin
				flag_wb_4 = 1'b1;
				case (func3_4_reg) 
					`RV32I_FUNC3_LOAD_BYTE: begin
						wb_val_4 = {{24{data_ldst_reg[7]}}, data_ldst_reg[7:0]};
						//wb_val_4 = {{24{data_data_i[7]}}, data_data_i[7:0]};
						//if	(flag_mem_data_mux) 	wb_val_4 = {{24{mem_data1_i[7]}}, mem_data1_i[7:0]};
						//else 						wb_val_4 = {{24{per_data_i[7]}}, per_data_i[7:0]};
					end
					`RV32I_FUNC3_LOAD_HWORD: begin	
						wb_val_4 = {{16{data_ldst_reg[15]}}, data_ldst_reg[15:0]};
						//wb_val_4 = {{16{data_data_i[15]}}, data_data_i[15:0]};
						//if	(flag_mem_data_mux) 	wb_val_4 = {{16{mem_data1_i[15]}}, mem_data1_i[15:0]};
						//else 						wb_val_4 = {{16{per_data_i[15]}}, per_data_i[15:0]};
					end
					`RV32I_FUNC3_LOAD_WORD: begin
						wb_val_4 = data_ldst_reg;	
						//wb_val_4 = data_data_i;
						//if	(flag_mem_data_mux) 	wb_val_4 = mem_data1_i;
						//else						wb_val_4 = per_data_i;
					end
					`RV32I_FUNC3_LOAD_UBYTE: begin	
						wb_val_4 = {{24{1'b0}}, data_ldst_reg[7:0]};
						//wb_val_4 = {{24{1'b0}}, data_data_i[7:0]};
						//if	(flag_mem_data_mux) 	wb_val_4 = {{24{1'b0}}, mem_data1_i[7:0]};
						//else						wb_val_4 = {{24{1'b0}}, per_data_i[7:0]};
					end
					`RV32I_FUNC3_LOAD_UHWORD: begin	
						wb_val_4 = {{16{1'b0}}, data_ldst_reg[15:0]};
						//wb_val_4 = {{16{1'b0}}, data_data_i[15:0]};
						//if	(flag_mem_data_mux) 	wb_val_4 = {{16{1'b0}}, mem_data1_i[15:0]};
						//else 						wb_val_4 = {{16{1'b0}}, per_data_i[15:0]};
					end
					default: 						wb_val_4 = 'b0;

				endcase
			end

			// else - store, branch, none
			default: begin
				wb_val_4 = 'b0;
				flag_wb_4 = 1'b0;
			end

		endcase
	end

	else begin
		wb_val_4 = 'b0;
		flag_wb_4 = 1'b0;
	end

	// exception logic

end

// ------------------------------------------------------------------------------------------------------------------------------
// Stage 3 - ALU Manipulation and load/store setup
// ------------------------------------------------------------------------------------------------------------------------------
// if flow control then do nothing
// if load store then form load/store target address
// if arith then route to alu
// ~8Mhz max to convert, divide, and convert

//wire 	flag_multiply;
wire 	flag_divide;
riscv_alu_pipelined #(
	.RV32M 				(1 						),
	.DIV_STAGES 		(3 						)
) rv32_alu_inst(
	.clock_div_i		(clock_i 				),
	.in0_i 				(Tsrc1_3_reg 			), 
	.in1_i 				(Tsrc2_3_reg 			), 
	.imm0_i 			(imm32_3_reg 			), 
	.addr_i 			(inst_addr_3_reg 		), 
	.out_o 				(alu_result_3 			), 
	.encoding_i 		(inst_encoding_3_reg 	), 
	.func3_i 			(func3_3_reg 			), 
	.func7_i 			(func7_3_reg			),
	.flag_mult_o 		(),
	.flag_div_o 		(flag_divide 			) 	// 1: if executing a divide operation
);

/*wire flag_load, flag_store;

memory_reference_controller ldst_contr(
	.encoding_i 		(inst_encoding_3_reg 	),
	.func3_i 			(func3_3_reg 			),
	.src1_operand_i		(Tsrc1_3_reg 			),
	.src2_operand_i		(Tsrc2_3_reg 			),
	.immediate_i 		(imm32_3_reg 			),
	.flag_load_o 		(flag_load 				), 	// 1: operation is load
	.flag_store_o 		(flag_store 			),  // 1: operation is store
	.addr_target_o 		(ldst_addr_3 			), 	// target address of load/store
	.data_target_o 		(ldst_data_3 			),	// data to write if store operation
	.exception_o 		(						) 	// [2] - unknown func3
													// [1] - target addr word misaligned
													// [0] - target addr hword misaligned
);*/

//always @(*) begin
//	mux_output_3 = 
//end

always @(*) begin

	// signal routing
	case(inst_encoding_3_reg)

		`ENCODING_JAL, `ENCODING_JALR: 												mux_output_3 = jump_addr_wb_3_reg;
		`ENCODING_LUI, `ENCODING_AUIPC, `ENCODING_ARITH_IMM, `ENCODING_ARITH_REG: 	mux_output_3 = alu_result_3;
		// load, store, none, branch
		default: 																	mux_output_3 = 'b0;

	endcase

end



// ------------------------------------------------------------------------------------------------------------------------------
// Stage 2 - Operand Fetch
// ------------------------------------------------------------------------------------------------------------------------------
// if load store then just check for dependencies and form src1 for target address in next stage (2 stage pipeline would request here)
// if arith then just check for dependencies and form src1 and src2 for ALU
// exceptions:
//		- jump target word/hword misalignment
// 		- next instruction word incorrect sequence
// 		- unknown func3

// vec the register file so it can be ported
wire 	[1023:0] 	register_file_vec_i;
genvar k;
generate 
	for (k = 0; k < 32; k = k + 1) begin: rf_pack
		assign register_file_vec_i[(32*k)+31:32*k] = RF[k];
	end
endgenerate


dependency_handler dependency_handler_inst(
	.encoding_i 				(inst_encoding_2_reg 	),
	.encoding_stage3_i 			(inst_encoding_3_reg 	),
	.encoding_stage4_i 			(inst_encoding_4_reg 	),
	.register_file_vec_i 		(register_file_vec_i 	), 	// register file regs vec'd to port
	.fsrc1_i 					(fsrc1_2_reg 			),
	.fsrc2_i 					(fsrc2_2_reg 			),
	.fdest_stage3_i 			(fdest_3_reg 			), 	// destination register of stage 3
	.fdest_stage4_i 			(fdest_4_reg 			), 	// destination register of stage 4
	.data_stage3_i 				(mux_output_3 			), 	// data bus from stage 3 output
	.data_stage4_i 				(wb_val_4 				), 	// data bus from stage 4 output
	.flag_dependency_o 			(flag_dependency_2 		), 	// 1: unresolved dependency that requires a pipeline stall
	.src1_operand_o 			(Tsrc1_2 				),
	.src2_operand_o 			(Tsrc2_2 				)
);


// jump/branch address generation
// -------------------------------------------------------
wire [3:0]	jump_exception;

target_address_generator jump_branch_cntrl_inst(

	.encoding_i 				(inst_encoding_2_reg 	),
	.instruction_addr_i			(inst_addr_2_reg 		),
	.instruction_next_addr_i	(inst_addr_1_reg 		),	// used to throw out of sequence exception
	.func3_i 					(func3_2_reg 			),
	.src1_operand_i 			(Tsrc1_2 				),
	.src2_operand_i 			(Tsrc2_2 				),
	.immediate_i 				(imm32_2_reg 			), 	// immediate value to modulate jump
	.flag_jump_o 				(flag_jump_2 			), 	// 1: jump/branch operation
	.addr_target_o 				(jump_addr_target_2 	), 	// target address of operation
	.addr_writeback_o 			(jump_addr_wb_2 		), 	// address/value to writeback to register file 	
	.exception_o 				(jump_exception 		) 	// [3] - unknown/unsupported func3 if branch operation
															// [2] - if jump/branch goes high if next instruction addr is not == target of operation
															// [1] - target address word misaligned
															// [0] - target address half-word misaligned
);

// load/store0 address generation
// -------------------------------------------------------
wire flag_load, flag_store;

memory_reference_controller ldst_contr(
	.encoding_i 		(inst_encoding_2_reg 	),
	.func3_i 			(func3_2_reg 			),
	.src1_operand_i		(Tsrc1_2 				),
	.src2_operand_i		(Tsrc2_2 				),
	.immediate_i 		(imm32_2_reg 			),
	.flag_load_o 		(flag_load 				), 	// 1: operation is load (encoding is load - flag to controller that a request is necessary)
	.flag_store_o 		(flag_store 			),  // 1: operation is store
	.addr_target_o 		(ldst_addr_2 			), 	// target address of load/store
	.data_target_o 		(ldst_data_2 			),	// data to write if store operation
	.exception_o 		(						) 	// [2] - unknown func3
													// [1] - target addr word misaligned
													// [0] - target addr hword misaligned
);

// ------------------------------------------------------------------------------------------------------------------------------
// Stage 1 - Instruction Decode
// ------------------------------------------------------------------------------------------------------------------------------
// exceptions: 
//		- unknown opcode: may be caused by mis-sequenced jump so do not take action until exception propogates past OP fetch

stage1_instruction_decode stage1_inst(
	.instruction_i 				(IR_1_reg 				), 	// instruction word to decode
	.encoding_o 				(inst_encoding_1 		), 	// one hot encoding of instruction type
	.func7_o 					(func7_1 				),
	.func3_o 					(func3_1 				),
	.fsrc2_o 					(fsrc2_1 				),
	.fsrc1_o 					(fsrc1_1 				),
	.fdest_o 					(fdest_1 				),
	.imm32_o 					(imm32_1 				), 	// generate immediate value during decode
	.exception_o 				( 						) 	// unknown opcode exception: 1'b1 if raised
);


// ------------------------------------------------------------------------------------------------------------------------------
// HART controller
// ------------------------------------------------------------------------------------------------------------------------------
reg 	[4:0]	pipeline_state_active, pipeline_state_saved;
reg 			flag_pipeline_dependency_stall, flag_pipeline_jump;
integer 		i;

always @(posedge clock_i) begin

	// reset state
	// -----------------------------------------------------------------------------------------------------------
	if (reset_i != 1'b1) begin

		// generic components
		pipeline_state_active = 5'b00000;
		pipeline_state_saved = 5'b00000;
		flag_pipeline_dependency_stall = 1'b0;
		flag_pipeline_jump = 1'b0;
		//flag_mem_data_mux = 1'b0;
		
		PC <= 4;
		for (i = 0; i < 32; i = i + 1) begin
			if (i != 2) 		RF[i] <= 'b0;
			//else if (i == 2)	RF[i] <= `SP_BASE;
			else if (i == 2) RF[i] <= 32'h0003F000;
		end

		// stage 1 components
		IR_1_reg <= 'b0;
		inst_addr_1_reg <= 'b0;

		// stage 2 components
		inst_encoding_2_reg <= `ENCODING_NONE; inst_addr_2_reg <= 'b0;
		func7_2_reg <= 'b0; func3_2_reg <= 'b0; fsrc2_2_reg <= 'b0; fsrc1_2_reg <= 'b0; 
		fdest_2_reg <= 'b0; imm32_2_reg <= 'b0;


		// stage 3 components
		inst_encoding_3_reg <= `ENCODING_NONE; inst_addr_3_reg <= 'b0;
		func7_3_reg <= 'b0; func3_3_reg <= 'b0; fdest_3_reg <= 'b0; imm32_3_reg <= 'b0;
		Tsrc1_3_reg <= 'b0; Tsrc2_3_reg <= 'b0; jump_addr_wb_3_reg <= 'b0;

		data_ldst_reg <= 'b0;

		// stage 4 components
		inst_encoding_4_reg <= `ENCODING_NONE;
		mux_output_4_reg <= 'b0; func3_4_reg <= 'b0; fdest_4_reg <= 'b0;

		// memory signals
		inst_req_reg 	<= 1'b1;
		inst_addr_reg 	<= 'b0;
		data_req_reg 	<= 1'b0;
		data_wren_reg 	<= 1'b0;
		data_addr_reg 	<= 'b0;
		data_data_reg 	<= 'b0;

	end

	// state machine sequencing
	// -----------------------------------------------------------------------------------------------------------
	else begin

		// -------------------------------------------------------------------------------------------------------
		// pipeline controller logic
		// -------------------------------------------------------------------------------------------------------

		// default signals - control signals to memory components
		inst_req_reg <= 1'b0;
		data_req_reg <= 1'b0;

		// if caches non-stalled
		if (inst_done_i & data_done_i) begin

			// default sequencing
			// -------------------
			pipeline_state_active = {pipeline_state_active[3:0],1'b1};

			// if returning from a stall then restore the pipeline state and overwrite the mem-encoding to "NONE"
			if (flag_pipeline_dependency_stall) begin
				flag_pipeline_dependency_stall = 1'b0;
				pipeline_state_active = pipeline_state_saved & 5'b01111;
			end
			// if jump stall has been serviced
			if (flag_pipeline_jump & !jump_exception[2]) begin
				flag_pipeline_jump = 1'b0;
			end

			// if there's a dependency save pipeline state stall for one cycle
			if (flag_dependency_2) begin
				flag_pipeline_dependency_stall = 1'b1; 							// flag to denote stall taken
				pipeline_state_saved = pipeline_state_active;					// save return state
				pipeline_state_active = `STATE_HART_PIPELINE_DEPENDENCY_STALL;
			end
			// jump taken hazard - first occurrence of it
			// enable a request for the correct instruction word
			else if (jump_exception[2] & !flag_pipeline_jump) begin
				PC = jump_addr_target_2;
				flag_pipeline_jump = 1'b1;
				pipeline_state_active = `STATE_HART_PIPELINE_JUMP;
			end


			// -------------------------------------------------------------------------------------------------------
			// next state logic
			// -------------------------------------------------------------------------------------------------------

			// stage 0 - instruction fetch
			// ---------------------------------------------
			if (pipeline_state_active[0]) begin
				inst_req_reg 		<= 1'b1;
				inst_addr_reg 		<= PC;
				PC 					= PC + 4; 	// increment for next instruction
			end

			// stage 1 - instruction decode
			// ---------------------------------------------
			if (pipeline_state_active[1]) begin
				IR_1_reg 			<= inst_data_i;
				inst_addr_1_reg 	<= inst_addr_o; 			// use old (previously requested) inst. ref add.
			end

			// stage 2 - operand fetch
			// ---------------------------------------------
			if (pipeline_state_active[2]) begin
				inst_addr_2_reg 	<= 	inst_addr_1_reg;
				inst_encoding_2_reg <= 	inst_encoding_1;
				func7_2_reg 		<= func7_1; 
				func3_2_reg 		<= 	func3_1;
				fsrc2_2_reg 		<= 	fsrc2_1; 
				fsrc1_2_reg 		<= 	fsrc1_1; 
				fdest_2_reg 		<= 	fdest_1; 
				imm32_2_reg 		<= 	imm32_1;
			end

			// stage 3 - alu manipulation
			// ---------------------------------------------
			if (pipeline_state_active[3]) begin
				inst_addr_3_reg 	<=  inst_addr_2_reg;
				inst_encoding_3_reg <= 	inst_encoding_2_reg;
				func7_3_reg 		<= 	func7_2_reg; 
				func3_3_reg 		<= 	func3_2_reg;
				fdest_3_reg 		<= 	fdest_2_reg; 
				Tsrc1_3_reg 		<=	Tsrc1_2;
				Tsrc2_3_reg 		<= 	Tsrc2_2;
				imm32_3_reg 		<= 	imm32_2_reg;
				jump_addr_wb_3_reg 	<= 	jump_addr_wb_2;


				// load/store request
				// -----------------------------------------------------------------------------
				// if the incoming signal is a load
				if (flag_load) begin
					data_req_reg 	<= 1'b1;
					data_wren_reg 	<= 1'b0;
					data_addr_reg 	<= ldst_addr_2;
				end
				// if the incoming signal is a store
				else if (flag_store) begin
					data_req_reg 	<= 1'b1;
					data_wren_reg 	<= 1'b1;
					data_addr_reg 	<= ldst_addr_2;
					data_data_reg 	<= ldst_data_2;
				end

			end
			else begin
				inst_encoding_3_reg <= `ENCODING_NONE;
			end

			// stage 4 - mem operation
			// ---------------------------------------------
			if (pipeline_state_active[4]) begin
				inst_encoding_4_reg <= 	inst_encoding_3_reg;
				mux_output_4_reg 	<= 	mux_output_3;
				func3_4_reg 		<= 	func3_3_reg;
				fdest_4_reg 		<= 	fdest_3_reg;
				data_ldst_reg 		<= 	data_data_i;
			
			end
			else begin
				inst_encoding_4_reg <= `ENCODING_NONE;
			end

			// stage 5 - writeback
			// ---------------------------------------------
			if (flag_wb_4) begin
				RF[fdest_4_reg] 	<= wb_val_4;
			end

		end // if mem_done0_i & mem_done1_i

	end
end


endmodule