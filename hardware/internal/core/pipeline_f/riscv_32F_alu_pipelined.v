`include "../../../../include/float.h"
module riscv_32F_alu_pipelined(
		input  clock_float_i,
		input [31:0] in0_i,
		input [31:0] in1_i,
		input [31:0] in2_i,
		input [15:0] encoding_i,
		input [4:0]  fsrc2_i,
		input [2:0]  rm_i,
		input [4:0] func5_i,
		output reg [31:0] out_o,
		output [3:0] stall_cycles
);

wire [31:0] div_o, mul_o, add_in_1, add_in_2, add_sub_o,
ITF_unsigned_o, ITF_signed_o, FTI_signed_o,FTI_unsigned_o,
sqrt_o, fsgnj_o, fmax_o, fmin_o, compare_o,class_o; 
wire  add_sub_sel, eq_o, le_o, lt_o;



compare_eq  float_compare_eq(
	.areset(1'b0),
	.clk(clock_float_i),
	.a(in0_i),
	.b(in1_i),
	.q(eq_o)
);

compare_lt float_compare_lt(
	.areset(1'b0),
	.clk(clock_float_i),
	.a(in0_i),
	.b(in1_i),
	.q(lt_o)
);


and (le_o,lt_o,eq_o);


float_div float_divider(
	.areset(1'b0),
	.clk (clock_float_i),
	.a(in0_i),
	.b(in1_i),
	.q(div_o)
);

float_mul float_multiplier(
	.areset(1'b0),
	.clk (clock_float_i),
	.a(in0_i),
	.b(in1_i),
	.q(mul_o)
);

float_add_sub float_adder_sub(
	.areset(1'b0),
	.clk(clock_float_i),
	.a(add_in_1),
	.b(add_in_2),
	.q(add_sub_o),
	.opSel(add_sub_sel)
);
float_sqrt float_radical2(
	.areset(1'b0),
	.clk (clock_float_i),
	.a(in0_i),
	.q(sqrt_o)
);
FTI_signed fcvt_fti(
	.areset(1'b0),
	.clk (clock_float_i),
	.a(in0_i),
	.q(FTI_signed_o)
);
FTI_unsigned fcvt_ftiu(
	.areset(1'b0),
	.clk (clock_float_i),
	.a(in0_i),
	.q(FTI_unsigned_o)
);
ITF_signed fcvt_itf(
	.areset(1'b0),
	.clk (clock_float_i),
	.a(in0_i),
	.q(ITF_signed_o)
);
ITF_unsigned fcvt_itfu(
	.areset(1'b0),
	.clk (clock_float_i),
	.a(in0_i),
	.q(ITF_unsigned_o)
);

//handling for classify instruction
/*src1 is:
	1 negative infinity
  2 negative subnormal
  4 negative normal
  8 negative zero
  16 positive zero
  32 positive subnormal
  64 positive normal
  128 positive infinity
  256 signaling NAN
  512 quiet NAN
*/
//going to assume this is one clock cycle worth of latency
	assign class_o = (in0_i[31]==1'b1 && in0_i[30:23]==8'hff && in0_i[22:0]==23'b00000000000000000000000) ? 32'h00000001 :
	(in0_i[31]==1'b0 && in0_i[30:23]==32'hff && in0_i[22:0]==23'b00000000000000000000000) ? 32'h00000080 :
	(in0_i[30:23]==32'hff && in0_i[22:0]==23'b10000000000000000000000) ? 32'h00000200:
	(in0_i[30:23]==8'hff) ? 32'h00000100 :
	(in0_i[31]==1'b1 && in0_i[30:23]==8'h00 && in0_i[22:0]==23'b00000000000000000000000) ?32'h00000008 :
	(in0_i[31]==1'b0 && in0_i[30:23]==8'h00 && in0_i[22:0]==23'b00000000000000000000000) ?32'h00000010 :
	(in0_i[31]==1'b1 && in0_i[30:23]==8'h00) ? 32'h00000004  :
	(in0_i[31]==1'b0 && in0_i[30:23]==8'h00) ? 32'h00000020 :
	(in0_i[31]==1'b1) ? 32'h00000002 : 32'h00000040;
	
	assign add_sub_sel = (encoding_i==`ENCODING_FNMADD) ? 1'b1 : (encoding_i==`ENCODING_FMADD)
? 1'b1 : ((encoding_i == `ENCODING_FARITH) && (func5_i==`RV32F_FUNC5_ADD)) ? 1'b1 : 1'b0;
//for FMADD and FMSUB select output of multipler for first input to adder/subtractor
//for FNMADD and FNMSUB operations select opposite sign output of multiplier as first input to adder/subtractor
assign add_in_1 = (encoding_i==`ENCODING_FMADD) ? mul_o : (encoding_i==`ENCODING_FMSUB) ? mul_o :
(encoding_i==`ENCODING_FNMADD) ? {(1'b1 ^ mul_o[31]),mul_o[30:0]} : 
(encoding_i==`ENCODING_FNMSUB) ? {(1'b1 ^ mul_o[31]),mul_o[30:0]} : in0_i;

assign add_in_2=(encoding_i==`ENCODING_FMADD) ? in2_i : (encoding_i==`ENCODING_FMSUB) ? in2_i :
(encoding_i==`ENCODING_FNMADD) ? in2_i : 
(encoding_i==`ENCODING_FNMSUB) ? in2_i : in1_i;

//if src1<src2 assign src2 to fmax otherwise src1
assign fmax_o = (le_o==1'b1) ? in1_i : in0_i; 
//vice versa for fmin
assign fmin_o = (le_o==1'b1) ? in0_i : in1_i;
//if no float operations need to be preformed, no need to stall

wire [3:0] stall_cycles_1, stall_cycles_2, stall_cycles_3, stall_cycles_4, stall_cycles_5, stall_cycles_6,
stall_cycles_7,stall_cycles_8;

//if we aren't a float operation than the result doesn't matter so just assume its a float operation
//attempt at a balanced structural path

assign stall_cycles_2=(func5_i==`RV32F_FUNC5_SQRT) ? `FSQRT_LATENCY : (func5_i==`RV32F_FUNC5_DIV) ?  `FDIV_LATENCY : 'b0;
assign stall_cycles_1=(encoding_i[14:11]) ?`FMA_LATENCY : (func5_i<5'b00010) ? `FADD_SUB_LATENCY : 4'b0;
assign stall_cycles_3=(func5_i==`RV32F_FUNC5_MUL) ? `FMUL_LATENCY : (func5_i==`RV32F_FUNC5_CLASS) ? `CLASS_LATENCY :4'b0;
assign stall_cycles_4=(func5_i==`RV32F_FUNC5_FCVT_FTI) ? `FLOAT_TO_INT_LATENCY : (func5_i==`RV32F_FUNC5_FCVT_ITF) ? `INT_TO_FLOAT_LATENCY :4'b0;
assign stall_cycles_5=(func5_i==`RV32F_FUNC5_CMP) ? `COMPARE_LATENCY : (func5_i==`RV32F_FUNC5_FMIN_MAX) ? `COMPARE_LATENCY : 4'b0;
assign stall_cycles_6=(stall_cycles_5) ? stall_cycles_5 : stall_cycles_4;
assign stall_cycles_7=(stall_cycles_3) ? stall_cycles_3 : stall_cycles_2;
assign stall_cycles_8=(stall_cycles_1) ? stall_cycles_1 : stall_cycles_6;
assign stall_cycles=(stall_cycles_7) ? stall_cycles_7 : stall_cycles_8;


		
		//assign output based on instruction
always @(*) begin
   out_o='b0;//default output
	case(encoding_i)
		`ENCODING_FNMSUB, `ENCODING_FNMADD, `ENCODING_FMSUB, `ENCODING_FMADD: out_o =add_sub_o;
		`ENCODING_FARITH: begin
			case(func5_i)
				`RV32F_FUNC5_SGNJ: begin
					case(rm_i)
						`RV32F_FUNC5_RM_SGNJ: out_o={in1_i[31],in0_i[30:0]};
						`RV32F_FUNC5_RM_SGNJN: out_o={(in1_i[31]^ 1'b1),in0_i[30:0]};
						`RV32F_FUNC5_RM_SGNJX: out_o ={(in1_i[31]^in0_i[31]), in0_i[30:0]};
						default:;
					endcase
				end
				`RV32F_FUNC5_DIV: out_o=div_o;
				`RV32F_FUNC5_MUL: out_o=mul_o;
				`RV32F_FUNC5_ADD, `RV32F_FUNC5_SUB: out_o=add_sub_o;
				`RV32F_FUNC5_SQRT: out_o=sqrt_o;
				`RV32F_FUNC5_CMP: begin
					case(rm_i)
						`RV32F_FUNC5_RM_EQ: out_o={{30{1'b0}},eq_o};
						`RV32F_FUNC5_RM_LT: out_o={{30{1'b0}},lt_o};
						`RV32F_FUNC5_RM_LE: out_o={{30{1'b0}},le_o};
						default:;
					endcase
				end
				`RV32F_FUNC5_FMIN_MAX: begin
					case(rm_i)
						`RV32F_FUNC5_RM_MIN: out_o=fmin_o;
						`RV32F_FUNC5_RM_MAX: out_o=fmax_o;
						default:;
					endcase
				end
				`RV32F_FUNC5_CLASS: begin
					case(rm_i)
						`RV32F_FUNC5_RM_MV_XW: out_o =in0_i;
						`RV32F_FUNC5_RM_CLASS: out_o =class_o;
						default:;
					endcase
				end
				`RV32F_FUNC5_MV_WX: out_o=in0_i;
				`RV32F_FUNC5_FCVT_FTI: begin
					case(fsrc2_i)
						`RV32F_FUNC5_RS2_USGN: out_o =FTI_unsigned_o;
						`RV32F_FUNC5_RS2_SGN: out_o =FTI_signed_o;
						default:;
					endcase
				end
				`RV32F_FUNC5_FCVT_ITF: begin
					case(fsrc2_i)
						`RV32F_FUNC5_RS2_USGN: out_o = ITF_unsigned_o;
						`RV32F_FUNC5_RS2_SGN: out_o = ITF_signed_o;
						default:;
					endcase
				end
				default:;
			endcase
		end
		default:;
	endcase
end

endmodule