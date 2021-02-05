
`define DELAY 2'h0
`define WRITE 2'h1
`define READ  2'h2

module ddr3_pattern_gen (
	// Outputs 
	output reg         avl_burstbegin,
	output reg [24:0]  avl_addr,
	output reg [255:0] avl_wdata, 
	output reg         avl_read_req,
	output reg         avl_write_req,
	output     [9:0]   avl_size,
	
	// Inputs
	input              risc_clk,
	input              reset_n,
	
	input              avl_ready,
	input              avl_rdata_valid,
	input      [255:0] avl_rdata,
	input              local_init_done,
	input              local_cal_success,
    
    input              test_mode,
    input              test_pass,
    input      [31:0]  pass_cnt
);

reg  [9:0]  addr;
reg         block;       // Block write?
reg  [3:0]  delay;
reg  [4:0]  delay_lfsr;  // Randomize delays but allows for 0
reg  [3:0]  read_count;
reg         read;        // Only read once previous read checked
reg         rw_mode;     // 0 = read, 1 = write
reg  [1:0]  size;
reg  [1:0]  state;
reg  [3:0]  write_count; // Read buffer has 8 addresses
reg  [3:0]  write_lfsr;

reg         tap254, tap251, tap246; // For wdata
reg         tap9, tap7, tap6;       // For address
reg         tap4, tap3, tap2;       // For delay
reg         tap3_;                  // For write count

reg  [9:0]  read_addr [7:0];  // Written addresses to be read later
reg         read_block[7:0]; // Whether it was a block 
                                                          
assign avl_size = {8'h0,size};  // Only possible sizes are 2 and 1

// Data and address LFSRs
always @(negedge risc_clk or negedge reset_n)
begin
    if (!reset_n)
    begin
        avl_wdata  = 256'h1;
        addr       = 10'h1;
        delay_lfsr = 4'h1;
        write_lfsr = 4'h1;
    end
    else
    begin
        tap254     = avl_wdata[254] ^ avl_wdata[0];
        tap251     = avl_wdata[251] ^ avl_wdata[0];
        tap246     = avl_wdata[246] ^ avl_wdata[0];
        avl_wdata  = {avl_wdata[0],avl_wdata[255],tap254,
                      avl_wdata[253:252],tap251,avl_wdata[250:247],tap246,
                      avl_wdata[245:1]};
        
        tap9       = addr[9] ^ addr[0];
        tap7       = addr[7] ^ addr[0];
        tap6       = addr[6] ^ addr[0];
        addr       = {addr[0],tap9,addr[8],tap7,tap6,addr[5:1]};  
 
        tap4       = delay_lfsr[4] ^ delay_lfsr[0];
        tap3       = delay_lfsr[3] ^ delay_lfsr[0];
        tap2       = delay_lfsr[2] ^ delay_lfsr[0];      
        delay_lfsr = {delay_lfsr[0],tap4,tap3,tap2,delay_lfsr[1]};
        
        tap3_      = write_lfsr[3] ^ write_lfsr[0];
        write_lfsr = {write_lfsr[0],tap3_,write_lfsr[2:1]};
    end
end

// Control
always @(negedge risc_clk or negedge reset_n)
begin
    if (!reset_n)
    begin
        avl_read_req   <= 1'b0;
        avl_write_req  <= 1'b0;
        size           <= 2'h1;
        avl_burstbegin <= 1'b0; 
        
        block          <= 1'b0;   // Always start with a single
        delay          <= 4'h7;   // Always start with max delay
        read           <= 1'b1;
        read_count     <= 4'h8;
        rw_mode        <= 1'b1;   // Always start with a write
        state          <= `DELAY; // Start with a delay
        write_count    <= 4'h8;   // Start with max number of writes
	end
    else
    begin
        if (local_init_done && local_cal_success && avl_ready && test_mode)
        begin
            case(state)
            `DELAY: begin // Delay before a write, 0-7 clock cycles
                if (delay !== 4'h0)
                begin
                    avl_read_req   <= 1'b0;
                    avl_write_req  <= 1'b0;
                    avl_burstbegin <= 1'b0; 
                    
                    delay <= delay - 4'h1;
                end
                else
                begin                                      // End of delay
                    avl_read_req   <= 1'b0;
                    avl_write_req  <= 1'b0;
                    avl_burstbegin <= 1'b0;
                
                    delay <= delay_lfsr[4:1];                   // Next delay
                    
                    if (!rw_mode)                          // Read
                    begin
                        state <= `READ;
                    end
                    else                                   // Write
                    begin
                        if (delay_lfsr[1])                 // Do a block write
                        begin
                            block <= 1'b1;
                            size  <= 2'h3;
                        end
                        else
                        begin
                            block <= 1'b0;
                        end
                        state <= `WRITE;                        
                    end                    
                end
            end
            `WRITE: begin // Write new half-block or block
                if (write_count != 4'h0 && !block)         // Do another single write
                begin
                    avl_addr       <= {15'h0,addr};
                    avl_burstbegin <= 1'b1;                // Everything has BB
                    avl_write_req  <= 1'b1; 
                    size           <= 2'b1;
                    
                    read_addr[write_count-4'h1] <= addr;
                    read_block[write_count-4'h1] <= 1'b0;
                    write_count    <= write_count - 4'h1;
                    state          <= `DELAY;
                end
                else if (write_count != 4'h0 && block)     // Do another block write
                begin
                    avl_burstbegin <= 1'b1;                // Everything has BB
                    avl_write_req  <= 1'b1;
                    size           <= size - 2'h1;
                    
                    if (size == 2'h2)                      // End of block
                    begin
                        avl_addr    <= avl_addr + 25'h1;
                        write_count <= write_count - 4'h1;
                        state       <= `DELAY; 
                    end
                    else                                   // Beginning of block
                    begin
                        avl_addr    <= {15'h0,addr};
                        read_addr[write_count-4'h1]  <= addr;
                        read_block[write_count-4'h1] <= 1'b1;
                    end
                end
                else                                       // No more writes
                begin
                    rw_mode <= 1'b0;                       // Read mode
                    state   <= `DELAY;
                end
            end
            `READ: begin // Read back written half-block or block
                if (read_count != 4'h0 && read)            // Do another read
                begin
                    if (!read_block[read_count-4'h1])      // Not a block
                    begin
                        avl_addr <= {15'h0,read_addr[read_count-4'h1]};
                        avl_burstbegin <= 1'b1;            // Everything has BB
                        avl_read_req   <= 1'b1;
                        size           <= 2'h1;
                        
                        read           <= 1'h0;            // Have to wait
                    end
                    else                                   // A block
                    begin
                        avl_burstbegin <= 1'b1;                // Everything has BB
                        avl_read_req   <= 1'b1;
                        size           <= size - 2'h1;
                        
                        if (size == 2'h2)                      // End of block
                        begin
                            avl_addr    <= avl_addr + 25'h1;
                            read        <= 1'b0;
                        end
                        else                                   // Beginning of block
                        begin
                            avl_addr <= {15'h0,read_addr[read_count-4'h1]};
                        end
                    end
                end
                else if (read_count == 4'h0)               // No more reads
                begin
                    rw_mode     <= 1'b1;                   // Write mode
                    
                    write_count <= write_lfsr;             // Next set of read/writes
                    read_count  <= write_lfsr;
                    
                    state <= `DELAY;
                end
                else if (test_pass)                        // Read successful
                begin
                    read <= 1'b1;
                    read_count <= read_count - 4'h1;
                end
                else                                       // Waiting for test_pass
                begin
                    avl_burstbegin <= 1'b0;
                    avl_read_req   <= 1'b0;
                    size           <= 2'h3;
                end
            end
            default: begin
                delay <= delay_lfsr[4:1];
                state <= `DELAY;
            end
            endcase
        end
    end
end

endmodule 