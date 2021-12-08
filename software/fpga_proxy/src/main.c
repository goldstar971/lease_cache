#include "stdint.h"
#include "stdio.h"
#include <getopt.h>
#include <string.h>
#include "jtag_proxy.h"


int main(int argc, char** argv)
{
       // connect and synchronize
    pHandle proxy_inst=proxy_connect();
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
        char *start_ptr, *save_ptr,*token;
        char arg_len;
        char opt;
        int command_length;
         uint32_t status;
        //iterate over options 
        while((opt=getopt(argc,argv,"c:"))!=-1){
            switch(opt) {
            case 'c': 
                start_ptr=&optarg[0];
               token=strtok_r(start_ptr,":",&save_ptr);
                    //iterate through list of commands
                 while(token!=NULL){
                        status=proxy_string_command(proxy_inst,token);
                          switch(status){
                            case 0: printf("Command Successful\n"); break;
                            case 1: printf("Command Failed\n"); return 1; break;
                        }
                       token=strtok_r(NULL,":",&save_ptr);
                }
             break;
            default: fprintf(stderr,"Usage: %s [-c \"command1:command2:....:commandn\"]\n",argv[0]);
            }
        }
         
    }
   
    return 0;
}
