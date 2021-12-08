#include "sampler.h"
#include "test.h"
#include <time.h> 				// timers
#include <inttypes.h> 
#include <unistd.h> 			// sleep
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <stdio.h>




uint32_t test_run(pHandle pInst, command *pCommand){

	// temporaries
	time_t time0, time1;
	char stat_buffer[CPU_STAT_REPORT_BYTES];
	char command_str[300];
	char file_name[256];
	char application[256];
	char benchmark_type[50];
	char benchmark_name[50];

	strcpy(application,pCommand->field[1]);
	//get benchmark type and benchmark name
	get_file_name(application,benchmark_type,benchmark_name);

	//if we aren't given the relative or absolute path try an assemble using benchmark directory
	if(access(application,F_OK)!=0){
		sprintf(application,"%s/%s/%s/program.elf",BENCHMARK_DIR,benchmark_type,benchmark_name);
	}
	if(access(application,F_OK)!=0){
		printf("Could not find provided application file: %s. \
Attempt to find alternative %s failed.\n  \
Provide either the absolute or relative path or just policy and benchmark name: \
e.g CLAM_large/adi\n If following these instructions \
fails, check to see that BENCHMARK_DIRECTORY has been defined correctly in the \
proxy makefile\n",pCommand->field[1],application);
		return 1;
	}
	//now that existence has been checked, remove the file extension, otherwise it will cause problems
	application[strlen(application)-4]='\0';

	//put peripherals and cpu in reset
	sprintf(command_str, RESET);

	if(proxy_string_command(pInst, command_str)){
		return 1;
	}
	// give comms system permission to r/w main memory.

		sprintf(command_str, SET_MM_ACCESS_COMMS);
	if(proxy_string_command(pInst, command_str)){
		return 1;
	}
			sleep(.1);
		// load fpga memory with target application
	sprintf(command_str, "LOAD %s\r",application);
		if(proxy_string_command(pInst, command_str)){
			return 1;
		}
		sleep(.1);
		//applications sometimes fail to load to the FPGA, verify this has occured (function will attempt to fix incorrect words if it finds them)
	sprintf(command_str, "VERIFY %s\r",application);
	if(proxy_string_command(pInst, command_str)){
			return 1;
		}

	// pull cpu and peripherals out of reset 
	sprintf(command_str, SET_CPU);
	if(proxy_string_command(pInst, command_str)){
			return 1;
		}
	//give CPU permission to r/w main memory
	sprintf(command_str, SET_MM_ACCESS_CPU);
	if(proxy_string_command(pInst, command_str)){
			return 1;
		}
	
	time0 = time(NULL); 						

	// check for completion of the main
	char rx_buffer[4];
	*(uint32_t *)rx_buffer = 0x00000000;
	printf("\n");
	while(*(uint32_t *)rx_buffer != 0x00000001){

		protocol_read(pInst, rx_buffer, 4, TEST_DONE_ADDR,0);
	}
	//get cpu stats
	// report
	time1 = time(NULL);
	
	protocol_cache_fusion(pInst, stat_buffer, CPU_STAT_ADDR,CPU_STAT_ADDR,6);


	FILE *pFile=NULL;
	char result_string[400];
	char report_buffer[CACHE_REPORT_BYTES];
	

	printf("Benchmark_name:           %s\n", benchmark_name);
	make_cache_report(pInst, report_buffer,stat_buffer);

	//make file of timing results
	sprintf(file_name,"%s/cache/benchmark_timing_data.txt",RESULT_DIR);
	pFile = fopen(file_name,"a+");
	if (!pFile){
			printf("Could not open or create file!\n");
			return 1;
	}

	#ifndef MULTI_LEVEL_CACHE
	sprintf(result_string,"Cache ID: %u %s_%s: Mem stall time: %lu ALU stall time: %lu Kernel time: %lu Total time: %lu\n",
		*(uint32_t *)(report_buffer+124),
		benchmark_type,
		benchmark_name,
		*(uint64_t *)stat_buffer,
		*(uint64_t *)(stat_buffer+8),
		*(uint64_t *)(report_buffer+24),
		*(uint64_t *)(stat_buffer+16));
	#else 
		sprintf(result_string,"Cache ID: %u %s_%s: Mem stall time: %lu ALU stall time: %lu Kernel time: %lu Total time: %lu\n",
		*(uint32_t *)(report_buffer+188),
		benchmark_type,
		benchmark_name,
		*(uint64_t *)stat_buffer,
		*(uint64_t *)(stat_buffer+8),
		*(uint64_t *)(report_buffer+24),
		*(uint64_t *)(stat_buffer+16));
	#endif
	fputs(result_string,pFile);
	fclose(pFile);
	//clear results string
	memset(&result_string[0],0,sizeof(result_string));

	printf("Approx. Time-to-Execute: %lu seconds\n\n", time1-time0);

	
	#ifndef MULTI_LEVEL_CACHE
	// write report to file
	
	sprintf(result_string, "%s,%lu,%lu,%lu,%lu,%u,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%u\n",
								application, 							// path
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
								*(uint64_t *)(report_buffer+128),				// data cache misses that result in default lease
								*(uint64_t *)(report_buffer+136),				// data cache random evictions
								*(uint32_t *)(report_buffer+124)				// data cache ID
				);
	#else

	sprintf(result_string, "%s,%lu,%lu,%lu,%lu,%u,%lu,%lu,%lu,%u,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%lu,%u\n",
								application, 							// path
								*(uint64_t *)(report_buffer+0), 				// instruction cache hits
								*(uint64_t *)(report_buffer+8),					// instruction cache misses
								*(uint64_t *)(report_buffer+16),				// instruction cache writebacks
								*(uint64_t *)(report_buffer+24),				// walltime (measured by both caches, only need one)
								*(uint32_t *)(report_buffer+60),				// instruction cache ID
								*(uint64_t *)(report_buffer+64),				// data cache hits
								*(uint64_t *)(report_buffer+72),				// data cache misses
								*(uint64_t *)(report_buffer+80),				// data cache writebacks
								*(uint32_t *)(report_buffer+124),				// data cache ID
								*(uint64_t *)(report_buffer+128),				// L2 cache hits
								*(uint64_t *)(report_buffer+136),				// L2 cache misses
								*(uint64_t *)(report_buffer+144),				// L2 cache writebacks
								*(uint64_t *)(report_buffer+160),				// L2 cache expired lease replacements (lease cache only
								*(uint64_t *)(report_buffer+176),				// L2 cache multiple expired lines at miss
								*(uint64_t *)(report_buffer+168),				// L2 cache defaulted lease renewals
								*(uint64_t *)(report_buffer+192),				// L2 cache misses that result in default lease
								*(uint64_t *)(report_buffer+200),               // L2 cache random evictions
								*(uint32_t *)(report_buffer+188)				// L2 cache ID
				);
	#endif

	// write results to file

	#ifdef MULTI_LEVEL_CACHE
		if(strchr(benchmark_type,'_')==NULL){
			sprintf(file_name,"%s/cache/results_multi_level.txt",RESULT_DIR);
		}
		else{
			sprintf(file_name,"%s/cache/results_%s_multi_level.txt",RESULT_DIR,strchr(benchmark_type,'_')+1);
		}
	#else
		if(strchr(benchmark_type,'_')==NULL){
			sprintf(file_name,"%s/cache/results.txt",RESULT_DIR);
		}
		else{
			sprintf(file_name,"%s/cache/results_%s.txt",RESULT_DIR,strchr(benchmark_type,'_')+1);
		}

	#endif
		pFile = fopen(file_name,"a+");
		if (!pFile){
			printf("Could not open or create file!\n");
			return 1;
		}
	// report and exit without error
	fputs(result_string, pFile);
	fclose(pFile);
	return 0;
}

uint32_t script_run(pHandle pInst, command *pCommand){
	//handles both absolute path to scripts and just providing script name i.e., run_all_PRL.pss
	 char *script_file=(char*)calloc(256,sizeof(char));
	 if(script_file==NULL){
	 	printf("failed to allocate memory for script file name!");
	 	return 1;
	 }

	strcpy(script_file,pCommand->field[1]);
	//if we don't the absolute path try an assemble using script directory
	if(access(script_file,F_OK)!=0){
		sprintf(script_file,"%s/%s.pss",SCRIPT_DIR,pCommand->field[1]);
	}
	if(access(script_file,F_OK)!=0){
		printf("Could not find provided script file: %s. \
Attempt to find alternative %s failed.\n  \
Provide either the absolute path from proxy dir or just script name: \
e.g run_all_PRL \n \
If just providing script name fails, check the proxy makefile to see \
if SCRIPT_DIRECTORY has been correctly defined\n",pCommand->field[1],script_file);
		return 1;
	}

	// open file

	FILE *pFile = fopen(script_file,"r");
	if(!pFile){
		printf("Error, could not open %s\n", script_file);
		free(script_file);
    	return 1;
    }

    // execute each line of script
    char line[256];
    while(fgets(line, sizeof(line)/sizeof(line[0]), pFile)){
    	if (proxy_string_command(pInst, line)){
    		fclose(pFile);
    		free(script_file);
    		return 1;
    	}
    }

    // return without error
    fclose(pFile);
    free(script_file);
	return 0;
}


uint32_t make_cache_report(pHandle pInst, char *rx_buffer, char *stat_buffer){
	
	// gather cache data via fusion command
	protocol_cache_fusion(pInst, rx_buffer, CACHE_RESULT_ADDR, CACHE_L1I_ADDR,16);
	
	#ifdef MULTI_LEVEL_CACHE
	protocol_cache_fusion(pInst, (rx_buffer+64), CACHE_RESULT_ADDR, CACHE_L1D_ADDR,16);
	protocol_cache_fusion(pInst, (rx_buffer+128), CACHE_RESULT_ADDR, CACHE_L2_ADDR,20);
	#else 
	protocol_cache_fusion(pInst, (rx_buffer+64), CACHE_RESULT_ADDR, CACHE_L1D_ADDR,20);
	#endif
	uint64_t item;
	#ifndef MULTI_LEVEL_CACHE
	for (uint32_t i = 0; i < 20; i++){
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
			case 16:    printf("L1-D Default_misses:      %" PRIu64 "\n", item); break;
			case 17:    printf("L1-D Random Evictions:    %" PRIu64 "\n", item); break;
			default: 	break;
		}	
	}
	#else
	for (uint32_t i = 0; i < 30; i++){
		item = (uint64_t) (*(uint32_t *)(rx_buffer+(8*i)+4)) << 32 | (*(uint32_t *)(rx_buffer+(8*i)+0));

		switch(i){
			case 0: 	printf("L1-I Hits:                %" PRIu64 "\n", item); break;
			case 1: 	printf("L1-I Misses:              %" PRIu64 "\n", item); break;
			case 2: 	printf("L1-I Writebacks:          %" PRIu64 "\n", item); break;
			case 3: 	printf("L1-I Kernel Time [cycs]:  %" PRIu64 "\n", item); break;
			case 7: 	printf("L1-I Cache ID:            %" PRIu32 "\n", *(uint32_t *)(rx_buffer+(8*i)+4)); break;
			case 8: 	printf("L1-D Hits:                %" PRIu64 "\n", item); break;
			case 9: 	printf("L1-D Misses:              %" PRIu64 "\n", item); break;
			case 10: 	printf("L1-D Writebacks:          %" PRIu64 "\n", item); break;
			case 15: 	printf("L1-D Cache ID:            %" PRIu32 "\n", *(uint32_t *)(rx_buffer+(8*i)+4)); break;
			case 16: 	printf("L2 Hits:                  %" PRIu64 "\n", item); break;
			case 17: 	printf("L2 Misses:                %" PRIu64 "\n", item); break;
			case 18: 	printf("L2 Writebacks:            %" PRIu64 "\n", item); break;
			case 20: 	printf("L2 Expired Evictions:     %" PRIu64 "\n", item); break;
			case 21: 	printf("L2 Default Assignments:   %" PRIu64 "\n", item); break;
			case 22: 	printf("L2 M-Expired Evictions:   %" PRIu64 "\n", item); break;
			case 23: 	printf("L2 Cache ID:              %" PRIu32 "\n", *(uint32_t *)(rx_buffer+(8*i)+4)); break;
			case 24:    printf("L2 Default_misses:        %" PRIu64 "\n", item); break;
			case 25:  	printf("L2 Random Evictions:      %" PRIu64 "\n", item); break;
			default: 	break;
		}	
	}
	#endif
	for (uint32_t i = 0; i < 3; i++){
		item = (uint64_t) (*(uint32_t *)(stat_buffer+(8*i)+4)) << 32 | (*(uint32_t *)(stat_buffer+(8*i)+0));
		switch(i){
			case 0:     printf("Mem stall time [cycs]:    %" PRIu64 "\n", item); break; 
			case 1:		printf("ALU stall time [cycs]:    %" PRIu64 "\n", item); break;	
			case 2:		printf("Approx total time [cycs]: %" PRIu64 "\n", item); break;
			default:  break;
		}
	}
	return 0;
}
