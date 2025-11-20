//==============================================================================
// File: async_fifo_tb.sv
// Description: Complete testbench for async FIFO - ModelSim compatible
//==============================================================================

`timescale 1ns/1ps

module async_fifo_tb;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;
    parameter DEPTH = 1 << ADDR_WIDTH;
    parameter WCLK_PERIOD = 10;
    parameter RCLK_PERIOD = 20;
    
    // Signals
    logic                   wclk;
    logic                   rclk;
    logic                   wrst_n;
    logic                   rrst_n;
    logic                   winc;
    logic                   rinc;
    logic [DATA_WIDTH-1:0]  wdata;
    logic [DATA_WIDTH-1:0]  rdata;
    logic                   wfull;
    logic                   rempty;
    logic [ADDR_WIDTH:0]    waddr;
    logic [ADDR_WIDTH:0]    raddr;
    
    // Test variables
    int test_num;
    int error_count;
    int pass_count;
    logic [DATA_WIDTH-1:0] write_queue[$];
    logic [DATA_WIDTH-1:0] read_queue[$];
    
    //==========================================================================
    // Clock Generation
    //==========================================================================
    initial begin
        wclk = 0;
        forever #(WCLK_PERIOD/2) wclk = ~wclk;
    end
    
    initial begin
        rclk = 0;
        forever #(RCLK_PERIOD/2) rclk = ~rclk;
    end
    
    //==========================================================================
    // DUT Instantiation
    //==========================================================================
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .SYNC_STAGES(2)
    ) dut (
        .wclk   (wclk),
        .wrst_n (wrst_n),
        .winc   (winc),
        .wdata  (wdata),
        .wfull  (wfull),
        .waddr  (waddr),
        .rclk   (rclk),
        .rrst_n (rrst_n),
        .rinc   (rinc),
        .rdata  (rdata),
        .rempty (rempty),
        .raddr  (raddr)
    );
    
    //==========================================================================
    // Waveform Dump
    //==========================================================================
    initial begin
        $dumpfile("async_fifo_tb.vcd");
        $dumpvars(0, async_fifo_tb);
    end
    
    //==========================================================================
    // Test Stimulus
    //==========================================================================
    initial begin
        // Initialize
        test_num = 0;
        error_count = 0;
        pass_count = 0;
        wrst_n = 0;
        rrst_n = 0;
        winc = 0;
        rinc = 0;
        wdata = 0;
        
        // Display test header
        $display("\n");
        $display("================================================================================");
        $display("                    ASYNC FIFO TESTBENCH START");
        $display("================================================================================");
        $display("DATA_WIDTH = %0d, ADDR_WIDTH = %0d, DEPTH = %0d", DATA_WIDTH, ADDR_WIDTH, DEPTH);
        $display("WCLK = %0d MHz, RCLK = %0d MHz", 1000/WCLK_PERIOD, 1000/RCLK_PERIOD);
        $display("================================================================================\n");
        
        // Reset
        apply_reset();
        
        // Run all tests
        test_1_basic_write_read();
        test_2_fill_empty();
        test_3_full_flag();
        test_4_empty_flag();
        test_5_wrap_around();
        test_6_random_write_read();
        test_7_back_to_back();
        test_8_fast_write_slow_read();
        test_9_slow_write_fast_read();
        test_10_burst_operations();
        test_11_corner_cases();
        test_12_stress_test();
        
        // Final report
        final_report();
        
        // End simulation
        #1000;
        $finish;
    end
    
    //==========================================================================
    // Reset Task
    //==========================================================================
    task apply_reset();
        $display("[%0t] Applying Reset...", $time);
        wrst_n = 0;
        rrst_n = 0;
        winc = 0;
        rinc = 0;
        repeat(10) @(posedge wclk);
        repeat(10) @(posedge rclk);
        wrst_n = 1;
        rrst_n = 1;
        repeat(5) @(posedge wclk);
        repeat(5) @(posedge rclk);
        $display("[%0t] Reset Complete\n", $time);
    endtask
    
    //==========================================================================
    // Write Task
    //==========================================================================
    task write_data(input logic [DATA_WIDTH-1:0] data);
        @(posedge wclk);
        if (!wfull) begin
            winc = 1;
            wdata = data;
            write_queue.push_back(data);
            $display("[%0t] Write: Data=0x%02h, Full=%0b", $time, data, wfull);
        end else begin
            winc = 0;
            $display("[%0t] Write: FIFO FULL - Cannot write 0x%02h", $time, data);
        end
        @(posedge wclk);
        winc = 0;
    endtask
    
    //==========================================================================
    // Read Task
    //==========================================================================
    task read_data(output logic [DATA_WIDTH-1:0] data);
        @(posedge rclk);
        if (!rempty) begin
            rinc = 1;
            @(posedge rclk);
            data = rdata;
            rinc = 0;
            read_queue.push_back(data);
            $display("[%0t] Read: Data=0x%02h, Empty=%0b", $time, data, rempty);
        end else begin
            rinc = 0;
            data = 'x;
            $display("[%0t] Read: FIFO EMPTY - Cannot read", $time);
        end
    endtask
    
    //==========================================================================
    // Verification Task
    //==========================================================================
    task verify_data();
        int num_mismatches;
        int num_correct;
        logic [DATA_WIDTH-1:0] expected_data;
        logic [DATA_WIDTH-1:0] actual_data;
        
        num_mismatches = 0;
        num_correct = 0;
        
        if (write_queue.size() != read_queue.size()) begin
            $display("ERROR: Write queue size (%0d) != Read queue size (%0d)", 
                     write_queue.size(), read_queue.size());
            error_count++;
            return;
        end
        
        while (write_queue.size() > 0) begin
            expected_data = write_queue.pop_front();
            actual_data = read_queue.pop_front();
            
            if (expected_data === actual_data) begin
                num_correct = num_correct + 1;
            end else begin
                $display("ERROR: Data mismatch! Expected=0x%02h, Got=0x%02h", 
                         expected_data, actual_data);
                num_mismatches = num_mismatches + 1;
            end
        end
        
        if (num_mismatches == 0 && num_correct > 0) begin
            $display("PASS: All %0d data verified correctly", num_correct);
            pass_count = pass_count + 1;
        end else if (num_mismatches > 0) begin
            $display("FAIL: %0d mismatches found", num_mismatches);
            error_count = error_count + 1;
        end
    endtask
    
    //==========================================================================
    // Test 1: Basic Write and Read
    //==========================================================================
    task test_1_basic_write_read();
        logic [DATA_WIDTH-1:0] read_val;
        
        test_num = test_num + 1;
        $display("\n================================================================================");
        $display("TEST %0d: Basic Write and Read", test_num);
        $display("================================================================================");
        
        write_data(8'hAA);
        write_data(8'h55);
        write_data(8'hF0);
        write_data(8'h0F);
        
        repeat(10) @(posedge rclk);
        
        read_data(read_val);
        read_data(read_val);
        read_data(read_val);
        read_data(read_val);
        
        verify_data();
        
        $display("================================================================================\n");
    endtask
    
    //==========================================================================
    // Test 2: Fill and Empty FIFO
    //==========================================================================
    task test_2_fill_empty();
        logic [DATA_WIDTH-1:0] read_val;
        int i;
        
        test_num = test_num + 1;
        $display("\n================================================================================");
        $display("TEST %0d: Fill and Empty FIFO", test_num);
        $display("================================================================================");
        
        $display("Filling FIFO with %0d entries...", DEPTH);
        for (i = 0; i < DEPTH; i = i + 1) begin
            write_data(i[DATA_WIDTH-1:0]);
        end
        
        repeat(10) @(posedge rclk);
        
        $display("Emptying FIFO...");
        for (i = 0; i < DEPTH; i = i + 1) begin
            read_data(read_val);
        end
        
        verify_data();
        
        $display("================================================================================\n");
    endtask
    
    //==========================================================================
    // Test 3: Full Flag Test
    //==========================================================================
    task test_3_full_flag();
        int i;
        logic [DATA_WIDTH-1:0] dummy;
        
        test_num = test_num + 1;
        $display("\n================================================================================");
        $display("TEST %0d: Full Flag Test", test_num);
        $display("================================================================================");
        
        write_queue.delete();
        read_queue.delete();
        
        $display("Writing until FIFO is full...");
        for (i = 0; i < DEPTH + 5; i = i + 1) begin
            write_data(8'h10 + i[7:0]);
            if (wfull) begin
                $display("FIFO is FULL at write #%0d", i);
                break;
            end
        end
        
        $display("Attempting to write when full...");
        write_data(8'hFF);
        
        if (wfull) begin
            $display("PASS: Full flag is working correctly");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Full flag not asserted");
            error_count = error_count + 1;
        end
        
        repeat(10) @(posedge rclk);
        for (i = 0; i < DEPTH; i = i + 1) begin
            read_data(dummy);
        end
        
        $display("================================================================================\n");
    endtask
    
    //==========================================================================
    // Test 4: Empty Flag Test
    //==========================================================================
    task test_4_empty_flag();
        logic [DATA_WIDTH-1:0] read_val;
        int i;
        
        test_num = test_num + 1;
        $display("\n================================================================================");
        $display("TEST %0d: Empty Flag Test", test_num);
        $display("================================================================================");
        
        write_queue.delete();
        read_queue.delete();
        
        for (i = 0; i < 5; i = i + 1) begin
            write_data(8'h20 + i[7:0]);
        end
        
        repeat(10) @(posedge rclk);
        
        $display("Reading until FIFO is empty...");
        for (i = 0; i < 10; i = i + 1) begin
            read_data(read_val);
            if (rempty) begin
                $display("FIFO is EMPTY at read #%0d", i);
                break;
            end
        end
        
        $display("Attempting to read when empty...");
        read_data(read_val);
        
        if (rempty) begin
            $display("PASS: Empty flag is working correctly");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Empty flag not asserted");
            error_count = error_count + 1;
        end
        
        $display("================================================================================\n");
    endtask
    
    //==========================================================================
    // Test 5: Wrap Around Test
    //==========================================================================
    task test_5_wrap_around();
        logic [DATA_WIDTH-1:0] read_val;
        int i, j;
        
        test_num = test_num + 1;
        $display("\n================================================================================");
        $display("TEST %0d: Wrap Around Test", test_num);
        $display("================================================================================");
        
        for (j = 0; j < 3; j = j + 1) begin
            $display("Cycle %0d:", j+1);
            
            for (i = 0; i < DEPTH; i = i + 1) begin
                write_data(8'h30 + i[7:0] + (j * 16));
            end
            
            repeat(10) @(posedge rclk);
            
            for (i = 0; i < DEPTH; i = i + 1) begin
                read_data(read_val);
            end
            
            
        end
        verify_data();
        
        $display("================================================================================\n");
    endtask
    
    //==========================================================================
    // Test 6: Random Write and Read
    //==========================================================================
    task test_6_random_write_read();
        logic [DATA_WIDTH-1:0] read_val;
        int i, num_ops;
        int write_count, read_count;
        
        test_num = test_num + 1;
        $display("\n================================================================================");
        $display("TEST %0d: Random Write and Read", test_num);
        $display("================================================================================");
        
        write_count = 0;
        read_count = 0;
        num_ops = 50;
        
        fork
            begin
                for (i = 0; i < num_ops; i = i + 1) begin
                    if ($urandom_range(0, 1) == 1) begin
                        write_data($urandom_range(0, 255));
                        write_count = write_count + 1;
                    end
                    repeat($urandom_range(1, 3)) @(posedge wclk);
                end
            end
            
            begin
                repeat(20) @(posedge rclk);
                for (i = 0; i < num_ops; i = i + 1) begin
                    if ($urandom_range(0, 1) == 1 && !rempty) begin
                        read_data(read_val);
                        read_count = read_count + 1;
                    end
                    repeat($urandom_range(1, 3)) @(posedge rclk);
                end
            end
        join
        
        repeat(20) @(posedge rclk);
        while (!rempty) begin
            read_data(read_val);
            read_count = read_count + 1;
        end
        
        $display("Write Count: %0d, Read Count: %0d", write_count, read_count);
        verify_data();
        
        $display("================================================================================\n");
    endtask
    
    //==========================================================================
    // Test 7: Back-to-Back Operations
    //==========================================================================
    task test_7_back_to_back();
        logic [DATA_WIDTH-1:0] read_val;
        int i;
        
        test_num = test_num + 1;
        $display("\n================================================================================");
        $display("TEST %0d: Back-to-Back Operations", test_num);
        $display("================================================================================");
        
        $display("Back-to-back writes...");
        for (i = 0; i < 8; i = i + 1) begin
            write_data(8'h40 + i[7:0]);
        end
        
        repeat(15) @(posedge rclk);
        
        $display("Back-to-back reads...");
        for (i = 0; i < 8; i = i + 1) begin
            read_data(read_val);
        end
        
        verify_data();
        
        $display("================================================================================\n");
    endtask
    
    //==========================================================================
    // Test 8: Fast Write, Slow Read
    //==========================================================================
    task test_8_fast_write_slow_read();
        logic [DATA_WIDTH-1:0] read_val;
        int i;
        
        test_num = test_num + 1;
        $display("\n================================================================================");
        $display("TEST %0d: Fast Write, Slow Read", test_num);
        $display("================================================================================");
        
        fork
            begin
                for (i = 0; i < 12; i = i + 1) begin
                    write_data(8'h50 + i[7:0]);
                end
            end
            
            begin
                repeat(30) @(posedge rclk);
                for (i = 0; i < 12; i = i + 1) begin
                    read_data(read_val);
                    repeat(2) @(posedge rclk);
                end
            end
        join
        
        verify_data();
        
        $display("================================================================================\n");
    endtask
    
    //==========================================================================
    // Test 9: Slow Write, Fast Read
    //==========================================================================
    task test_9_slow_write_fast_read();
        logic [DATA_WIDTH-1:0] read_val;
        int i;
        
        test_num = test_num + 1;
        $display("\n================================================================================");
        $display("TEST %0d: Slow Write, Fast Read", test_num);
        $display("================================================================================");
        
        fork
            begin
                for (i = 0; i < 10; i = i + 1) begin
                    write_data(8'h60 + i[7:0]);
                    repeat(3) @(posedge wclk);
                end
            end
            
            begin
                repeat(50) @(posedge rclk);
                for (i = 0; i < 10; i = i + 1) begin
                    if (!rempty) read_data(read_val);
                end
            end
        join
        
        repeat(10) @(posedge rclk);
        while (!rempty) read_data(read_val);
        
        verify_data();
        
        $display("================================================================================\n");
    endtask
    
    //==========================================================================
    // Test 10: Burst Operations
    //==========================================================================
    task test_10_burst_operations();
        logic [DATA_WIDTH-1:0] read_val;
        int i, j;
        
        test_num = test_num + 1;
        $display("\n================================================================================");
        $display("TEST %0d: Burst Operations", test_num);
        $display("================================================================================");
        
        for (j = 0; j < 3; j = j + 1) begin
            $display("Burst %0d:", j+1);
            
            for (i = 0; i < 8; i = i + 1) begin
                write_data(8'h70 + i[7:0] + (j * 8));
            end
            
            repeat(20) @(posedge rclk);
            
            for (i = 0; i < 8; i = i + 1) begin
                read_data(read_val);
            end
        end
        
        verify_data();
        
        $display("================================================================================\n");
    endtask
    
    //==========================================================================
    // Test 11: Corner Cases
    //==========================================================================
    task test_11_corner_cases();
        logic [DATA_WIDTH-1:0] read_val;
        int i;
        
        test_num = test_num + 1;
        $display("\n================================================================================");
        $display("TEST %0d: Corner Cases", test_num);
        $display("================================================================================");
        
        $display("Testing special data patterns...");
        write_data(8'h00);
        write_data(8'hFF);
        write_data(8'hAA);
        write_data(8'h55);
        write_data(8'hF0);
        write_data(8'h0F);
        
        repeat(15) @(posedge rclk);
        
        for (i = 0; i < 6; i = i + 1) begin
            read_data(read_val);
        end
        
        verify_data();
        
        $display("================================================================================\n");
    endtask
    
    //==========================================================================
    // Test 12: Stress Test
    //==========================================================================
    task test_12_stress_test();
        logic [DATA_WIDTH-1:0] read_val;
        int i;
        int total_writes, total_reads;
        
        test_num = test_num + 1;
        $display("\n================================================================================");
        $display("TEST %0d: Stress Test", test_num);
        $display("================================================================================");
        
        total_writes = 0;
        total_reads = 0;
        
        fork
            begin
                for (i = 0; i < 100; i = i + 1) begin
                    if (!wfull) begin
                        write_data($urandom);
                        total_writes = total_writes + 1;
                    end
                    if ($urandom_range(0, 3) > 0) @(posedge wclk);
                end
            end
            
            begin
                repeat(50) @(posedge rclk);
                for (i = 0; i < 100; i = i + 1) begin
                    if (!rempty) begin
                        read_data(read_val);
                        total_reads = total_reads + 1;
                    end
                    if ($urandom_range(0, 3) > 0) @(posedge rclk);
                end
            end
        join
        
        repeat(50) @(posedge rclk);
        while (!rempty) begin
            read_data(read_val);
            total_reads = total_reads + 1;
        end
        
        $display("Total Writes: %0d, Total Reads: %0d", total_writes, total_reads);
        verify_data();
        
        $display("================================================================================\n");
    endtask
    
    //==========================================================================
    // Final Report
    //==========================================================================
    task final_report();
        $display("\n");
        $display("================================================================================");
        $display("                        FINAL TEST REPORT");
        $display("================================================================================");
        $display("Total Tests:    %0d", test_num);
        $display("Tests Passed:   %0d", pass_count);
        $display("Tests Failed:   %0d", error_count);
        $display("================================================================================");
        
        if (error_count == 0) begin
            $display("                    *** ALL TESTS PASSED ***");
        end else begin
            $display("                    *** SOME TESTS FAILED ***");
        end
        
        $display("================================================================================\n");
    endtask
    
    //==========================================================================
    // Timeout Watchdog
    //==========================================================================
    initial begin
        #50ms;
        $display("\n*** ERROR: Simulation timeout! ***\n");
        $finish;
    end

endmodule