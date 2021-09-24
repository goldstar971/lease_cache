# dependencies
import sys;				# for exiting
import getopt;			# for command line parse getopt.getopt
import os.path;
import terminal;
import math;
import statistics;
#import matplotlib.pyplot as plt

class lease_item:
	def __init__(self, field_str):

		# extract groups and check for correctness
		extract_group = field_str.split(","); 			# comma delimited
		if len(extract_group) != 5:
			print("Error - field extract mismatch: "+field_str);
			exit();

		# init class
		self.phase = 	extract_group[0];
		self.addr = 	extract_group[1]
		self.lease0 = 	extract_group[2];
		self.lease1 = 	extract_group[3];
		self.prob = 	extract_group[4];
		if float(self.prob) < 1.00:
			self.dual = True;
		else: 
			self.dual = False;

	def print_info(self):
		print(self.phase+","+self.addr+","+self.lease0+","+self.lease1+","+self.prob+","+str(self.dual));



def generate(options):
	# open file - read only privledge
	try:
		srcHandle = open(options.src_str,'r');
	except IOError:
		print("Error: File does not exist in current directory");
		exit(0);

	# go through file extracting all strings between keywords
	# -----------------------------------------------------------------------------------
	#keyword_begin = "Lease Dump";
	keyword_begin = "Dump formated leases";
	keyword_end = "";

	valid_flag = False;
	lease_item_list = [];
	
	for line in srcHandle:
		# check for termination
		if line.strip() == keyword_end:
			valid_flag = False;

		# import to list
		if valid_flag == True:
			line = line.replace(" ","").strip(); 		# remove all whitespaces and newline
			if (line != ""):
				new_lease_item = lease_item(line);
				lease_item_list.append(new_lease_item);
		
		# check for import
		if line.strip() == keyword_begin:
			valid_flag = True;
	# close file
	srcHandle.close();

	# parse, sort, group
	# -----------------------------------------------------------------------------------

	# first seperate items into sub-groups by their phase
	phase_list_arr = [];
	phase_list_arr_id = [];
	
	for item in lease_item_list:
		
		if item.phase in phase_list_arr_id:
			phase_list_arr[phase_list_arr_id.index(item.phase)].append(item);
		else:
			# create new list
			new_list = [];
			new_list.append(item);
			phase_list_arr.append(new_list);
			phase_list_arr_id.append(item.phase);


	# first sort sub-groups by id
	phase_list_arr = [x for _,x in sorted(zip(phase_list_arr_id,phase_list_arr))]

	# sort each sub-group by ref_addr, but place dual leases at top of list
	# negative is because its reverse order
	for phase in phase_list_arr:
		phase.sort(key=lambda x: (-x.dual, int(x.addr,16)), reverse=False)

	# error check lists
	# -----------------------------------------------------------------------------------

	#get the dual leases for each phase
	phase_dual_leases=[]
	for phase in phase_list_arr:
		for lease in phase:
			lease_value=int(lease.lease1,16)
			#if there is a dual lease
			if(lease_value>0):
				phase_dual_leases.append(lease)
	default_lease=1
	
	# make sure all the entries can fit in the table
	for phase in phase_list_arr:
	

		if len(phase) > options.size:
			print("Error: phase cannot fit in specified LLT size");
# then make sure all phases+config can fit in the memory
	config_bytes = 4*16;
	phase_bytes = 4*(4*options.size)*len(phase_list_arr)
	if (config_bytes + phase_bytes) > options.mem_size:
		print("Error: phases cannot fit in specified memory size");
		exit(0);

	# create source file from lists
	# -----------------------------------------------------------------------------------

	# open file
	try:
		destHandle = open(options.dest_str,'w');
	except IOError:
		print("Error: File does not exist in current directory");
		exit(0);

	# write header
	n_iterations = int(options.mem_size/4);
	destHandle.write("#include \"stdint.h\"\n\n");
	destHandle.write("static uint32_t lease["+str(n_iterations)+"] __attribute__ ((section (\".lease\"))) __attribute__ ((__used__)) = {\n");
	destHandle.write("// lease header\n");
	
	# write phase data
	# --------------------------------------------------------
	field_list = "reference address","lease0 value";
	for i, phase in enumerate(phase_list_arr):
		destHandle.write("// phase "+str(i)+"\n");
		# write configuration data
	# --------------------------------------------------------
		for j in range(0,16):
			if j == 0:
				destHandle.write("\t0x"+format_extend(str(hex(default_lease))[2:], 8)+",");
				destHandle.write("\t// default lease\n");
			elif j == 1:
				value_to_print=phase_dual_leases[i].lease1 if len(phase_dual_leases)>i else "0"
				destHandle.write("\t0x"+format_extend(value_to_print, 8)+",");
				destHandle.write("\t// long lease value\n");
			elif j==2:
				value_to_print=phase_dual_leases[i].prob if len(phase_dual_leases)>i else "1.00"
				destHandle.write("\t0x"+format_extend(discretize(value_to_print,options.bit_disc), 8)+",");
				destHandle.write("\t// short lease probability\n");
			elif j==3:
				destHandle.write("\t0x"+format_extend(hex(len(phase))[2:], 8)+",");
				destHandle.write("\t// num of references in phase\n");
			elif j==4:
				value_to_print=phase_dual_leases[i].addr if len(phase_dual_leases)>i else "0"
				#convert to word address
				value_to_print=hex(int(value_to_print,16)>>2).lstrip("0x")
				destHandle.write("\t0x"+format_extend(value_to_print, 8)+",");
				destHandle.write("\t//dual lease ref (word address)\n");
			else:
				destHandle.write("\t0x"+format_extend("0", 8)+",");
				destHandle.write("\t// unused\n");

		# loop through class fields
		for k in range(0,2):

			destHandle.write("\t//"+field_list[k]+"\n\t");

			# loop through table entries/phase entries
			for j in range(0,options.size):

				# print value
				if (j < len(phase)):
					if (k == 0):
						#destHandle.write("0x"+phase[j].addr);
						destHandle.write("0x"+format_extend(phase[j].addr, 8));
					elif (k == 1):
						#destHandle.write("0x"+phase[j].lease0);
						destHandle.write("0x"+format_extend(phase[j].lease0, 8));
				else:
					destHandle.write("0x"+format_extend("0", 8));
				# print delimiter
				if ((j+1) == options.size) & (k == 1) & ((i+1) == len(phase_list_arr)): 	# end of all phases
					destHandle.write("\n");
				elif (j+1) == options.size:														# end of section
 					destHandle.write(",\n");
				elif (((j+1) % 10) == 0):
					destHandle.write(",\n\t");
				else:
					destHandle.write(", ");

	# close file
	destHandle.write("};");
	destHandle.close();

	# print histograms if enabled
	#if (options.print):
		#x = [1,2,3,4,5];
		#y = [1,2,3,4,5];
		#plt.bar(y, x, align='center', alpha=0.5)
		#plt.bar(phase_list_arr[0].lease0, phase_list_arr[0].addr, align='center', alpha=0.5)
		#plt.xticks(y_pos, objects)
		#plt.ylabel('Usage')
		#plt.title('Programming language usage')
		#plt.show()


	# done with everything
	print("Done generating \"" + options.dest_str + "\"");


# discretize value function
# ----------------------------------------------------------------
def discretize(percentage, discretization):
# percentage 		- 	string of floating point number
# discretization 	- 	integer number (ex, 9 = 9-bit range)

	# conversion
	percentage = float(percentage);
	percentage_binary = hex(int(math.floor(percentage * (2**discretization-1)))); 	# as a hex string
	percentage_binary = percentage_binary.lstrip("0x").rstrip("L"); 				# remove leading and trailing

	# return 
	return percentage_binary;


# misc. formatting function
# ----------------------------------------------------------------
def format_extend(_str, total_chars):

	if isinstance(_str, str) == False: 
		_str = str(_str);

	return_str = _str;

	while(len(return_str) < total_chars):
		return_str = "0"+return_str;

	return return_str;
