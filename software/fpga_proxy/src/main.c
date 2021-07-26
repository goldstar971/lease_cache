#include "stdint.h"
#include "stdio.h"
#include <getopt.h>
#include <string.h>
#include "jtag_proxy.h"


int main(int argc, char** argv)
{
       // connect and synchronize
    pHandle proxy_inst = proxy_connect();
    if(proxy_inst==NULL){
        printf("Synchronization failed\n");
        return(1);
    }

    //if running ui
    if(argc<2){
         uint32_t status = proxy_terminal_command(proxy_inst);

    // continue executing commands until proxy is killed
    // 0: command success
    // 1: command fail
    // 2: close
        while(status != 2){

            // verify command execution
            switch(status){
                case 0: printf("Command Successful\n"); break;
                case 1: printf("Command Failed\n"); break;
                default: break;
            }

            // get next command
            status = proxy_terminal_command(proxy_inst);
        }
    }
    //if running in headless mode
    else{
    //check to see if command has been given
        char command_str[250];
        char *start_pointer,*end_pointer;
        char arg_len;
        char opt;
        int command_length;
         uint32_t status;
        //iterate over options 
        while((opt=getopt(argc,argv,"c:"))!=-1){
            switch(opt) {
            case 'c': 
                //get total length of command arg
            //fuck strtok being non-rentrant safe

                  memset(command_str,0,250); //clear buffer
                start_pointer=&optarg[0];
                end_pointer=strchr(start_pointer,':');
                    //iterate through list of commands
                 while(end_pointer!=NULL){
                    command_length=(end_pointer-start_pointer)/sizeof(char);
                    memcpy(command_str,start_pointer,command_length); //copy characters up to the delimiter
                        status=proxy_string_command(proxy_inst,command_str);
                          switch(status){
                            case 0: printf("Command Successful\n"); break;
                            case 1: printf("Command Failed\n"); break;
                        }
                        memset(command_str,0,command_length); //clear buffer
                        start_pointer=++end_pointer;//want to point to the character after the delimiter
                          end_pointer=strchr(start_pointer,':');
                     }

              //for last command or first command if only 1 command 
                 command_length=strlen(start_pointer)/sizeof(char);
                 memcpy(command_str,start_pointer,command_length);
                 
                 status=proxy_string_command(proxy_inst,command_str);
                  switch(status){
                    case 0: printf("Command Successful\n"); break;
                    case 1: printf("Command Failed\n"); break;
                 }
             break;
            default: fprintf(stderr,"Usage: %s [-c \"command1:command2:....:commandn\"]\n",argv[0]);
            }
        }
    }
    
    return 0;
}
