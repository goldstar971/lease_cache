# dependencies
import sys;				# for exiting
import getopt;			# for command line parse getopt.getopt
import os.path;

# import object
class script_options:
	def __init__(self, src_str, dest_str, printopt, size, mem_size, bit_disc, base_addr = 0x007FC000+0x10):
		self.src_str 	= src_str;
		self.dest_str 	= dest_str;
		self.printopt 	= printopt;
		self.size 		= size;
		self.mem_size 	= mem_size;
		self.bit_disc 	= bit_disc;
		self.base_addr 	= base_addr; 		# note: base_addr = 0x01FF_0000 (byte addressible)
											# 		base_addr = 0x007F_C000 (word addressible)

# functions
def parse(argv):
	# parse command line
	try:
		opts, args = getopt.getopt(argv,"n:m:i:o:b:hp",[]);
	except getopt.GetoptError:
		print("Error: Script unrecognized input\n");
		print_usage();
		sys.exit(2);

	# populate input fields
	source_filepath = "";
	result_filepath = "lease_src.c"
	option_print = False;
	option_dual = False;
	option_size = 128;
	option_mem_size = 4*16380;
	option_bit_disc = 9;

	for opt, arg in opts:
		if (opt == '-i'):
			source_filepath = arg;
		elif(opt == '-o'):
			result_filepath = arg;
		elif (opt == '-p'):
			option_print = True;
		elif (opt == '-n'):
			option_size = int(arg);
		elif (opt == '-m'):
			if int(arg) % 4 == 0:
				option_mem_size = int(arg);
			else:
				print("Error: memory size must be a multiple of four bytes");
				exit(0);
		elif (opt == '-b'):
			option_bit_disc = int(arg);
		elif (opt == '-h'):
			print_usage();
			exit(0);

	# check that file exists
	if (os.path.exists(source_filepath) == False):
		print("Error: Specified input file does not exist\n");
		exit(0);

	# make options object to send
	options = script_options(source_filepath, result_filepath, option_print, option_size, option_mem_size, option_bit_disc);

	return options;

def print_usage():
	print("Command line options:");
	print("\t -h: show usage");
	print("\t -n: table size");
	print("\t -m: memory size []")
	print("\t -b: dual lease percentage bit range (i.e. 6bit discretization)");
	print("\t -p: enable terminal print ");
	print("\t -i: [string] input file name");
	print("\t -o: [string] output file name (defaults to \"lease_src.c\")");
