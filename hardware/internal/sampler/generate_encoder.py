#!/usr/bin/python

for i in range(0,6):
	or_strs=""
	counter=8
	counter2=0
	for j in range(1,64):
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

	print(or_strs,end="")
	match_or_str="\tassign match_index["+str(i)+"]="+"|({or_o["+str(i)+"][0],or_o["+str(i)+"][1]"+",or_o["+str(i)+"][2]"+",or_o["+str(i)+"][3]});"
	print(match_or_str)