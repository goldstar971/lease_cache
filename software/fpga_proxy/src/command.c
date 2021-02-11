#include "command.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

uint32_t parse_input(command *pInputInst, char *pBuffer){

	// extract delimited fields from string
	uint32_t n = 0;
	char *ptr = strtok(pBuffer, COMMAND_DELIMITERS);

	while(ptr != NULL){
		if (n > N_FIELDS){
			return 1;
		}
		strcpy(pInputInst->field[n++],ptr);
		ptr = strtok(NULL, COMMAND_DELIMITERS);
	}

	// find first field (code) in the lookup table
	pInputInst->table_index = 100;
	for (uint32_t i = 0; i < sizeof(pCodes)/sizeof(pCodes[0]); i++){

		// if there is a match, record the index
		if(!strcmp(pInputInst->field[0],pCodes[i])){
			pInputInst->table_index = i;
		}
	}

	// check that there was a table match
	if (pInputInst->table_index == 100){
		return 1;
	}

	// error check each field based on lookup table format
	// - make sure right number of fields
	// - make sure fields are correct format
	if (n_fields[pInputInst->table_index] != n){ 	// check number of fields
		return 1;
	}
	if (field1_hex[pInputInst->table_index] & strncmp(pInputInst->field[1], "0x", 2) ){ 	// check field1 formatting
		return 1;
	}
	if (field2_hex[pInputInst->table_index] & strncmp(pInputInst->field[2], "0x", 2) ){ 	// check field2 formatting
		return 1;
	}

	// extract fields as numbers
	if (field1_hex[pInputInst->table_index]){
		pInputInst->field1_number = (uint32_t)strtol(pInputInst->field[1], NULL, 0);
	}
	if (field1_hex[pInputInst->table_index]){
		pInputInst->field2_number = (uint32_t)strtol(pInputInst->field[2], NULL, 0);
	}

	// return without error
	return 0;
}