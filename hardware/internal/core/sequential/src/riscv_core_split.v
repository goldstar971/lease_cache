`include "../../../../include/riscv.h"
`include "../../../../include/processor.h"
`include "../../../../include/peripheral.h"
`include "../../../../include/memory.h"
`include "../../../../include/exception.h"

module riscv_core_split(

	// general i/o
	input 				clock_i, reset_i,
	output 	reg [3:0]	exception_bus_o,
	output 		[31:0]	inst_addr_o,
	output 		[31:0] 	inst_word_o,

	// i/o to internal memory controller
	output 	reg 		mem_req0_o, mem_rw0_o,
	output 	reg [31:0]	mem_add0_o, mem_data0_o,
	input 		[31:0]	mem_data0_i, mem_done0_i,

	output 	reg 		mem_req1_o, mem_rw1_o,
	output 	reg [31:0]	mem_add1_o, mem_data1_o,
	input 		[31:0]	mem_data1_i, mem_done1_i,

	// i/o to peripheral controller
	output 	reg			per_req_o, per_rw_o,
	output 	reg [31:0]	per_add_o, per_data_o,
	input 		[31:0]	per_data_i

);	
 
// internal signals
// ---------------------------------------------------------------------------------
// non-memory signals
reg		[4:0]				MC;					// machine cycle
reg 	[`BW_WORD-1:0]		PC;					// program counter
reg 	[`BW_WORD-1:0]		IR;					// instruction register
reg 	[`BW_WORD-1:0]		RF		[0:31];		// register file of data path
reg 	[`BW_WORD-1:0]		Tsrc2;				// FU input - source 2 register
reg 	[`BW_WORD-1:0]		Tsrc1;				// FU input - source 1 register
reg  	[`BW_WORD-1:0]		Tdest;				// FU input - destination register
reg 	[`BW_WORD-1:0]		TALUH;				// FU output - high 32 bits
reg 	[`BW_WORD-1:0]		TALUL;				// FU output - low 32 bits
reg 	[`BW_WORD-1:0]		RAS 	[0:31];		// isolated return address stack
reg 	[4:0]				RAP; 				// return address pointer

// memory related signals
reg 	[`BW_WORD-1:0]		imm_off; 			// immediate offset value

// initialization signals
integer 					i;					// used for initializing registers


// misc. arithmetic hardware
// ---------------------------------------------------------------------------------
reg [`BW_WORD-1:0]			umult_inA, umult_inB; 	// inA is Tsrc1, inB is Tsrc2
wire [(2*`BW_WORD)-1:0] 	umult_result;
reg 						umult_flag;
umultiplier32b umult_inst(
	.dataa(umult_inA), .datab(umult_inB), .result(umult_result)
);

/*wire [`BW_WORD-1:0] udiv_result, udiv_remain;
udivider32b udiv_inst( 	// denom is src2 => inB
	.denom(umult_inB), .numer(umult_inA), .quotient(udiv_result), .remain(udiv_remain)
);*/



assign inst_addr_o = PC - 4; 	// becasuse of auto increment
assign inst_word_o = IR;

// processor controller
// ---------------------------------------------------------------------------------
always @(posedge clock_i) begin

	// reset condition
	// ----------------------------------------------------
	if (reset_i != 1'b1) begin
		// core states and registers
		PC = {(`BW_WORD){1'b0}};
		MC = `MC0;
		RAP = `RAS_BASE;
		IR = {(`BW_WORD){1'b0}};
		TALUL = {(`BW_WORD){1'b0}};
		TALUH = {(`BW_WORD){1'b0}};
		imm_off = {(`BW_WORD){1'b0}};
		Tsrc1 = {(`BW_WORD){1'b0}};
		Tsrc2 = {(`BW_WORD){1'b0}};
		Tdest = {(`BW_WORD){1'b0}};

		// M-extension defaults
		umult_inA = 'b0; umult_inB = 'b0; umult_flag = 1'b0;

		// default signals to internal memory controller
		mem_req0_o = 1'b1; mem_rw0_o = 1'b0; 
		mem_add0_o = 'b0; mem_data0_o = 'b0;

		mem_req1_o = 1'b0; mem_rw1_o = 1'b0; 
		mem_add1_o = 'b0; mem_data1_o = 'b0;

		// default signals to peripheral controller
		per_req_o = 1'b0; per_rw_o = 1'b0;
		per_add_o = 'b0; per_data_o = 'b0;

		// default misc io
		exception_bus_o = 4'h0;

		// set register file and return address stack to zero
		for (i = 0; i < 32; i = i + 1) begin
			RF[i] = {(`BW_WORD){1'b0}};
			RAS[i] = {(`BW_WORD){1'b0}};
		end
		
		RF[2] = `SP_BASE;
	end

	// state sequence
	// --------------------------------------------
	else begin

		// default signals
		per_req_o = 1'b0; per_rw_o = 1'b0;
		mem_req0_o = 1'b0; mem_rw0_o = 1'b0;
		mem_req1_o = 1'b0; mem_rw1_o = 1'b0;

		// only execute if memory has brought in word
		if ((mem_done0_i == 1'b1) & (mem_done1_i == 1'b1)) begin

			// operate based on machine cycle
			case (MC)
			
				// -----------------------------------------------------------------------------------------------------
				// instruction fetch
				// -----------------------------------------------------------------------------------------------------
				`MC0: begin
					IR = mem_data0_i;
					umult_flag = 1'b0;
					mem_req0_o = 1'b0;
					PC = PC + 4;	
					
					// transition to cycle 2 based on instruction type (opcode)
					case (IR[6:0]) 
						`OPCODE_R_32b, `OPCODE_32M: 					MC <= `MC1_R;
						`OPCODE_I_32b, `OPCODE_I_JALR, `OPCODE_I_LOAD: 	MC <= `MC1_I;
						`OPCODE_U_LUI, `OPCODE_U_AUIPC: 				MC <= `MC1_U;
						`OPCODE_J_JAL: 									MC <= `MC1_J;
						`OPCODE_SB_BRANCH: 								MC <= `MC1_SB;
						`OPCODE_S_STORE:								MC <= `MC1_S;
						default: begin										
							exception_bus_o <= (exception_bus_o | `CORE_UNKNOWN_OPCODE);
							MC <= `MC_EXCEPTION;
						end
					endcase
				end
				
				// -----------------------------------------------------------------------------------------------------
				// operand fetch 
				// -----------------------------------------------------------------------------------------------------
				`MC1_R: begin
					Tsrc2 = RF[IR[24:20]];													// load src reg2
					Tsrc1 = RF[IR[19:15]];													// load src reg1
					Tdest = {{27{1'b0}},IR[11:7]};											// load dest reg
					MC = `MC2_R;

					// multiplier/divider logic
					// ---------------------------------------
					if (IR[31:25] == 7'b0000001) begin

						// signed - signed multiplication
						if ((IR[14:12] == 3'b000) | (IR[14:12] == 3'b001)) begin
							if (Tsrc1[31] == 1'b1) begin	// if signed then convert to unsigned and throw flag
								umult_inA = ~Tsrc1 + 1'b1;
								umult_flag = ~umult_flag; 	
							end
							else umult_inA = Tsrc1;

							if (Tsrc2[31] == 1'b1) begin	// if signed then convert to unsigned and throw flag
								umult_inB = ~Tsrc2 + 1'b1;
								umult_flag = ~umult_flag; 	
							end
							else umult_inB = Tsrc2;
						end

						// signed - unsigned
						else if (IR[14:12] == 3'b010) begin
							if (Tsrc1[31] == 1'b1) begin	// if signed then convert to unsigned and throw flag
								umult_inA = ~Tsrc1 + 1'b1;
								umult_flag = ~umult_flag; 	
							end
							else umult_inA = Tsrc1;

							umult_inB = Tsrc2;
						end

						// unsigned - unsigned
						else if (IR[14:12] == 3'b011) begin
							umult_inA = Tsrc1;
							umult_inB = Tsrc2;
						end

						// divide - signed
						/*else if ((IR[14:12] == 3'b100) | (IR[14:12] == 3'b110)) begin
							if (Tsrc1[31] == 1'b1) begin	// if signed then convert to unsigned and throw flag
								umult_inA = ~Tsrc1 + 1'b1;
								umult_flag = ~umult_flag; 	
							end
							if (Tsrc2[31] == 1'b1) begin	// if signed then convert to unsigned and throw flag
								umult_inB = ~Tsrc2 + 1'b1;
								umult_flag = ~umult_flag; 	
							end
						end*/

						// divide - unsigned
						/*else if ((IR[14:12] == 3'b101) | (IR[14:12] == 3'b111)) begin
							umult_inA = Tsrc1;
							umult_inB = Tsrc2;
						end*/

						/*else begin
							exception_bus_o <= (exception_bus_o | `CORE_UNKNOWN_FUNC3);
							MC <= `MC_EXCEPTION;
						end*/

					end
				end

				`MC1_I: begin
					imm_off = {{20{IR[31]}},IR[31:20]};										// load imm
					Tsrc1 = RF[IR[19:15]];													// load src reg
					Tdest = {{27{1'b0}},IR[11:7]};														// load dest reg
					MC = `MC2_I;
					per_add_o = Tsrc1 + imm_off;
				end
				`MC1_U: begin
					imm_off = {IR[31:12],12'h000};												// load imm
					Tdest = {{27{1'b0}},IR[11:7]};															// load dest reg
					MC = `MC2_U;
				end
				`MC1_J: begin
					imm_off = {{12{IR[31]}}, IR[19:12], IR[20], IR[30:25], IR[24:21], 1'b0}; 	// jump offset
					Tdest = {{27{1'b0}},IR[11:7]};															// load dest reg
					MC = `MC2_J;
				end
				`MC1_SB: begin
					imm_off = {{20{IR[31]}},IR[7],IR[30:25],IR[11:8],1'b0};						// branch offset
					Tsrc1 = RF[IR[19:15]];													// src reg1
					Tsrc2 = RF[IR[24:20]];													// src reg2
					MC = `MC2_SB;
				end
				`MC1_S: begin
					imm_off = {{21{IR[31]}},IR[30:25],IR[11:7]};							// store offset
					Tsrc1 = RF[IR[19:15]];													// src reg1
					Tsrc2 = RF[IR[24:20]];													// src reg2 (value to be stored)
					MC = `MC2_S;
					per_add_o = Tsrc1 + imm_off;
				end

				// -----------------------------------------------------------------------------------------------------
				// manipulation
				// -----------------------------------------------------------------------------------------------------
				`MC2_R: begin

					// m extensions
					// --------------------------------------
					if (IR[31:25] == 7'b0000001) begin

						//{TALUH,TALUL} = umult_result;

						// lower 32b operations
						// --------------------
						if (IR[14:12] == 3'b000) begin
							if (umult_flag) {TALUH,TALUL} = ~umult_result + 1'b1;
							else 			{TALUH,TALUL} = umult_result;
						end

						// upper 32b operations
						// --------------------
						else if ((IR[14:12] == 3'b001) | (IR[14:12] == 3'b010) | (IR[14:12] == 3'b011)) begin
							if (umult_flag) {TALUL,TALUH} = ~umult_result + 1'b1;
							else 			{TALUL,TALUH} = umult_result;
						end

						// proceed to next cycle
						MC <= `MC3_R;

						// division - result
						// --------------------
						/*else if ((IR[14:12] == 3'b100) | (IR[14:12] == 3'b101)) begin
							if (umult_flag) TALUL = ~udiv_result + 1'b1;
							else 			TALUL = udiv_result;
						end*/

						// division - remainder 
						// --------------------
						/*else if ((IR[14:12] == 3'b110) | (IR[14:12] == 3'b111)) begin
							TALUL = udiv_remain;
							//if (umult_flag) TALUL = ~udiv_result + 1'b1;
							//else 			TALUL = udiv_result;
						end*/

						/*else begin
							exception_bus_o <= (exception_bus_o | `CORE_UNKNOWN_FUNC3);
							MC <= `MC_EXCEPTION;
						end*/

					end

					// i extensions
					// --------------------------------------
					else begin

						case (IR[14:12])

							// add - subtract
							`FUNC_R_ADD, `FUNC_R_SUB: begin
								if (IR[30] == 1'b0) begin
									{TALUH,TALUL} = Tsrc2 + Tsrc1;
								end
								else begin
									{TALUH,TALUL} = Tsrc1 - Tsrc2;
								end
								MC <= `MC3_R;
							end

							// set if less than
							`FUNC_R_SLT: begin
								if ($signed(Tsrc1) < $signed(Tsrc2)) 					
									TALUL <= 32'h00000001;
								else 							
									TALUL <= 32'h00000000;
								TALUH <= 32'h00000000;
								MC <= `MC3_R;
							end

							// set if less than (unsigned evaluation)
							`FUNC_R_SLTU: begin
								if ($unsigned(Tsrc1) < $unsigned(Tsrc2)) 	
									TALUL <= 32'h00000001;
								else 								
									TALUL <= 32'h00000000;
								TALUH <= 32'h00000000;
								MC <= `MC3_R;
							end

							// logical AND with immediate
							`FUNC_R_AND: begin
								if (IR[30] != 1'b1) begin
									TALUL = Tsrc1 & Tsrc2;
									TALUH = {(`BW_WORD){1'b0}};
								end
								MC <= `MC3_R;
							end

							// logical OR with immediate
							`FUNC_R_OR: begin
								TALUL = Tsrc1 | Tsrc2;
								TALUH = {(`BW_WORD){1'b0}};
								MC <= `MC3_R;
							end

							// logical XOR with immediate
							`FUNC_R_XOR: begin
								TALUL = Tsrc1 ^ Tsrc2;
								TALUH = {(`BW_WORD){1'b0}};
								MC <= `MC3_R;
							end

							// logical shift left
							`FUNC_R_SLL: begin
								{TALUH,TALUL} = Tsrc1 << Tsrc2[4:0];
								MC <= `MC3_R;
							end

							// logical and arith shift right
							`FUNC_R_SRL, `FUNC_R_SRA: begin
								// check if arithimtic shift
								if (IR[30] == 1'b1) begin
									{TALUH, TALUL} = Tsrc1 >>> Tsrc2[4:0];
								end
								else begin
									{TALUH, TALUL} = Tsrc1 >> Tsrc2[4:0];
								end
								MC <= `MC3_R;
							end

							// un-implmented functions
							default: begin
								exception_bus_o <= (exception_bus_o | `CORE_UNKNOWN_FUNC3);
								MC <= `MC_EXCEPTION;
							end

						endcase

					end
				end

				// immediate instruction execution
				`MC2_I: begin

					case(IR[6:0])

						`OPCODE_I_32b: begin

							// execute function based on func3 value
							case (IR[14:12])

								// add immediate
								`FUNC_I_ADDI: begin
									{TALUH,TALUL} = Tsrc1 + imm_off;
									MC <= `MC3_I;
								end
								
								// Set less than (unsigned numbers)
								`FUNC_I_SLTIU: begin
									if ($unsigned(Tsrc1) < $unsigned(imm_off)) 	
										TALUL <= 32'h00000001;
									else 								
										TALUL <= 32'h00000000;
									TALUH <= 32'h00000000;
									MC <= `MC3_I;
								end
								
								// set less than (signed numbers)
								`FUNC_I_SLTI: begin
									if ($signed(Tsrc1) < $signed(imm_off)) 	
										TALUL <= 32'h00000001;
									else 			
										TALUL <= 32'h00000000;
									TALUH <= 32'h00000000;
									MC <= `MC3_I;
								end

								// logical AND with immediate
								`FUNC_I_ANDI: begin
									TALUL = Tsrc1 & imm_off;
									TALUH = {(`BW_WORD){1'b0}};
									MC <= `MC3_I;
								end

								// logical OR with immediate
								`FUNC_I_ORI: begin
									TALUL = Tsrc1 | imm_off;
									TALUH = {(`BW_WORD){1'b0}};
									MC <= `MC3_I;
								end

								// logical XOR with immediate
								`FUNC_I_XORI: begin
									TALUL = Tsrc1 ^ imm_off;
									TALUH = {(`BW_WORD){1'b0}};
									MC <= `MC3_I;
								end

								// logical shift left
								`FUNC_I_SLLI: begin
									{TALUH,TALUL} = Tsrc1 << imm_off[4:0];
									MC <= `MC3_I;
								end

								// logical and arith shift right
								`FUNC_I_SRLI, `FUNC_I_SRAI: begin
									// check if arithimtic shift
									if (IR[30] == 1) begin
										{TALUH, TALUL} = Tsrc1 >>> imm_off[4:0];
									end
									else begin
										{TALUH, TALUL} = Tsrc1 >> imm_off[4:0];
									end
									MC <= `MC3_I;
								end

								// unknown func3
								default: exception_bus_o <= (exception_bus_o | `CORE_UNKNOWN_FUNC3);
							endcase
						end

						`OPCODE_I_JALR: begin
							// pop operation
							if(((Tdest != 5'b00001) & (Tdest != 5'b00101)) & ((IR[19:15] == 5'b00001) | (IR[19:15] == 5'b00101))) begin
								PC = RF[IR[19:15]] + imm_off; 	// jump to target address
								RF[IR[19:15]] = RAS[RAP+1]; 	// pop top of RAS into the r1/r5
								RAP = RAP + 1'b1;
								RF[Tdest] = PC; 				// store return address
							end

							// push operation
							else if(((Tdest == 5'b00001) | (Tdest == 5'b00101)) & ((IR[19:15] != 5'b00001) & (IR[19:15] != 5'b00101))) begin
								RAS[RAP] = RF[Tdest];					// store old return address at top of return address stack
								RAP = RAP - 1'b1;						// point to new top of stack
								RF[Tdest] = PC;
								PC = RF[IR[19:15]] + imm_off;
							end

							// conditional
							else if(((Tdest == 5'b00001) | (Tdest == 5'b00101)) & ((IR[19:15] == 5'b00001) | (IR[19:15] == 5'b00101))) begin
								// pop then push
								if (IR[19:15] != Tdest) begin
									RF[IR[19:15]] <= RAS[RAP+1]; 		// pop top of stack into r1/r5
									RAS[RAP+1] <= RF[Tdest]; 			// swap essentially with new return address
									RF[Tdest] = PC; 					// store new return address
									PC = Tsrc1 + imm_off;

								end
								// push
								else begin
									RAS[RAP] = RF[Tdest];					// store return address at top of return address stack
									RAP = RAP - 1'b1;						// point to new top of stack
									RF[Tdest] <= PC;
									PC = RF[IR[19:15]] + imm_off;
								end
							end

							// all other instructions
							else begin
								RF[Tdest] = PC;							// store address of instruction following jump
								PC = Tsrc1 + imm_off;					// create target address
							end

							// register independent
							PC = PC & 32'hFFFFFFFE;					// set LSb of result to zero per ISA
							MC = `MC3_I;
						end

						// loads - reads
						`OPCODE_I_LOAD: begin
							// if a peripheral address
							if (per_add_o >= `OUTPUT_PERIPHERAL_BASE) begin
								per_req_o = 1'b1;
								per_rw_o = 1'b0;
								MC = `MC3_I;
							end
							// memory operation
							else begin
								case(IR[14:12])
									`FUNC_I_LB, `FUNC_I_LBU: begin
										mem_req1_o = 1'b1;
										mem_rw1_o = 1'b0;
										mem_add1_o = Tsrc1 + imm_off;
										MC = `MC3_I;
									end
									`FUNC_I_LH, `FUNC_I_LHU: begin
										mem_req1_o = 1'b1;
										mem_rw1_o = 1'b0;
										mem_add1_o = Tsrc1 + imm_off;
										/*mem_data_req = 1'b1;
										mem_data_rw = `READ;
										mem_data_add = Tsrc1 + imm_off;
										mem_data_n = `HWORD_REQ;*/
										MC = `MC3_I;
									end
									`FUNC_I_LW: begin
										mem_req1_o = 1'b1;
										mem_rw1_o = 1'b0;
										mem_add1_o = Tsrc1 + imm_off;
										/*mem_data_req = 1'b1;
										mem_data_rw = `READ;
										mem_data_add = Tsrc1 + imm_off;
										mem_data_n = `WORD_REQ;*/
										MC = `MC3_I;
									end
									default: begin
										exception_bus_o <= (exception_bus_o | `CORE_UNKNOWN_FUNC3);
										MC <= `MC_EXCEPTION;
									end
								endcase
							end
						end

						// unimplemented functions
						default: begin
							exception_bus_o <= (exception_bus_o | `CORE_UNKNOWN_OPCODE);
							MC <= `MC_EXCEPTION;
						end

					endcase
				end

				`MC2_U: begin
					case(IR[6:0])
						// load upper immediate
						`OPCODE_U_LUI: begin
							TALUH = {(`BW_WORD){1'b0}};
							TALUL = imm_off;
							MC = `MC3_U;
						end
						// add upper immediate to PC
						`OPCODE_U_AUIPC: begin
							TALUH = {(`BW_WORD){1'b0}};
							TALUL = (PC-4) + imm_off;
							MC = `MC3_U;
						end
						default: begin
							exception_bus_o <= (exception_bus_o | `CORE_UNKNOWN_OPCODE);
							MC <= `MC_EXCEPTION;
						end
					endcase
					
				end

				`MC2_J: begin
					// push return address onto RAS if rd = 1,5
					if ((Tdest == 5'b00001) | (Tdest == 5'b00101)) begin
						RAS[RAP] = RF[Tdest];					// store old return address at top of return address stack
						RAP = RAP - 1'b1;						// point to new top of stack
						//RF[Tdest] = PC; 						// store new return address in ra
					end

					// form new address of next instruction				
					RF[Tdest] = PC;								// store address of inst. after jump in rd					
					PC = (PC-4) + imm_off;						// add jump address and offset to get new PC
					MC = `MC3_J;
				end

				`MC2_SB: begin
					case(IR[14:12]) 
						// branch if equal
						`FUNC_SB_BEQ: begin
							if (Tsrc1 == Tsrc2) 	PC = (PC - 4) + imm_off;
							MC = `MC3_SB;
						end
						// branch if not equal
						`FUNC_SB_BNE: begin
							if (Tsrc1 != Tsrc2) 	PC = (PC - 4) + imm_off;
							MC = `MC3_SB;
						end
						// branch if rs1 < rs2 ----> Tb < Tc
						`FUNC_SB_BLT: begin
							if ($signed(Tsrc1) < $signed(Tsrc2)) 	PC = (PC - 4) + imm_off;
							MC = `MC3_SB;
						end
						`FUNC_SB_BLTU: begin
							if ($unsigned(Tsrc1) < $unsigned(Tsrc2)) 	PC = (PC - 4) + imm_off;
							MC = `MC3_SB;
						end
						// branch if rs1 >= rs2 ----> Tb < Tc
						`FUNC_SB_BGE: begin
							if ($signed(Tsrc1) >= $signed(Tsrc2)) 	PC = (PC - 4) + imm_off;
							MC = `MC3_SB;
						end
						`FUNC_SB_BGEU: begin
							if ($unsigned(Tsrc1) >= $unsigned(Tsrc2)) PC = (PC - 4) + imm_off;
							MC = `MC3_SB;
						end
						default: begin
							exception_bus_o <= (exception_bus_o | `CORE_UNKNOWN_FUNC3);
							MC <= `MC_EXCEPTION;
						end
					endcase
				end

				`MC2_S: begin
					//if ((per_add_o >= `OUTPUT_PERIPHERAL_BASE) & (per_add_o < `INPUT_PERIPHERAL_BASE)) begin
					if (per_add_o >= `INPUT_PERIPHERAL_BASE) begin
						// set io bank to write
						per_req_o = 1'b1;
						per_rw_o = 1'b1;
						per_data_o = Tsrc2;
						MC = `MC3_S;
					end
					else begin
						case(IR[14:12])
							`FUNC_S_SB: begin
								mem_req1_o = 1'b1;
								mem_rw1_o = 1'b1;
								mem_add1_o = Tsrc1 + imm_off;
								mem_data1_o = Tsrc2;

								/*mem_data_req = 1'b1;
								mem_data_rw = `WRITE;
								mem_data_n = `BYTE_REQ;
								mem_data_add = Tsrc1 + imm_off;
								mem_data_dataIn = Tsrc2;*/
								MC = `MC3_S;
							end
							`FUNC_S_SH: begin
								mem_req1_o = 1'b1;
								mem_rw1_o = 1'b1;
								mem_add1_o = Tsrc1 + imm_off;
								mem_data1_o = Tsrc2;
								/*mem_data_req = 1'b1;
								mem_data_rw = `WRITE;
								mem_data_n = `HWORD_REQ;
								mem_data_add = Tsrc1 + imm_off;
								mem_data_dataIn = Tsrc2;*/
								MC = `MC3_S;
							end
							// store word
							`FUNC_S_SW: begin
								mem_req1_o = 1'b1;
								mem_rw1_o = 1'b1;
								mem_add1_o = Tsrc1 + imm_off;
								mem_data1_o = Tsrc2;
								/*mem_data_req = 1'b1;
								mem_data_rw = `WRITE;
								mem_data_n = `WORD_REQ;
								mem_data_add = Tsrc1 + imm_off;
								mem_data_dataIn = Tsrc2;*/
								MC = `MC3_S;
							end
							default: begin
								exception_bus_o <= (exception_bus_o | `CORE_UNKNOWN_FUNC3);
								MC <= `MC_EXCEPTION;
							end
						endcase
					end
				end

				// -----------------------------------------------------------------------------------------------------
				// operand store
				// -----------------------------------------------------------------------------------------------------
				`MC3_R: begin
					// RV32M
					RF[Tdest] <= TALUL;
					MC <= `MC0;	
					//mem_inst_req <= 1'b1;
					//mem_inst_add <= PC;	
					mem_req0_o = 1'b1;
					mem_add0_o = PC;
				end
				`MC3_I: begin
					// immediate operation - no memory manipulation
					// --------------------------------------------
					if (IR[6:0] == `OPCODE_I_32b) begin
						RF[Tdest] = TALUL;						// store the result in the destination register
						//mem_inst_req <= 1'b1;
						//mem_inst_add <= PC;	
						mem_req0_o = 1'b1;
						mem_add0_o = PC;
						MC = `MC0;
					end
					// memory load
					// -----------
					else if (IR[6:0] == `OPCODE_I_LOAD) begin

						// check if peripheral operation
						if (per_add_o >= `OUTPUT_PERIPHERAL_BASE) begin
							TALUL = per_data_i;
							RF[Tdest] = per_data_i;
						end

						// not a peripheral - switch depending on condition
						else begin
							case(IR[14:12])
								/*`FUNC_I_LB: TALUL = {{24{mem_data_dataOut[7]}},mem_data_dataOut[7:0]};
								`FUNC_I_LH: TALUL = {{16{mem_data_dataOut[15]}},mem_data_dataOut[15:0]};
								`FUNC_I_LW: TALUL = mem_data_dataOut;
								`FUNC_I_LBU: TALUL = {{24{1'b0}},mem_data_dataOut[7:0]};
								`FUNC_I_LHU: TALUL = {{16{1'b0}},mem_data_dataOut[15:0]};*/
								`FUNC_I_LB: TALUL = {{24{mem_data1_i[7]}},mem_data1_i[7:0]};
								`FUNC_I_LH: TALUL = {{16{mem_data1_i[15]}},mem_data1_i[15:0]};
								`FUNC_I_LW: TALUL = mem_data1_i;
								`FUNC_I_LBU: TALUL = {{24{1'b0}},mem_data1_i[7:0]};
								`FUNC_I_LHU: TALUL = {{16{1'b0}},mem_data1_i[15:0]};
							endcase
							RF[Tdest] = TALUL;
							//mem_data_req = 1'b0;
						end
						//mem_inst_req <= 1'b1;
						//mem_inst_add <= PC;	
						mem_req1_o = 1'b0;
						mem_req0_o = 1'b1;
						mem_add0_o = PC;
						MC = `MC0;
					end
					// jump and link register
					// ------------------------
					else begin
						//mem_inst_req <= 1'b1;
						//mem_inst_add <= PC;	
						mem_req0_o = 1'b1;
						mem_add0_o = PC;
						MC = `MC0;
					end
				end
				`MC3_U: begin
					RF[Tdest] = TALUL;
					//mem_inst_req <= 1'b1;
						//mem_inst_add <= PC;	
					mem_req0_o = 1'b1;
					mem_add0_o = PC;
					MC = `MC0;	
				end
				`MC3_J: begin
					//mem_inst_req <= 1'b1;
						//mem_inst_add <= PC;	
					mem_req0_o = 1'b1;
					mem_add0_o = PC;
					MC = `MC0;
				end
				`MC3_SB: begin
					//mem_inst_req <= 1'b1;
						//mem_inst_add <= PC;	
					mem_req0_o = 1'b1;
					mem_add0_o = PC;
					MC = `MC0;
				end
				`MC3_S: begin
					// incase io operation
					per_rw_o = 1'b0;
					/*mem_data_rw <= `READ;
					mem_data_req <= 1'b0;
					mem_inst_req <= 1'b1;
					mem_inst_add <= PC;*/
					mem_req1_o = 1'b0;
					mem_rw1_o = 1'b0;

					mem_req0_o = 1'b1;
					mem_add0_o = PC;
					MC = `MC0;
				end
				`MC_EXCEPTION: begin
					exception_bus_o <= (exception_bus_o | `CORE_UNKNOWN_OPCODE);
					MC <= `MC_EXCEPTION;
				end	
			endcase
		end // memory done conditional termination
	end

	// overwrite any signal to x0 - x0 is tied lo ground
	RF[0] = 0;

end

endmodule