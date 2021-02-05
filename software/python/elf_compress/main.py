# dependencies
import re;
import array;
import sys, os;
sys.path.append(os.path.dirname(os.path.abspath(__file__))+"/src/");
import terminal;
import dma_elf;

# script entry
def main(argv):

	# get script options
	options = terminal.parse(argv);

	# extract elf sections
	# format:
	# 		section_addr (byte addr), section_size (in bytes)
	[addr_list, size_list] = dma_elf.get_sections(options);

	# extract elf data in compressed format
	# format:
	# 		section_data (32b = riscv_word_size)
	dma_elf.get_data(options, addr_list, size_list);


# manage script flags
if __name__ == "__main__":
	main(sys.argv[1:])