#include "stdint.h"
#include "stdio.h"
#include "jtag_proxy.h"

int main() {

    // connect and synchronize
    pHandle proxy_inst = proxy_connect();

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

    // exit
    return 0;
}