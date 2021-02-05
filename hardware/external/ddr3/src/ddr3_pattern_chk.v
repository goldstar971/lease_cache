
module ddr3_pattern_chk (
	// Outputs 
    output reg    test_fail,
    output reg    test_pass,
    output reg [31:0] pass_cnt,
    output reg [7:0]  failures,
	
	// Inputs
	input         risc_clk,
	input         reset_n,
    
    input         avl_burstbegin,
	input [24:0]  avl_addr,
	input [255:0] avl_wdata, 
	input         avl_read_req,
	input         avl_write_req,
	input [9:0]   avl_size,
    
    input         avl_ready,
	input         avl_rdata_valid,
	input [255:0] avl_rdata,
	input         local_init_done,
	input         local_cal_success
);

reg  [9:0]   addr;
wire [255:0] check_bus;
reg  [255:0] data;
reg          write;

reg  [9:0]   base_addr;
reg          check;
reg          lock_base_addr;
reg  [9:0]   read_size;

reg          refresh; // Read may be split
reg  [5:0]   refresh_hold; // Give second half time

chk_ram check_ram (
    .address(addr),
	.clock(!risc_clk),
	.data(data),
	.wren(write),
	.q(check_bus)
);

always @(posedge risc_clk or negedge reset_n)
begin
    if (!reset_n)
    begin
        addr      <= 10'h0;
        check     <= 1'b0;
        data      <= 256'h0;
        failures  <= 8'h0;
        test_fail <= 1'b0;
        test_pass <= 1'b0;
        pass_cnt  <= 32'h0;
        write     <= 1'b0;
        
        lock_base_addr <= 1'b0;
        refresh        <= 1'b0;
        refresh_hold   <= 6'h3F;
    end
    else
    begin
        // Management
        if (avl_write_req)
        begin
            addr  <= avl_addr[9:0];
            data  <= avl_wdata;
            write <= avl_write_req;
        end
        else if (avl_read_req && avl_burstbegin && !lock_base_addr)
        begin
            base_addr <= avl_addr[9:0];
            read_size <= avl_size;
            
            if (avl_size !== 10'h1)
            begin
                lock_base_addr <= 1'b1;
            end
        end
        else if (avl_read_req && avl_burstbegin && lock_base_addr)
        begin
            lock_base_addr <= 1'b0;
        end
        else
        begin
            write <= 1'b0;
        end
        
        // Error Checking
        if (!avl_ready && avl_burstbegin)
        begin
            failures  <= failures + 8'h1;
            test_fail <= 1'b1;
        end
        
        test_pass <= 1'b0;
        if (avl_rdata_valid && !check)
        begin
            addr  <= base_addr;
            check <= 1'b1;
            data  <= avl_rdata;
        end
        else if (check && read_size !== 10'h0)
        begin
            if (data !== check_bus && !refresh)
            begin
                failures  <= failures + 8'h1;
                test_fail <= 1'b1;
            end
            else if (!refresh)
            begin
                if (read_size == 10'h1)
                begin
                    test_pass <= 1'b1;
                    pass_cnt <= pass_cnt + 32'h1;
                end
                else if (!avl_rdata_valid) // Burst but split
                begin
                    refresh <= 1'b1;
                end
            end
            else if (refresh_hold == 6'h0) // Refresh count ran out
            begin
                failures  <= failures + 8'h1;
                test_fail <= 1'b1;
            end
            
            if (read_size == 10'h1 && !refresh)
            begin
                check <= 1'b0;
            end
            else if (refresh)
            begin
                refresh_hold <= refresh_hold - 6'h1;
                
                if (avl_rdata_valid)
                begin
                    data  <= avl_rdata;
                    refresh <= 1'b0;
                    refresh_hold <= 6'h3F;
                end
            end
            else
            begin
                addr  <= addr + 10'h1;
                data  <= avl_rdata;
            end
            
            if (!refresh)
            begin
                read_size <= read_size - 10'h1;
            end
        end
        else if (read_size == 10'h0)
        begin
            check <= 1'b0;
        end
    end
end

endmodule
