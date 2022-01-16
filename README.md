# Setup
1. install Quartus version 18.1 (can be later, but you may need to upgrade ip)
2. run ./setup_env.sh from the repository root directory
3. you are all set to start generating data.

# Hardware
Contains the FPGA hardware for the system.

## top subdir
Directory contains all projects used for research. The only difference between any of the projects is the top.h located in the include subdirectory of a project directory. This file allows one to specify:
1. the number of cache levels (1 or 2).
2. individual set associativity for each cache (2-way 4-way, 8-way, 16-way or fully associative)
3. individual cache replacement policy for each cache
4. individual capacity of each cache
5. the bitwidth of the lease value register and the bitwidth of long lease percentage

You can modify other things, but you probably will not need to do so and it will require you to have changed other files as well. Once changes are made, project will have to be recompiled in order for things to take effect. SOF files for each project have been uploaded to the repo, so you do not need to compile first before generating data.



**Projects**

- system_fa_dynamic_lease_multi_level
	
	Project is setup for the multi-level lease cache system. For the multi-level lease cache, the sampler table has only 64 entries compared to 256 for the other projects on account of resource constrains, so you probably want to sample using the multi-level PLRU cache system to get samples for multi-level.
- system_fa_dynamic_lease_perfected
	
	Project is setup for the single-level lease cache system.
- system_fa_PLRU_multi_level
	
	Project is setup for the multi-level PLRU cache system.
- system_fa_PLRU_perfected
	
	Project is setup for the single-level PLRU cache system.

**Associated Bash Functions**

- compile_plru 

	*Purpose:* runs analysis and synthesis, fitter, and assembler for the single-level PLRU cache system.

	*Outputs:* sof file
- compile_plru_multi_level 

	*Purpose:* runs analysis and synthesis, fitter, and assembler for the multi-level PLRU cache system.

	*Outputs:* sof file
- compile_lease_scope: 

	*Purpose:* runs analysis and synthesis, fitter, and assembler for the single-level lease cache system.

	*Outputs:* sof file
- compile_lease_scope_multi_level: 

	*Purpose:* runs analysis and synthesis, fitter, and assembler for the multi level lease cache system.
	
	*Outputs:* sof file

- open_plru: 

	*Purpose:* 

	open single-level PLRU cache system in Quartus.
- open_lease_scope: 

	*Purpose:* 

	open single-level lease cache system in Quartus.
- open_plru_multi_level: 

	*Purpose:* 

	open multi-level PLRU cache system in Quartus.
- open_lease_multi_level: 

	*Purpose:* 

	open multi-level lease cache system in Quartus.
- program_plru: 

	*Purpose:* programs FPGA with single-level PLRU cache system.
- program_lease_scope: 

	*Purpose:* 

	programs FPGA with single-level lease cache system.
- program_plru_multi_level: 

	*Purpose:* 

	programs FPGA with multi-level PLRU cache system.
- program_lease_multi_level: 

	*Purpose:* 

	programs FPGA with multi-level lease cache system.

## internal subdir

**Contents**:
- core:  contains RISCV core with 32-bit I,M, and F extensions, as well as the port switch module for choosing between cache memory and peripheral register access.
- cache: contains n-way associative single-level caches as well as general cache replacement controllers and cache performance controllers.
- cache_2level: contains  n-way associative multi-level cache and multi-level replacement controllers
- sampler_tracker: contains cache line lease tracker and reuse interval sampler
- system: contains: top level for both single and mult-level cache systems
- system_controller: memory controller which transfers data between the different main memory, cache memory, and the RISC core. 

## peripheral subdir
	Module with registers for reading and writing to cache performance controllers, reuse interval sampler, cache line lease tracker, 
	RISC CPU run-time statistcs, and internal and peripheral system reset controller.

## external subdir
	Contains intel jtag controllers, external memory controller which arbitrates access to main_memory and peripheral registers between the fpga proxy, and internal RISC system (includes core and cache), and the controller for handling communication with the fpga proxy. Also contains Intel IP for DDR3 SDRAM hardware controller.
## include subdir
	Contains files which hold macros used in other hardware files. There only ones you will likely need to modify or look at are "sampler.h", if you want to change the capacity of the sampling table; "float.h", which contains the delay for each floating point hardware operation and may need to be adjusted if you change the clock rate of the floating point hardware unit inside of the RISC core; 
	**Include files**
- utilities.h: macro for taking ceiling of the base 2 logarithm of a binary number.
- tracker.h: parameters for cache line tracker. You might change this if you change the capacity of a cache you are tracking
- sampler.h: parameters for sampler. You might change this if you wanted to adjust the size of the sampling table.
- riscv_v2_2.h: macros for the instruction set and inclusion of hardware for the RISCV core. You might modify this if you are adding instructions and you might look at this if you are trying to debug program run using Signal Tap and the dissasembly of a program.
- peripheral.h:  macros for the addresses of different peripheral's registers.
- "mem.h": parameters for system memory address width.
- "logic_components.h": includes logical components used in hardware modules such as LFSR, DFFs, encoders, etc
- "float.h": parameters for the delay needed for the intel IP to complete a specific floating point operation at the current clock speed. Change if you change the speed at which the hardware FALU inside the RISCV core is running at. 
- "exception.h": macros for exception states inside the RISCV core
- "comm.h": includes modules for the fpga_proxy interface.
- "cache_components.h": includes cache components for single-level and multi-level cache.
- "cache.h": macros for different cache configurations, parameters for cache block size, and base addresses for lease lookup tables in main memory. 

## utilities subdir
Contains the logical hardware used internally in the higher modules such as LFSRs, encoders, DFFs, PLLs, embedded memory. Also has a script for generating efficient arbitrary sized priority encoders.


# Software

## Benchmark subdir
	Contains the C files for the various benchmarks in the 30 benchmark poly-benchsuite as well as a linker files and programs for converting the output elf files from GCC into compressed binaries with program section information output to seperate files. In all of the benchmark directories of a given dataset size, the makefile is soft linked to the makefile in CLAM_(size)/2mm/makefile i.e. The benchmark source files and header files for single scope benchmarks are soft linked to the header and source files of CLAM for small dataset and the benchmark source files and header files for multi-scope benchmarks are soft linked to the header and source files of SHEL for small dataset. This is to both decrease the size of the repo by ommitting redundant information and also because if you change the scopes in all benchmark, it will change the scope in that benchmark for all sizes and all multi-scoped policies, which means much less work for you.

**Contents**
	-elf_compress: contains rust program which converts program.elf files output by GCC into compressed binaries, with program section information copied to seperate text files which are then used by the FPGA proxy to flash the main memory on the FPGA board with the compressed binary.
	-ld: contains linker file used to place lease lookup table in a specific memory addressed in the binary program file
	-include: contains C source and header files for the polybench suite as well as Source and Header files for the RISCV.
	-various benchmark directories for different dataset sizes. 

**Associated Bash Functions**
- make_benchmarks: 

    *Purpose:*

	compiles all benchmarks for a given policy and dataset size. Does them all simultaneously so may briefly take up a large amount of RAM 

    *Usage*: 

	run in a benchmark policy directory: e.g., "C-SHEL/large"

    *Outputs:*

	1. Compiled binaries and associated files.

- make_run_all_script:

    *Purpose:* 

	generate script to make fpga_proxy command the fpga system to run all benchmarks for a given policy and dataset size and return cache statistics

    *Usage*: 

	run in a benchmark policy directory: e.g., "C-SHEL/large"

    *Outputs:*
	
	1. fpga proxy scripts: used for script commands
- make_sample_all_script:

    *Purpose:* 

	generate script to make fpga_proxy command the fpga system to run all benchmarks for a given policy and dataset size and return reuse interval sampling data

    *Usage*: 

	run in a benchmark policy directory: e.g., "C-SHEL/large"

    *Outputs:*
	
	1. fpga proxy scripts: used for script commands
- make_track_all_script:

    *Purpose:* 

	generate script to make fpga_proxy command the fpga system to run all benchmarks for a given policy and dataset size and return cache line tracking data.

    *Usage*: 

	run in a benchmark policy directory: e.g., "C-SHEL/large"
    *Outputs:*
	
	1. fpga proxy scripts: used for script commands




## Fpga Proxy subdir

**How to make proxy**
1. in this directory enter into terminal either "make" or, if you wish to build for a multi-level cache "make multi-level". Alternatively, call bash function make_proxy.

**How to use proxy**
	
-	If using the UI mode. Reset the FPGA and then enter into the terminal: "run_proxy". You will be able to enter any number of commands without having to reset the FPGA. To exit, just use "Ctrl-c". 

-	If using the headless mode, enter "run_proxy -c" follwed by a program command in double quotes i.e., 'run_proxy -c "SCRIPT run_all_PRL". You can chain an arbitrary number of commands together using the ":" e.g., run_proxy -c "SCRIPT track_all_CLAM_medium:run_all_SHEL_medium:Sample_all_PRL_large"'. 

**TIPS/INFO**  
- If you are getting verification errors or on any sort of other error, just reset the fpga and try again. If you reset the FPGA and you are in the UI, you must exit and then reinvoked it in order for things to work. Resetting the FPGA refers to pushing the hard reset button on the board. This reset is necessasry to allow the proxy and the fpga_hardware proxy comms interface to complete synchronization.
- If you run either the headless mode or the UI mode and you only see the message "JTAG Connection successful - press Ctrl-c to exit" without anything following it, that means you didn't reset the FPGA before invoking either.
- If you see the bottom rightmost fpga (with the USB cable set as the top) user LED turn on, that means the benchmark kernel has started running. For most benchmarks this will be within twenty seconds regardless of dataset size. For Cholesky, Ludcmp, and Lu, this will likely be around 4 hours for the large dataset size and ~70 seconds for the medium dataset size. The reason is that for these three benchmarks, the init_array function which runs before the kernel, takes up the vast majority of the runtime because it converts the data matrices to positive semi-definite matrices which requires a triple nested for loop over the whole matrix.
- You can't run nested Script commands, i.e,. having scripts that contain script commands in them. For unknown reasons, which 30+ hours of effort was unable to debug, having more than like 3 file pointers pointing to open files causes a malloc error, even if you set stack size to unlimited.  This doesn't make a lot of sense at all, but I was unable to fix this issue.

- There are other proxy commands besides the five detailed here, but they are only used as part of other commands

- commands are case sensitive

- for benchmark file in proxy commands, one can provide either the relative path to the benchmark program from the fpga_proxy directory 
e.g., "RUN ../benchmarks/CLAM_large/atax/program" or just the name policy and dataset size e.g., "RUN CLAM_large/atax".

- for script files in SCRIPT proxy commands, one can provide either the relative path to the script from the fpga_proxy directory e.g., 
"SCRIPT ../scripts/run_all_CLAM.pss" or just the name of the script without the file extension e.g., "SCRIPT run_all_CLAM.pss",

**Proxy Commands**

- RUN

	*Purpose:*

	runs benchmark and report back cache run-time statistics. Results are both output to the terminal 
	and appended to a results file specific to the dataset size and cache level located in the software/results/cache/ directory.

	*Usage:* 

	RUN <benchmark file>

	*Input Args:*

	1. benchmark file: benchmark program file. 

	*Output:* 

	results_file: for single-level cache, from left to right, results data is:

	- instruction cache hits
	- instruction cache misses
	- instruction cache writebacks
	- walltime 
	- instruction cache ID
	- data cache hits
	- data cache misses
	- data cache writebacks
	- data cache expired lease replacements 
	- data cache multiple expired lines at miss
	- data cache defaulted lease renewals
	- data cache misses that result in default lease
	- data cache random evictions
	- data cache ID

	for multi-level cache, from left to right, results data is:

	- instruction cache hits
	- instruction cache misses
	- instruction cache writebacks
	- walltime
	- instruction cache ID
	- data cache hits
	- data cache misses
	- data cache writebacks
	- data cache ID
	- L2 cache hits
	- L2 cache misses
	- L2 cache writebacks
	- L2 cache expired lease replacements 
	- L2 cache multiple expired lines at miss
	- L2 cache defaulted lease renewals
	- L2 cache misses that result in default lease
	- L2 cache random evictions
	- L2 cache ID



- TRACK

	*Purpose:*

	Run benchmark and return lease cache line tracking data.

	*Usage:*

	TRACK <benchmark file> <tracking rate>

	*Input Args:*

	1. benchmark file: benchmark program file
	2. tracking rate: the length of logical time in between writing the cache line lease register status bits to buffer (logical time is in terms of ld/st instructions). (optional). Default rate is 256. 

	*Outputs:*

	1. tracking files: CSV files that contain the information generated by the cache line tracker. Tracking files are formatted in the following manner with N being the cache capacity divided by 32.  The first N fields is all cache lines with short leases. The next F fields is all cache lines  with medium leases. The next N fields is all cache lines with long leases. Each bit is a boolean corresponding to a cachline. A cache line with a longer lease may something indicate that it has a shorter lease. Due to the way the data is processed this doesn't matter. The remaining 4 fields represent the bytes of a benchmark kernal run-time at that moment in terms of logical time. Fields on a line are arranged left to right in order in *ascending* order, while inside of a field, the arrangement is left to right in *descending order*. 

- SAMPLE

	*Purpose:*

	Run benchmark and return sampling data

	*Usage:*

	SAMPLE <benchmark file> <sampling rate> <seed>

	*Input Args:*

	1. benchmark file: Benchmark program file.
	2. sampling rate: the average length of logical time in between a reference sample (logical time is in terms of ld/st instructions). Valid values are between 0 and 65535. Will round down the given value to the nearest power of 2.  Default rate is 256. (optional) 
	3. seed: the initial seed value for the LFSR. Valid values are between 1 and 13383. Default value is 1 (optional). 

	*Outputs:*

	1. Sampling files: Text files which contain benchmark run_time data obtained using the reuse-interval sampler. From left to right, the fields are:
program_reference (with the 8 MSB being the scope number for multi-scope benchmarks), reuse_interval (in terms of logical time), block tag, and time of reuse (in logical time). 

- SCRIPT

	*Purpose:*

	Run set of commands listed in text file.

	*Usage:*

	SCRIPT <script file>

	*Input Args:*

	1. Script file: The name of the script.

- CLOSE

	*Close:*

	Close the UI mode (you can just use Ctrl-c though).

	*Usage*

	CLOSE

**Makefile**

Make file contains recipies to build the proxy for either a single or multi-level cache. Additionally, it is in this file that the scripts directory, benchmark base directory, and results directories base paths, relative to the fpga_proxy directory are specified. You can change this parameters to change where the proxy will look for benchmarks and scripts, as well as where it will output results.

**Bash Scripts**

- get_predicted_misses.sh

	*Purpose:* 

	Generates leases for 64,128,256,512, and 1024 sample rates for initial LFSR seeds of 1,2,3,4, and 5 using sampling data generated by running sensitivity_sample.h for the CLAM lease agorithm and writes the projected number of misses plus some other data to a csv file.

	*Outputs:* 

	1. perdicted_misses.txt: CSV file containing the number of misses projected by the CLAM lease algorithm for a given LFSR seed, sampling rate, dataset_size, cache-level, and benchmark.

- sensitivity_sample.sh

	*Purpose:* 

	Get sampling data, for single and multi-scoped benchmarks for either small or medium dataset sizes, for single or multi-level cache, for sampling rates of 64,128,256,512, and 1024 and initial LFSR seeds of 1,2,3,4, and 5.

	*Outputs:*

	1. Sampling files: see SAMPLE proxy command for details.

- sensitivity_run.sh

	*Purpose:*

	Get cache runtime statistics for single and multi-scoped benchmarks for either small or medium dataset sizes, for single or multi-level cache, for sampling rates of 64,128,256,512, and 1024 and initial LFSR seeds of 1,2,3,4, and 5 using generated leases.

	*Outputs:*
	
	results files: see RUN proxy command for details. 

**Associated Bash Functions**

- goto_proxy

	*Purpose:* 

	changes directory to the fpga_proxy sub-directory

- make_proxy

	*Purpose:* 

	Makes proxy.

	*Input Args:*  
	1. multi-level: specifies whether to make proxy for multi-level or not. Accepted arguments 'multi-level' (optional).

	*Outputs:*
	1. compiled proxy binary

- run_proxy 
	
	*Purpose:*

	Invokes proxy.

	*Input Args:*
	1. command: double quoted string of proxy commands. If ommited, proxy will enter UI mode. Flag is (-c). (optional)


## CLAM subdir
**Associated Bash Functions**
- gen_leases

    *Purpose:*

    Passes Input Args for sample rate, seed, dataset sizes, cache level, set associativity, and lease lookup table size,
     to run.sh followed by post.sh. If an input argument is ommited, default values are selected. See run.sh and post.sh for more details.
    
**bash Scripts** 
-	run.sh

    *Purpose:* 

    Uses Input Args Input Args for sample rate, seed, dataset sizes, cache level, set associativity, and lease lookup table size to generate leases for all benchmarks for all policies for dataset sizes selected via command line prompts.
    
    *Input Args*: 
    1. rate: sampling rate. Default is 256. Flag is (-r). (optional)
    2. seed: seed value used to initalize sampling LFSR. default is 1. Flag is (-s). (optional)
    3. llt_size: number of entries in the lease lookup table: default is 128. Flag is (-l). (optional)
    4. multi_level: selects whether to generate for a multi-level cache : default is no. Flag is (-m). (optional)
    5. ways: Specify set associativity, default is fully associative. Flag is (-w). (optional)
    6. capacity: Specify number of lines in the lease cache. Default for single-level is 128 and 512 is default for multi-level cache. Flag is (-c). (optional)
    
    *Outputs:* see clam function for details
    
-	post.sh

    *Purpose:* 

    takes all generated lease.c files for all policies and all data_set sizes, which had a given set associativity, lease lookup table size, and cache capacity and moves them to the corresponding folder in the software/benchmarks/directory. Then compiles all benchmarks with the new leases and creates run_all and track_all scripts for each policy and data_set_size e.g., "run_all_CLAM_medium.pss".
    
    *Inputs Args*: 
    1. llt_size: Size of lease lookup table.
    2. cache_size: capacity of lease cache.
    3. num_ways: set associativity (for fully associative set equal to cache size).
    
    *Outputs:*
    1. fpga proxy scripts: Scripts that will command the fpga to track or run all possible benchmarks for a given policy and dataset size.
    2. compiled binaries and associated files.
    
### Lease Generation Software
**How to build**
1. enter into terminal "make CLAM".

**How to run**
1. Enter into terminal either "./target/release/clam" or if you wish to build and run in the same step "cargo run --release", along with the required arguments and any flags.

**clam help**

	*Usage*:
    
        clam [FLAGS] [OPTIONS] -s <CACHE_SIZE> <INPUT> <OUTPUT>

    *Args*:
    
        <INPUT>     Sets the input file name
        <OUTPUT>    Sets the output file Location
    
    *FLAGS*:
    
        -c               calculate leases for CSHEL
        -d               enable even more information about lease assignment
        -h, --help       Print help information
        -V               output information about lease assignment
            --version    Print version information

    *OPTIONS*:
    -D <DISCRETIZE_WIDTH>             bit width avaiable for discretized short lease probability
                                      [default: 9]
    -E <EMPIRICAL_SAMPLE_RATE>        Use given or empirically derived sampling rate [default: yes]
    -L <LLT_SIZE>                     Number of elements in the lease lookup table [default: 128]
    -M <MEM_SIZE>                     total memory allocated for lease information [default: 65536]
    -p <PRL>                          calculate leases for prl (only for non_phased sampling files)
                                      [default: 5]
    -s <CACHE_SIZE>                   target cache size for algorithms
    -S <SAMPLING_RATE>                benchmark sampling rate [default: 256]

    *Outputs:*   
1. lease files: file containing list of leases in order of least to greatest scope and reference as well as the number of misses projected by the argument.
2. lease.c files: C file containing the generated lease information converted to a static array with an attribute telling the linker to place at a specific address in memory when compiling the binary.

# MATLAB_data_visualizations
## lease_cache_tracking subdir
**matlab scripts**
1. plot_tracking_results.m: detailed in generate_cache_spectrums
## cache_statistics subdir
Concerns the analysis of cache data generated during benchmark runs.
**matlab scripts**
1. plot_cache_summary.m: detailed in the plot_cache_statistics function further on in the document.
2. sensitivity_plot.m: 

	Purpose: 
	
	Analyzses the results data generated by running sensitivity_run.sh and get_predicted_misses.sh

	*Inputs Arguments*: none

	*Outputs:* 
	
	1. sensitivity_plots: Boxplots of the misses for each benchmark normalized to plru for different seed values and sampling rates, with a different plot for each lease policy, and boxplots of the projected misses for the CLAM lease policy obtained from lease generation for different sampling rates and seed values.

**Associated Bash Functions 
- plot_cache_statistics

	*Purpose:*
	
	To graph the cache statistics resulting from benchmark runs. If an optional argument isn't provided at the command line, a UI will appear.	It runs the matlab script plot_cache_summary.m.

	*Input Args*: 
	1. dataset_size: string corresponding to the dataset size you wish to generate cache spectrums (optional)
	2. multi_level: accepted values are ['yes', 'no'] (optional)

	*Outputs:*
	1.  miss graphs: plots the number of misses for different policies for different benchmarks for the given data set size and cache heriarchy 
	normalized by the PLRU results.
	2. miss_ratio graphs: plots the number of misses as a percentage of total references for different policies for diferent benchmarks 
	3. clock_cycles graphs: plots the number of clock cycles for different policies for different benchmarks normalized by the PLRU results.
	4. contention graphs: On the right size, the subplot is the percent error of misses during a benchmark run for a specific lease policy from the number of misses projected during lease generation for that policy. On the upper left side, the subplot is the ratio of random evictions to misses for different policies for different benchmarks, which is a measure of cache vacancy. The lower left subplot, displays the previously generated miss graphs for reference.
	5. Writes the geomean vaues for misses and clock cycles to the file geomean.txt
- generate_cache_spectrums
 
	*Purpose:*

	To generate cache tenancy spectrums from the data generated from using the software proxy TRACK commmand. It runs the matlab script plot_tracking_results.m.
	If the first three argument aren't provided at the command line, a UI will appear.

	*Input Args*
	1. multi_level: accepted values are ['yes', 'no'] (optional)
	2. lease_policy: specify the name of the lease for which you wish to generate cache spectrums (optional)
	2. dataset_size: string corresponding to the dataset size you wish to generate cache spectrums (optional)
	4. benchmarks to plot: matlab array whose values correspond to the position of a benchmark in an alphabatized list of all benchmarks for which tracking data has been generated e.g., [3, 4, 5]. If this argument is ommitted, it will use all benchmarks for which tracking data has been generated.  

	*Outputs:*
	1. cache_tenancy_spectrum graphs: On the left side is a plot of the aggregate cache vancancy over the benchmark run-time i.e., the number of cache lines which are not expired. On the right side is a plot of lease register status for all cache lines over time, which distinguishes leases that are expired from leases with short, medium or long time remaining before expiration.
	
    *WARNING*: 
    For the large data set benchmark runs and the default tracking rate, your computer may very well run out of memory when trying to generate the plots resulting in MATLAB crashing. At times 40 GB of RAM was not enough. If ploting is still desired, you will have to modify lines 111 of plot\_tracking\_results.m and line 15 of src/extract_tracking_data.m.
	

# Data Generation walkthrough
For this walkthrough, we will be generating results for medium dataset for all lease policies 
(CLAM SHEL C-SHEL and PRL) for the single-level cache for a sample rate of 512. 
We will assume that the repo has just been set up. All paths are relative to project root directory
1. go to software/benchmarks/CLAM_medium
2. in terminal enter 'make_sample_all_script 512'
3. repeat steps 1 and 2 or software/benchmarks/SHEL_medium 
4. connect up fpga to laptop and power fpga on
5. in terminal enter 'program_plru' to program the fpga with the single-level PLRU cache system
 (if you don't have any prior leases generated then sampling with the lease cache will be really slow)
6. in terminal enter 'make_proxy' to generate fpga_proxy
7. in terminal enter 'run_proxy -c "SCRIPT sample_all_SHEL_medium:SCRIPT sample_all_CLAM_medium"
8. cd software/CLAM
9. in terminal enter gen_leases -r 512 to generate leases from the sampling files you just generated and then compile and link them with benchmarks
10. using the prompts specify you only wish to generate leases for the medium dataset 
11. erase all but the first 30 lines of the results_medium.txt file in software/fpga_proxy/results/cache/ directory (prior results were pushed to git)
The first 30 lines are the baseline benchmark results using PLRU and never change.
12. in terminal enter 'program_lease_scope' to program the fpga with the single-level lease cache system.
13. in terminal enter run_proxy -c "SCRIPT run_all_CLAM_medium:run_all_SHEL_medium:run_all_C-SHEL_medium:run_all_PRL_medium"'
14. in terminal enter 'plot_cache_statistics medium no'
15. You've are done, Graphs of the results will be in MATLAB_data_visualizations/cache_statistics/cache_statistics_graphs/single_level/


