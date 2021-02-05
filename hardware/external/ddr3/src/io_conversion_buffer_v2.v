// Memory controller bus must be 256-bit Avalon Memory Mapped
//
//                                 _______________________     
//        |                sys_   |                       |    s0_
// (to processor system) <------> | io_conversion_buffer  | <------> (to avalon CCD Bridge)
//                                |                       |
//                                |_______________________|
//
//
//
// -------------------------------------------------------------------------------------------------------

`define ST_DDR3_IO_BUFFER_IDLE          3'b000
`define ST_DDR3_IO_BUFFER_READ          3'b001
`define ST_DDR3_IO_BUFFER_WRITE         3'b010
`define ST_DDR3_IO_BUFFER_READ_BLOCK    3'b011
`define ST_DDR3_IO_BUFFER_WRITE_BLOCK   3'b100
`define ST_WAIT_CLEAR                   3'b101

module io_conversion_buffer_v2 #( 
    parameter AWIDTH, 
    parameter DWIDTH 
)(
    // interface to internal/embedded processing system
    input                   sys_clock_i,
    input                   sys_reset_i,
    input                   sys_req_i,
    input                   sys_reqBlock_i,
    input                   sys_rw_i,
    input                   sys_clear_i,
    input   [AWIDTH-1:0]    sys_addr_i, 
    input   [DWIDTH-1:0]    sys_data_i,
    output                  sys_ready_o, 
    output                  sys_valid_o,
    output                  sys_done_o, 
    output  [DWIDTH-1:0]    sys_data_o,
    
    // interface to avalon DDR3 controller hardware subsystem 
    input                    s0_ready,           
    input                    s0_rdata_valid,   
    input       [255:0]      s0_rdata,   
    output wire              s0_burstbegin,      
    output wire [24:0]       s0_addr,  
    output wire [255:0]      s0_wdata,    
    output wire              s0_read_req,
    output wire              s0_write_req, 
    output wire [9:0]        s0_size
);

// port mappings
// ----------------------------------------------------------------------------
reg                 sys_valid_reg, sys_done_reg, sys_ready_reg;
reg [DWIDTH-1:0]    sys_data_reg;
reg                 s0_burstbegin_reg, s0_read_req_reg, s0_write_req_reg;
reg [24:0]          s0_addr_reg;
reg [255:0]         s0_wdata_reg;
reg [9:0]           s0_size_reg;

// direct mappings
assign sys_ready_o = sys_ready_reg;          

// intermediate mappings
assign sys_valid_o = sys_valid_reg;
assign sys_done_o = sys_done_reg;
assign sys_data_o = sys_data_reg;
assign s0_burstbegin = s0_burstbegin_reg;
assign s0_addr = s0_addr_reg;
assign s0_wdata = s0_wdata_reg;
assign s0_read_req = s0_read_req_reg;
assign s0_write_req = s0_write_req_reg;
assign s0_size = s0_size_reg;

// interface conversion buffer controller
// ----------------------------------------------------------------------------
reg [2:0]   state;
reg [2:0]   sub_word_reg;
reg [1:0]   flag_write;
reg [1:0]   flag_block;

reg [31:0]  rx_buffer[0:15];
reg [31:0]  tx_buffer[0:15];

integer i;
reg [3:0]   rx_ptr, read_ptr,
            tx_ptr, write_ptr;
reg [4:0]   n_rx, n_tx;
//reg         tx_buffer_beta_delay_reg;
reg [3:0]   delay_reg;

always @(posedge sys_clock_i) begin 
    // reset state
    if (!sys_reset_i) begin
        // generics
        state = `ST_DDR3_IO_BUFFER_IDLE;
        flag_write = 'b0;
        flag_block = 'b0;

        // processor system signals
        sys_ready_reg = 1'b0;
        sys_valid_reg = 1'b0;
        sys_done_reg = 1'b0;
        sys_data_reg = 'b0;

        // CDC signals
        s0_burstbegin_reg = 1'b0; 
        s0_read_req_reg = 1'b0; 
        s0_write_req_reg = 1'b0;
        s0_addr_reg = 'b0;
        s0_wdata_reg = 'b0;
        s0_size_reg = 'b0;

        // control signals
        sub_word_reg = 'b0;

        // data buffer params
        rx_ptr = 'b0; tx_ptr = 'b0; 
        read_ptr = 'b0; write_ptr = 'b0;
        n_rx = 'b0; n_tx = 'b0;
        for (i = 0; i < 16; i = i + 1) begin
            tx_buffer[i] = 'b0;
        end

        //tx_buffer_beta_delay_reg = 1'b0;
        delay_reg = 'b0;

    end
    // active sequencing
    else begin

        // rx buffer logic
        // ----------------------------------------------------------------
        // rx_ptr   pointer to next buffer location to write to
        // read_ptr pointer to the next buffer location to read from
        // n_rx     count of the number of unread elements in the buffer 

        // store incoming data if initial request (sys_req_i == 1) or if subsequent data from a
        // block request (sys_reqBlock_i == 1)
        if (sys_req_i) begin
            if (sys_rw_i) begin
                rx_buffer[rx_ptr] = sys_data_i;                         // store incoming data
                n_rx = n_rx + 1'b1;                                     // increment count of unread elements in buffer
                rx_ptr = rx_ptr + 1'b1;                                 // point to next buffer location
            end
        end
        else begin  // if reqBlock_i still high then it is a write command
            if (sys_reqBlock_i) begin
                rx_buffer[rx_ptr] = sys_data_i;                         // store incoming data
                n_rx = n_rx + 1'b1;                                     // increment count of unread elements in buffer
                rx_ptr = rx_ptr + 1'b1;                                 // point to next buffer location
            end
        end

        // default signals to DDR3
        s0_burstbegin_reg = 1'b0;
        s0_read_req_reg = 1'b0;
        s0_write_req_reg = 1'b0;

        // default signals to system
        //sys_ready_reg = s0_ready;
        //sys_done_reg = 1'b0;
        sys_valid_reg = 1'b0;

        if (delay_reg) delay_reg = delay_reg - 1'b1;
        else begin

        case(state)
            `ST_DDR3_IO_BUFFER_IDLE: begin
                // ready control
                if (s0_ready & (n_tx == 'b0)) sys_ready_reg = 1'b1;

                if (sys_req_i & s0_ready) begin

                    // clear the ready signals
                    sys_ready_reg = 1'b0;

                    // single word (32b) request
                    if (!sys_reqBlock_i) begin
                        // READ
                        if (!sys_rw_i) begin
                            s0_burstbegin_reg = 1'b1;
                            s0_size_reg = 10'h001;
                            s0_addr_reg = {{4'b0000},sys_addr_i[23:3]};
                            sub_word_reg = sys_addr_i[2:0];
                            s0_read_req_reg = 1'b1;
                            state = `ST_DDR3_IO_BUFFER_READ;
                        end
                        // WRITE
                        else begin
                            // in order to perform a single word write must first read the half-block
                            // then overwrite the appropriate word in the half-block
                            s0_burstbegin_reg = 1'b1;
                            s0_size_reg = 10'h001;
                            s0_addr_reg = {{4'b0000},sys_addr_i[23:3]};
                            sub_word_reg = sys_addr_i[2:0];
                            s0_read_req_reg = 1'b1;
                            flag_write = 2'b00;
                            state = `ST_DDR3_IO_BUFFER_WRITE;
                        end
                    end
                    // block request
                    else begin
                        // block read
                        if (!sys_rw_i) begin
                            flag_block = 2'b00;
                            s0_burstbegin_reg = 1'b1;
                            s0_size_reg = 10'h001;
                            s0_read_req_reg = 1'b1;
                            s0_addr_reg = {{4'b0000},sys_addr_i[23:3]};
                            state = `ST_DDR3_IO_BUFFER_READ_BLOCK;
                        end
                        // block write
                        else begin
                            flag_block = 2'b00;
                            s0_addr_reg = {{4'b0000},sys_addr_i[23:3]} - 1'b1; // auto increments in next state
                            state = `ST_DDR3_IO_BUFFER_WRITE_BLOCK;
                        end
                    end
                end
            end
            `ST_DDR3_IO_BUFFER_READ: begin
                //sys_ready_reg = 1'b0;
                if (s0_rdata_valid) begin
                    case(sub_word_reg)
                        3'b000: tx_buffer[write_ptr] = s0_rdata[31:0];
                        3'b001: tx_buffer[write_ptr] = s0_rdata[63:32];
                        3'b010: tx_buffer[write_ptr] = s0_rdata[95:64];
                        3'b011: tx_buffer[write_ptr] = s0_rdata[127:96];
                        3'b100: tx_buffer[write_ptr] = s0_rdata[159:128];
                        3'b101: tx_buffer[write_ptr] = s0_rdata[191:160];
                        3'b110: tx_buffer[write_ptr] = s0_rdata[223:192];
                        3'b111: tx_buffer[write_ptr] = s0_rdata[255:224];
                    endcase
                    write_ptr = write_ptr + 1'b1;
                    n_tx = n_tx + 1'b1;
                    //sys_done_reg = 1'b1;
                    delay_reg = 4;
                    //state = `ST_DDR3_IO_BUFFER_IDLE;
                    state = `ST_WAIT_CLEAR;
                end
            end
            `ST_DDR3_IO_BUFFER_WRITE: begin
                //sys_ready_reg = 1'b0;
                // writing is multistep process - first replace the necessary word, then wait for the write to complete
                case(flag_write)
                    // store the half block
                    2'b00: begin
                        if (s0_rdata_valid) begin
                            flag_write = 2'b01;
                            s0_wdata_reg = s0_rdata;
                        end
                    end
                    // request the writeback
                    2'b01: begin
                        if (s0_ready) begin
                            flag_write = 2'b10;
                            s0_burstbegin_reg = 1'b1;
                            s0_write_req_reg = 1'b1;
                            s0_size_reg = 10'h001;
                            case(sub_word_reg)
                                3'b000: s0_wdata_reg = {s0_wdata_reg[255:32],rx_buffer[read_ptr]};
                                3'b001: s0_wdata_reg = {s0_wdata_reg[255:64],rx_buffer[read_ptr],s0_wdata_reg[31:0]};
                                3'b010: s0_wdata_reg = {s0_wdata_reg[255:96],rx_buffer[read_ptr],s0_wdata_reg[63:0]};
                                3'b011: s0_wdata_reg = {s0_wdata_reg[255:128],rx_buffer[read_ptr],s0_wdata_reg[95:0]};
                                3'b100: s0_wdata_reg = {s0_wdata_reg[255:160],rx_buffer[read_ptr],s0_wdata_reg[127:0]};
                                3'b101: s0_wdata_reg = {s0_wdata_reg[255:192],rx_buffer[read_ptr],s0_wdata_reg[159:0]};
                                3'b110: s0_wdata_reg = {s0_wdata_reg[255:224],rx_buffer[read_ptr],s0_wdata_reg[191:0]};
                                3'b111: s0_wdata_reg = {rx_buffer[read_ptr],s0_wdata_reg[223:0]};
                            endcase
                            read_ptr = read_ptr + 1'b1;
                            n_rx = n_rx - 1'b1;
                        end
                    end
                    // wait for success indicator (ready goes high)
                    2'b10: begin
                        flag_write = 2'b00;
                        //sys_done_reg = 1'b1;
                        state = `ST_WAIT_CLEAR;

                        /*if (sys_clear_i) begin
                            sys_done_reg = 1'b0;
                            sys_ready_reg = s0_ready;
                            flag_write = 2'b00;
                            state = `ST_DDR3_IO_BUFFER_IDLE;
                        end*/
                    end
                endcase


            end

            `ST_DDR3_IO_BUFFER_READ_BLOCK: begin
                //sys_done_reg = 1'b0;
                //sys_ready_reg = 1'b0;

                case(flag_block)
                    // get first half block
                    2'b00: begin
                        if (s0_rdata_valid) begin
                            tx_buffer[write_ptr] = s0_rdata[31:0];
                            tx_buffer[write_ptr+3'b001] = s0_rdata[63:32];
                            tx_buffer[write_ptr+3'b010] = s0_rdata[95:64];
                            tx_buffer[write_ptr+3'b011] = s0_rdata[127:96];
                            tx_buffer[write_ptr+3'b100] = s0_rdata[159:128];
                            tx_buffer[write_ptr+3'b101] = s0_rdata[191:160];
                            tx_buffer[write_ptr+3'b110] = s0_rdata[223:192];
                            tx_buffer[write_ptr+3'b111] = s0_rdata[255:224];
                            flag_block = 2'b01;
                            write_ptr = write_ptr + 4'b1000;
                            n_tx = n_tx + 4'b1000;
                        end
                    end
                    // request second half
                    2'b01: begin
                        if (s0_ready) begin
                            flag_block = 2'b10;
                            s0_burstbegin_reg = 1'b1;
                            s0_read_req_reg = 1'b1;
                            s0_size_reg = 10'h001;
                            s0_addr_reg = s0_addr_reg + 1'b1;
                        end
                    end
                    // get second half block
                    2'b10: begin
                        if (s0_rdata_valid) begin
                            tx_buffer[write_ptr] = s0_rdata[31:0];
                            tx_buffer[write_ptr+3'b001] = s0_rdata[63:32];
                            tx_buffer[write_ptr+3'b010] = s0_rdata[95:64];
                            tx_buffer[write_ptr+3'b011] = s0_rdata[127:96];
                            tx_buffer[write_ptr+3'b100] = s0_rdata[159:128];
                            tx_buffer[write_ptr+3'b101] = s0_rdata[191:160];
                            tx_buffer[write_ptr+3'b110] = s0_rdata[223:192];
                            tx_buffer[write_ptr+3'b111] = s0_rdata[255:224];
                            flag_block = 2'b11;
                            write_ptr = write_ptr + 4'b1000;
                            n_tx = n_tx + 4'b1000;

                            
                        end
                    end
                    2'b11: begin
                        flag_block = 2'b00;
                        //sys_done_reg = 1'b1;
                        state = `ST_WAIT_CLEAR;

                        //sys_done_reg = 1'b1;
                        /*if (sys_clear_i) begin
                            flag_block = 2'b00;
                            sys_done_reg = 1'b0;
                            sys_ready_reg = s0_ready;
                            state = `ST_DDR3_IO_BUFFER_IDLE;
                        end*/
                    end
                    // 
                endcase
            end
            `ST_DDR3_IO_BUFFER_WRITE_BLOCK: begin
                //sys_ready_reg = 1'b0;
                //sys_done_reg = 1'b0;
                case(flag_block)
                    2'b00, 2'b01: begin
                        if (n_rx >= 5'b01000) begin
                            if (s0_ready) begin
                                flag_block = flag_block + 1'b1;
                                s0_burstbegin_reg = 1'b1;
                                s0_size_reg = 10'h001;
                                s0_write_req_reg = 1'b1;
                                s0_addr_reg = s0_addr_reg + 1'b1;
                                s0_wdata_reg = {rx_buffer[read_ptr+3'b111], rx_buffer[read_ptr+3'b110],
                                                rx_buffer[read_ptr+3'b101], rx_buffer[read_ptr+3'b100],
                                                rx_buffer[read_ptr+3'b011], rx_buffer[read_ptr+3'b010],
                                                rx_buffer[read_ptr+3'b001], rx_buffer[read_ptr+3'b000]};
                                read_ptr = read_ptr + 4'b1000;
                                n_rx = n_rx - 4'b1000;
                            end
                        end
                    end
                    2'b10: begin
                        //sys_done_reg = 1'b1;
                        flag_block = 2'b00;
                        state = `ST_WAIT_CLEAR;
                        //sys_ready_reg = 1'b0;
                        //sys_done_reg = 1'b1;
                        //if (sys_clear_i) begin
                        //if (s0_ready) begin
                            /*sys_ready_reg = s0_ready;
                            sys_done_reg = 1'b0;
                            flag_block = 2'b00;
                            state = `ST_DDR3_IO_BUFFER_IDLE;*/
                        //end
                    end
                endcase
            end

            `ST_WAIT_CLEAR: begin
                sys_done_reg = 1'b1;                // for a one word read there has to be a complete word in the buffer with
                                                    // valid_o driving high, that is why done must go high here
                if (sys_clear_i) begin
                    sys_done_reg = 1'b0;
                    state = `ST_DDR3_IO_BUFFER_IDLE;
                    // delay_reg = 4'b1000;
                    delay_reg = 4'b0010;
                end
            end

        endcase // case (state)

        end // delay

        // tx_buffer logic
        // ---------------------------------------------------------
        if (n_tx > 5'b00000) begin
            //if (tx_buffer_beta_delay_reg) begin
            //    tx_buffer_beta_delay_reg = 1'b0;
                n_tx = n_tx - 1'b1;                 // decrement number of entries
                sys_valid_reg = 1'b1;               // valid high so data is latched by receiver
                sys_data_reg = tx_buffer[tx_ptr];   // put data on bus
                tx_ptr = tx_ptr + 1'b1;             // point to next valid location
            //end
            //else begin
            //    tx_buffer_beta_delay_reg = 1'b1;
            //end
        end
    end
end

endmodule 