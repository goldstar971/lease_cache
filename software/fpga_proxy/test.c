#include "stdint.h"
#include "stdio.h"
#include <getopt.h>
#include <string.h>
#include "unistd.h"

int main(int argc, char** argv)
{
       // connect and synchronize
    //check to see if command has been given
        char command_str[1000];
        char *start_pointer,*end_pointer;
        char arg_len;
        char opt;
         FILE *done_file=NULL;
        FILE *begin_file=NULL;
         begin_file=fopen("begin_file.txt","w");
                    fputs("2",begin_file);
                    fclose(begin_file);
		 begin_file=fopen("begin_file.txt","r");
		 printf("%c\n",fgetc(begin_file));
		rewind(begin_file);
		char r=fgetc(begin_file);
		printf("r is: %c\n",r);
		if(r=='2'){
			printf("test sucessful");
		}
		return 0;
}
