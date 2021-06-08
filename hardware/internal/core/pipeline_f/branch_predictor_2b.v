`include "../../../include/btb.h"
module branch_predictor_2b(
	input clock_i,
	input reset,
	input [`BW_WORD_ADDR-1:0] PC_i,
	input [31:0] instruction_stage1,
	input [`BW_WORD_ADDR-1:0] stage_1_instruct_addr,
	input [`BW_WORD_ADDR-1:0] stage_2_instruct_addr,
	input mispredict,
	output [`BW_BTYE_ADDR-1:0] PC_o);

wire [`BW_WORD_ADDR-1:0] prediction;
wire match;
wire [branch_table_mem_width-1:0] match_index,LRU_index;
wire [`BRANCH_TABLE_BUFFER_SIZE-1:0] match_bits;
integer i,k;

wire [branch_table_mem_width-1:0] all_full;
assign all_full=(entries_used==4'b1111) ? 1'b1 :1'b0;

genvar j;
generate 
	for (j = 0; j < 16; j = j + 1'b1) begin : branch_address_array
		identity_comparator #(.BW(`BW_WORD_ADDR)) comp_inst(PC_i, branch_pcs[j], match_bits[j]);
	end
endgenerate

tag_match_encoder_4b btb_match(.match_bits(match_bits&valid_bits),.match_index_reg(match_index),.actual_match(match));
//only used if btb has been filled, will always be valid and a match.
tag_match_encoder_4b lru_match(.match_bits(LRU_stack_bits),.match_index_reg(LRU_index),.actual_match());


//assume not taken for new branch
// (we can't actually calculate the address of a new branch because of dependencies so we can't assume taken)
wire [6:0] opcode_stage1;
assign destination_stage1=(opcode_stage1==`RV32I_OPCODE_BRANCH)? stage_1_instruct_addr+{instruction_stage1[31],instruction_stage1[7],instruction_stage1[30:25],instruction_stage1[11:9]} :
{instruction_stage1[31], instruction_stage1[19:12], instruction_stage1[20], instruction_stage1[30:22]}+stage_1_instruct_addr;
assign opcode_stage1=instruction_stage1[6:0];
assign prediction=(match && branch_predictors[match_index]>1) ?  branch_destinations[match_index] : PC_i+24'h1;
assign PC_o=(match) ? {prediction,2'b0} : {PC_i+24'h1,2'b00};
localparam branch_table_mem_width=`CLOG2(`BRANCH_TABLE_BUFFER_SIZE);

    //branch table prediction buffer memories
reg   [1:0]	branch_predictors[`BRANCH_TABLE_BUFFER_SIZE-1:0];
reg	 [`BW_WORD_ADDR-1:0] branch_pcs  [`BRANCH_TABLE_BUFFER_SIZE-1:0];
reg	 [`BW_WORD_ADDR-1:0] branch_destinations[`BRANCH_TABLE_BUFFER_SIZE-1:0];
reg	[branch_table_mem_width-1:0] branch_uses  [`BRANCH_TABLE_BUFFER_SIZE-1:0];
reg [branch_table_mem_width-1:0] last_match_index;
reg [`BRANCH_TABLE_BUFFER_SIZE-1:0]LRU_stack_bits, valid_bits;
reg [branch_table_mem_width-1:0] entries_used;
reg update_table,was_match;

reg[`BW_WORD_ADDR-1:0] branch_dest_from_stage_1;
wire [`BW_WORD_ADDR-1:0] destination_stage1;
reg[`BW_WORD_ADDR-1:0] last_update_pc;

//update recently used as posedge
always@(posedge clock_i)begin
	if(!reset)begin
		for(k=0;k<`BRANCH_TABLE_BUFFER_SIZE;k=k+1)begin
			branch_predictors[k]<='b0;
			branch_pcs[k]<='b0;
			branch_destinations[k]<='b0;
			branch_uses[k]<='b0;
			valid_bits[k]<='b0;
			LRU_stack_bits[k]<='b0;
		end
		entries_used<='b0;
	end
	else begin
//update recently used
		if(update_table)begin
			for(i=0;i<`BRANCH_TABLE_BUFFER_SIZE;i=i+1)begin
				//hit	
				if(was_match)begin
					if((i==last_match_index))begin
						branch_uses[i]<=4'b0;
					end
					else if(branch_uses[i]<branch_uses[last_match_index]&&i<entries_used)begin
						branch_uses[i]<=branch_uses[i]+4'b1;
					end
				end
				//miss
				else if(all_full)begin
					if(branch_uses[i]==`BRANCH_TABLE_BUFFER_SIZE-'b1)begin
						branch_uses[i]<=4'b0;
						LRU_stack_bits[i]<=1'b1;
					end
					else begin 
						branch_uses[i]<=branch_uses[i]+4'b1;
						LRU_stack_bits[i]<=1'b0;
					end
				end
				//just increment previous entries if not full
				else if(i<entries_used)begin
					branch_uses[i]<=branch_uses[i]+4'b1;
				end
			end
			//if match¸ update branch table buffer
			last_update_pc<=stage_1_instruct_addr;
			if(was_match)begin	
				//update predictor
				//if predict taken
				if(branch_predictors[last_match_index]>=2'b1)begin
					if(mispredict)begin
						branch_predictors[last_match_index]<=branch_predictors[last_match_index]-2'b1;
					end
					else begin
						branch_predictors[last_match_index]<=2'b11;
					end
				end
				else begin
					if(mispredict)begin
						branch_predictors[last_match_index]<=branch_predictors[last_match_index]+2'b1;
					end
					else begin
						branch_predictors[last_match_index]<=2'b0;
					end
				end
			end
			//if not match
			else begin
				//if unused space in buffer
				if(!all_full)begin
					if(mispredict)begin
						branch_predictors[entries_used]<=2'b10; 
					end
					branch_destinations[entries_used]<=branch_dest_from_stage_1;
					branch_pcs[entries_used]<=stage_1_instruct_addr;
					entries_used<=entries_used+1'b1;
					valid_bits[entries_used]<=1'b1;
				end
				else begin
					//predicting not taken by default, therefore if prediction is correct predictor will have value 0
					if(mispredict)begin
						branch_predictors[LRU_index]<=2'b10; 
					end
					branch_destinations[LRU_index]<=branch_dest_from_stage_1;
					branch_pcs[LRU_index]<=stage_1_instruct_addr;
				end
			end
		end
	end
end

//update branch prediction table
always@(negedge clock_i )begin
	if(!reset) begin
		last_match_index<='b0;
		was_match<=1'b0;
		update_table<=1'b0;
		branch_dest_from_stage_1<='b0;
	end
	else begin
		//store index of prediction to avoid additional circuitry
		//decide whether to update the table
		update_table<=1'b0;
		if(opcode_stage1==`RV32I_OPCODE_BRANCH||opcode_stage1==`RV32I_OPCODE_JAL) begin
			branch_dest_from_stage_1<=destination_stage1;
			
			if(match)begin
				last_match_index<=match_index;
				was_match<=1'b1;
			end
			if(stage_1_instruct_addr!=last_update_pc)begin
				update_table<=1'b1;
			end
		end
	end
end


endmodule