# dependencies
import sys;				# for exiting
import getopt;			# for command line parse getopt.getopt
import os.path;

# import object
class script_options:
	def __init__(self, src_str, dest_str, printopt = False):
		self.printopt 		= printopt;
		self.src_str 		= src_str;
		self.dest_str 		= dest_str;
		self.info_str 		= src_str + "_info.txt";
		self.section_str 	= dest_str + "_sections.txt";
		self.data_str 		= dest_str + "_compressed.txt";

# functions
def parse(argv):
	# parse command line
	try:
		opts, args = getopt.getopt(argv,"i:o:hp",[]);
	except getopt.GetoptError:
		print("Error: Script unrecognized input\n");
		print_usage();
		sys.exit(0);

	# populate input fields
	source_filepath = "program";
	result_filepath = "program";
	option_print = False;

	for opt, arg in opts:
		if (opt == '-i'):
			if (arg.find(".") != -1):
				print("Error: do not enter extension for input path");
				exit(0);
			source_filepath = arg;
		elif(opt == '-o'):
			if (arg.find(".") != -1):
				print("Error: do not enter extension for ooutput path");
				exit(0);
			result_filepath = arg;
		elif (opt == '-p'):
			option_print = True;
		elif (opt == '-h'):
			print_usage();
			exit(0);

	# check that file exists
	source_path_test = source_filepath+"_info.txt";
	if (os.path.exists(source_path_test) == False):
		print("Error: input file \'" + source_path_test + "\' does not exist\n");
		exit(0);

	# make options object to send
	options = script_options(source_filepath, result_filepath, option_print);

	return options;


def print_usage():
	print("Script options:");
	print("\t -h: show usage");
	print("\t -p: enable terminal print ");
	print("\t -i: [string] input file name without extension");
	print("\t -o: [string] output file name without extension)");