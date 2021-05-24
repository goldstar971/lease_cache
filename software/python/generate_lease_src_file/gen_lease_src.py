# dependencies
import sys;
sys.path.append("./src");
import terminal;
import clease;

# main entry point
# ---------------------------------------------------------------------------------------------
def main(argv):

	# extract script options
	options = terminal.parse(argv);

	# create lease source file
	clease.generate(options);

# entry definition for script
if __name__ == "__main__":
	main(sys.argv[1:])
