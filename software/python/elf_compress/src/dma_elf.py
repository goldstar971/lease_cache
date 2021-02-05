import re;
import sys;
import array;
import os;

def get_sections(options):

	# script algo parameters
	str1 = "Program Headers:";
	str2 = "Section to Segment mapping:";

	# open file - read only privledge
	try:
		fileInputHandle = open(options.info_str,'r');
	except IOError:
		print("Error: \'" + options.info_str + "does not exist");
		exit(0);

	# default returns
	add_arr 	= []; 
	size_arr 	= [];

	# loop through lines searching for delimiters
	# store all entries between delimiters in text array
	enable 		= False;

	for lines in fileInputHandle:
		if (enable):
			# do not import empty lines or delimiters
			if ((lines.strip() != None) & (lines.strip() != str1) & (lines.strip() != str2)):
			 	if (lines != "\n"):

			 		tt = re.sub('\s+', ',', lines).strip();
					temp = tt.split(',');
					add_arr.append(temp[3]);
					size_arr.append(temp[5]);

		if (re.search(str1, lines) != None):
			enable = True;
		elif (re.search(str2, lines) != None):
			enable = False;

	# remove header line
	add_arr.pop(0);
	size_arr.pop(0);

	# write section information to file
	try:
		fileOutputHandle = open(options.section_str,'w');
	except IOError:
		print("Error: could not open \'" + options.section_str + " \n");
		exit(0);

	for index, value in enumerate(add_arr):
		temp_str = add_arr[index] + "," + size_arr[index] + "\n";
		fileOutputHandle.write(temp_str);

	# feedback
	if options.printopt:
		print("Successfully extracted program section information");

	# close file
	fileInputHandle.close();
	fileOutputHandle.close();

	return [add_arr, size_arr];



def get_data(options, addr_list, size_list):

	# open file - write privledge
	try:
		fileOutputHandle = open(options.data_str,'w');
	except IOError:
		print("Error: could not open \'" + options.data_str + "\'");
		exit(0);

	# extract binary data into array
	numbers = array.array("I");
	with open(options.src_str+".txt", 'rb') as f:
		numbers.fromfile(f, os.stat(options.src_str+".txt").st_size // numbers.itemsize);

	compressed_list = [];
	bound_index 	= 0;
	bound_low 		= int(addr_list[bound_index],16); 					# extract everything from here
	bound_high 		= bound_low + int(size_list[bound_index],16); 		# to here, for every section (including this section)

	for index, value in enumerate(numbers):

		if (4*index == bound_high):
			bound_index = bound_index + 1; 						
			bound_low 	= int(addr_list[bound_index],16);
			bound_high 	= bound_low + int(size_list[bound_index],16);

		if ((4*index >= bound_low) & (4*index < bound_high)):
			compressed_list.append(value);
			temp_str = "%08x\n" % value;
			fileOutputHandle.write(temp_str);


	# close file
	fileOutputHandle.close();

	# verify a successful operation
	n_bytes = 0;
	for section_index, section_value in enumerate(size_list):
		# convert to int
		n_bytes = n_bytes + int(section_value,16);

	if options.printopt:
		print(str(len(compressed_list)*4) + " bytes written to file");
		print(str(n_bytes) + " bytes in section header");

	if ((len(compressed_list)*4) != n_bytes):
		print("Error: import data error");
		os.remove(options.data_str);
	else:
		print("-- Import Success --");