#!/usr/bin/python
import sys
import math


if(len(sys.argv)!=2):
	f.write("you need to provide the number of match bits being encoded!")
	sys.exit()
log2_val=int(math.log2(float(sys.argv[1])))
or_level_1=2**(log2_val-4)-1
file_name="tag_match_encoder_"+str(log2_val)+"b"
with open(file_name+".v",'w') as f:
	f.write("module "+file_name+"(\ninput ["+str(int(sys.argv[1])-1)+":0] match_bits,\n\
	output reg ["+str(log2_val-1)+":0] match_index_reg,\n output reg actual_match);\n")
	if(or_level_1<1):
		f.write("wire or_o["+str(log2_val-1)+":0];\nwire ["+str(log2_val-1)+":0] match_index;\n")
	else:
		f.write("wire ["+str(or_level_1)+":0] or_o["+str(log2_val-1)+":0];\nwire ["+str(log2_val-1)+":0] match_index;\n")
	for i in range(0,log2_val):
		or_strs=""
		counter=8
		counter2=0
		for j in range(1,int(sys.argv[1])):
			if(counter==8): 
				or_strs=(or_strs+"\tassign or_o["+str(i)+"]["+str(counter2)+"]=|({")
				counter=0
				counter2=counter2+1;
			if(j%(2**(i+1))>=2**(i)):
				counter=counter+1
				if(counter==8):
					or_strs=(or_strs+"match_bits["+str(j)+"]});\n")
				else:
					or_strs=(or_strs+"match_bits["+str(j)+"],")
		f.write(or_strs)
		match_or_str="\tassign match_index["+str(i)+"]="+"|({"
		for z in range(0, counter2):
			match_or_str=match_or_str+"or_o["+str(i)+"]["+str(z)+"],"
		match_or_str=match_or_str[:-1]+"});\n"
		f.write(match_or_str)
	f.write("always@(match_index)begin\n\tmatch_index_reg=match_index;\n\tactual_match=|({match_index,match_bits[0]});\nend"\
		+"\n\nendmodule")
	
