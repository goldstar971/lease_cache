#include "command.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>



uint32_t parse_input(command *pInputInst, char *pBuffer){
	// extract delimited fields from string
	uint32_t n = 0;
	char *start_pointer, *end_pointer;
	int command_length;
	
	int leading_whitespace;
	start_pointer=&pBuffer[0];
	end_pointer=strpbrk(start_pointer,COMMAND_DELIMITERS);

	char* command_str=(char *)calloc(256,sizeof(char));
	if(command_str==NULL){
		printf("unable to allocate memory for command\n");
		return 1;
	}

	memset(command_str,0,256);

	//handle leading whitespace before command
	if(start_pointer==end_pointer){
		leading_whitespace=strspn(start_pointer,COMMAND_DELIMITERS);
		start_pointer+=leading_whitespace;
		end_pointer=strpbrk(start_pointer,COMMAND_DELIMITERS);
	}
	do{
		end_pointer=strpbrk(start_pointer,COMMAND_DELIMITERS);
		command_length=strcspn(start_pointer,COMMAND_DELIMITERS);
		memcpy(command_str,start_pointer,command_length);
		if(command_length==0){
			break;
		}
		strcpy(pInputInst->field[n++],command_str);
		if (n > N_FIELDS){
			printf("too many fields for command!\n");
			return 1;
		}
		memset(command_str,0,command_length); //clear buffer
		//get whitespace between fields
		leading_whitespace=strspn(start_pointer+command_length,COMMAND_DELIMITERS);
		
		//adjust start pointer to the beginning of the next field
	
		start_pointer=start_pointer+leading_whitespace+command_length;
	}while(end_pointer != NULL);
	free(command_str);
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

	//if we weren't provided with a sampling rate for a track or sample command use default rate of 256
	if (n==2 &&pInputInst->table_index>7){
		//add default rate
		strcpy(pInputInst->field[n++],"0x100");
		
		if(pInputInst->table_index==9){
			//add default seed
			strcpy(pInputInst->field[n++],"0x1");
		}
	}
	else if (n==3 &&pInputInst->table_index>7){
	//convert given sample rate to hex
		sprintf(pInputInst->field[2],"%#x",(uint32_t)strtol(pInputInst->field[2],NULL,0));
		
		if(pInputInst->table_index==9){
			//add default seed
			strcpy(pInputInst->field[n++],"0x1");
		}
	}
	else if(n==4 &&pInputInst->table_index==9){
		//convert given sample rate to hex string
		sprintf(pInputInst->field[2],"%#x",(uint32_t)strtol(pInputInst->field[2],NULL,0));
		sprintf(pInputInst->field[3],"%#x",(uint32_t)strtol(pInputInst->field[3],NULL,0));
	}

	// - make sure right number of fields
	if (n_fields[pInputInst->table_index] != n){ 	// check number of fields
		return 1;
	}
		// - make sure fields are correct format
	if (field1_hex[pInputInst->table_index] & strncmp(pInputInst->field[1], "0x", 2) ){ 	// check field1 formatting
		return 1;
	}
	if (field2_hex[pInputInst->table_index] & strncmp(pInputInst->field[2], "0x", 2) ){ 	// check field2 formatting
		return 1;
	}
	if (field3_hex[pInputInst->table_index] & strncmp(pInputInst->field[3], "0x", 2) ){ 	// check field2 formatting
		return 1;
	}

	// extract fields as numbers
	if (field1_hex[pInputInst->table_index]){
		pInputInst->field1_number = (uint32_t)strtol(pInputInst->field[1], NULL, 0);
	}
	if (field2_hex[pInputInst->table_index]){
		pInputInst->field2_number = (uint32_t)strtol(pInputInst->field[2], NULL, 0);
	}
	if (field3_hex[pInputInst->table_index]){
		pInputInst->field3_number = (uint32_t)strtol(pInputInst->field[3], NULL, 0);
	}


	// return without error
	return 0;
}