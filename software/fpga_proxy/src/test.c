#include "sampler.h"
#include "test.h"
#include <time.h> 				// timers
#include <inttypes.h> 
#include <unistd.h> 			// sleep
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>




uint32_t test_run(pHandle pInst, command *pCommand){

	// temporaries
	time_t time0, time1;
	char command_str[200];

	// put system in reset
	sprintf(command_str, "CONFIG 0x2 0x0");
	if(proxy_string_command(pInst, command_str)){
			return 1;
		}
	sprintf(command_str, "CONFIG 0x1 0x0");
	if(proxy_string_command(pInst, command_str)){
			return 1;
		}

	// load fpga memory with target application
	sprintf(command_str, "LOAD %s\r",pCommand->field[1]);
	if(proxy_string_command(pInst, command_str)){
			return 1;
		}

	// pull system out of reset 
	sprintf(command_str, "CONFIG 0x1 0x3");
	if(proxy_string_command(pInst, command_str)){
			return 1;
		}
	//begin wall-clock timer
	sprintf(command_str, "CONFIG 0x2 0x1");
	if(proxy_string_command(pInst, command_str)){
			return 1;
		}
	
	time0 = time(NULL); 						

	// check for completion of the main
	char rx_buffer[4];
	*(uint32_t *)rx_buffer = 0x00000000;
	printf("\n");
	while(*(uint32_t *)rx_buffer != 0x00000001){

		protocol_read(pInst, rx_buffer, 4, TEST_DONE_ADDR);
	}

	// report
	time1 = time(NULL);
	printf("Approx. Time-to-Execute: %lu seconds\n", time1-time0);

	char report_buffer[CACHE_REPORT_BYTES];
	char file_name[50];
	char benchmark_type[50];
	char benchmark_name[50];
	get_file_name(pCommand,file_name,benchmark_type,benchmark_name);
	printf("Benchmark_name:           %s\n", benchmark_name);
	make_cache_report(pInst, report_buffer);

	// write report to file
	char result_string[400];
	sprintf(result_string, "%s,%lu,%lu,%lu,%lu,%u,%lu,%lu,%lu,%lu,%lu,%lu,%u\n",
								pCommand->field[1], 							// path
								*(uint64_t *)(report_buffer+0), 				// instruction cache hits
								*(uint64_t *)(report_buffer+8),					// instruction cache misses
								*(uint64_t *)(report_buffer+16),				// instruction cache writebacks
								*(uint64_t *)(report_buffer+24),				// walltime (measured by both caches, only need one)
								*(uint32_t *)(report_buffer+60),				// instruction cache ID
								*(uint64_t *)(report_buffer+64),				// data cache hits
								*(uint64_t *)(report_buffer+72),				// data cache misses
								*(uint64_t *)(report_buffer+80),				// data cache writebacks
								*(uint64_t *)(report_buffer+96),				// data cache expired lease replacements (lease cache only
								*(uint64_t *)(report_buffer+112),				// data cache multiple expired lines at miss
								*(uint64_t *)(report_buffer+104),				// data cache defaulted lease renewals
								*(uint32_t *)(report_buffer+124)				// data cache ID
				);

	// write results to file
	FILE *pFile = fopen("./results/cache/results.txt","a+");
	if (!pFile){
		return 1;
	}

	// report and exit without error
	fputs(result_string, pFile);
	fclose(pFile);
	return 0;
}

uint32_t script_run(pHandle pInst, command *pCommand){

	// open file
	FILE *pFile = fopen(pCommand->field[1],"r");
	if(!pFile){
		printf("Error, could not open %s\n", pCommand->field[1]);

    	return 1;
    }

    // execute each line of script
    char line[256];
    while(fgets(line, sizeof(line)/sizeof(line[0]), pFile)){
    	if (proxy_string_command(pInst, line)){
    		return 1;
    	}
    }

    // return without error
    fclose(pFile);
	return 0;
}


uint32_t make_cache_report(pHandle pInst, char *rx_buffer){
	
	// gather cache data via fusion command
	protocol_cache_fusion(pInst, rx_buffer, CACHE_RESULT_ADDR, CACHE_L1I_ADDR);
	protocol_cache_fusion(pInst, (rx_buffer+64), CACHE_RESULT_ADDR, CACHE_L1D_ADDR);

	uint64_t item;
	for (uint32_t i = 0; i < 18; i++){
		item = (uint64_t) (*(uint32_t *)(rx_buffer+(8*i)+4)) << 32 | (*(uint32_t *)(rx_buffer+(8*i)+0));

		switch(i){
			case 0: 	printf("L1-I Hits:                %" PRIu64 "\n", item); break;
			case 1: 	printf("L1-I Misses:              %" PRIu64 "\n", item); break;
			case 2: 	printf("L1-I Writebacks:          %" PRIu64 "\n", item); break;
			case 3: 	printf("L1-I Time [cycles]:       %" PRIu64 "\n", item); break;
			case 7: 	printf("L1-I Cache ID:            %" PRIu32 "\n", *(uint32_t *)(rx_buffer+(8*i)+4)); break;
			case 8: 	printf("L1-D Hits:                %" PRIu64 "\n", item); break;
			case 9: 	printf("L1-D Misses:              %" PRIu64 "\n", item); break;
			case 10: 	printf("L1-D Writebacks:          %" PRIu64 "\n", item); break;
			case 12: 	printf("L1-D Expired Evictions:   %" PRIu64 "\n", item); break;
			case 13: 	printf("L1-D Default Assignments: %" PRIu64 "\n", item); break;
			case 14: 	printf("L1-D M-Expired Evictions: %" PRIu64 "\n", item); break;
			case 15: 	printf("L1-D Cache ID:            %" PRIu32 "\n", *(uint32_t *)(rx_buffer+(8*i)+4)); break;
			case 16:    printf("LD-D SWAPs:               %" PRIu64 "\n", item); break;
			default: 	break;
		}	
	}
	return 0;
}
