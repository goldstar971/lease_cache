`include "../../../include/btb.h"
module branch_predictor_2b(
	input [1:0] clock_bus_i,
	input resetn_i,
	input [`BW_WORD_ADDR-1:0] PC_i,
	input [`BW_WORD_ADDR-1:0] jump_destination_i,
	input [`BW_WORD_ADDR-1:0] stage_1_instruct_addr_i,
	input [`BW_WORD_ADDR-1:0] stage_3_instruct_addr_i,
	input [15:0] stage_3_encoding_i,
	input mispredict_i,
	output [`BW_BYTE_ADDR-1:0] PC_o);

wire [`BW_WORD_ADDR-1:0] prediction;
wire match;
wire [branch_table_mem_width-1:0] match_index,LRU_index;
wire [`BRANCH_TABLE_BUFFER_SIZE-1:0] match_bits;
integer i,k;

wire all_full;
assign all_full=entries_used[branch_table_mem_width];

genvar j;
generate 
	for (j = 0; j < `BRANCH_TABLE_BUFFER_SIZE; j = j + 1'b1) begin : branch_address_array
		identity_comparator #(.BW(`BW_WORD_ADDR)) comp_inst(PC_i, branch_pcs[j], match_bits[j]);
	end
endgenerate

tag_match_encoder_6b btb_match(.match_bits(match_bits&valid_bits),.match_index_reg(match_index),.actual_match(match));
//only used if btb has been filled, will always be valid and a match.
tag_match_encoder_6b lru_match(.match_bits(LRU_stack_bits),.match_index_reg(LRU_index),.actual_match());


//assume not taken for new branch
// (we can't actually calculate the address of a new branch because of dependencies so we can't assume taken)
assign prediction=(match && branch_predictors[match_index]>1) ?  branch_destinations[match_index] : PC_i+24'h1;
assign PC_o=(match) ? {prediction,2'b0} : {PC_i+24'h1,2'b00};
localparam branch_table_mem_width=`CLOG2(`BRANCH_TABLE_BUFFER_SIZE);

    //branch table prediction buffer memories
reg   [1:0]	branch_predictors[`BRANCH_TABLE_BUFFER_SIZE-1:0];
reg	 [`BW_WORD_ADDR-1:0] branch_pcs  [`BRANCH_TABLE_BUFFER_SIZE-1:0];
reg	 [`BW_WORD_ADDR-1:0] branch_destinations[`BRANCH_TABLE_BUFFER_SIZE-1:0];
reg	[branch_table_mem_width-1:0] branch_uses  [`BRANCH_TABLE_BUFFER_SIZE-1:0];
reg [branch_table_mem_width-1:0] last_match_index,match_index1,match_index2, match_index3;
reg [`BRANCH_TABLE_BUFFER_SIZE-1:0]LRU_stack_bits, valid_bits;
reg [branch_table_mem_width:0] entries_used; //when all spaces used MSB will be 1.
reg update_table,was_match,match1,match2, match3;


reg[`BW_WORD_ADDR-1:0] last_pc,last_update_pc;

//trigger at 270 degrees
always@(posedge clock_bus_i[1])begin
	if(!resetn_i)begin
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
					if(&(branch_uses[i]))begin
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
			
			if(was_match)begin	
				//update predictor
				//if predict taken
				if(branch_predictors[last_match_index]>2'b1)begin
					if(mispredict_i)begin
						branch_predictors[last_match_index]<=branch_predictors[last_match_index]-2'b1;
					end
					else begin
						branch_predictors[last_match_index]<=2'b11;
					end
				end
				else begin
					if(mispredict_i)begin
						branch_predictors[last_match_index]<=branch_predictors[last_match_index]+2'b1;
					end
					else begin
						branch_predictors[last_match_index]<=2'b0;
					end
				end
			end
			//if not match
			else begin
				if(all_full)begin
					//predicting not taken by default, therefore if prediction is correct predictor will have value 0
					if(mispredict_i)begin
						branch_predictors[LRU_index]<=2'b10; 
					end
					branch_destinations[LRU_index]<=jump_destination_i;
					branch_pcs[LRU_index]<=stage_3_instruct_addr_i;
				end
					//if unused space in buffer
				else begin
					if(mispredict_i)begin
						branch_predictors[entries_used]<=2'b10; 
					end
					branch_destinations[entries_used]<=jump_destination_i;
					branch_pcs[entries_used]<=stage_3_instruct_addr_i;
					entries_used<=entries_used+1'b1;
					valid_bits[entries_used]<=1'b1;
				end
			end
		end
	end
end

//trigger at 90 degrees
always@(posedge clock_bus_i[0] )begin
	if(!resetn_i) begin
		last_match_index<='b0;
		was_match<=1'b0;
		update_table<=1'b0;
		match1<=1'b0;
		match_index1<='b0;
		last_pc<='b0;
		match3<=1'b0;
		match2<=1'b0;
		match_index2<='b0;
		match_index3<='b0;
		last_update_pc<='b0;

	end
	else begin
	//update table
		

		last_pc<=PC_i;
		last_update_pc<=stage_3_instruct_addr_i;
		//only update table once.
		if((stage_3_encoding_i==`ENCODING_JAL||stage_3_encoding_i==`ENCODING_BRANCH)&&(stage_3_instruct_addr_i!=last_update_pc))begin
				
				update_table<=1'b1;
			end 
			else begin
				update_table<=1'b0;
			end
	//if not stalled, 
		if(PC_i!=last_pc)begin

			match1<=match;
			match_index1<=match_index;
			match2<=match1;
			match_index2<=match_index1;
			match3<=match2;
			match_index3<=match_index2;
			was_match<=match3;
			last_match_index<=match_index3;
			
			
		end
	end
end


endmodule