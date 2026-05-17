// =============================================================================
// Testbench: Register (Updated with extended Display Info)
// =============================================================================
`timescale 1ns/1ps

module register_tb;
    reg         clk, rst, load;
    reg  [31:0] data_in;
    wire [31:0] data_out;

    register uut (
        .clk(clk), .rst(rst), .load(load),
        .data_in(data_in), .data_out(data_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer pass_count = 0;
    integer fail_count = 0;

    task check;
        input [31:0] expected;
        input [127:0] test_name;
        begin
            if (data_out === expected) begin
                $display("[PASS] %-7s | Input: [rst=%b, ld=%b, in=%0d] | Output: %0d", 
                         test_name, rst, load, data_in, data_out);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %-7s | Input: [rst=%b, ld=%b, in=%0d] | Expected: %0d, Got: %0d", 
                         test_name, rst, load, data_in, expected, data_out);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("register_tb.vcd");
        $dumpvars(0, register_tb);
        
         $display("Starting Register Testbench...\n");
        // --- TC1: System Reset ---
        rst = 1; load = 0; data_in = 0;
        @(posedge clk); #1;
        check(32'd0, "TC1");

        // --- TC2: Load Data (ALU Result) ---
        rst = 0; load = 1; data_in = 32'd150;
        @(posedge clk); #1;
        check(32'd150, "TC2.1");
        
        rst = 0; load = 1; data_in = 32'd300;
        @(posedge clk); #1;
        check(32'd300, "TC2.2");

        // --- TC3: Data Stability (Idle/Fetch) ---
        rst = 0; load = 0; data_in = 32'd999;
        @(posedge clk); #1;
        check(32'd300, "TC3.1");
        
        rst = 0; load = 0; data_in = 32'd999;
        @(posedge clk); #1;
        check(32'd300, "TC3.2");

        // --- TC4: Feedback to ALU ---
        rst = 0; load = 0; data_in = 32'd999;
        @(posedge clk); #1;
        check(32'd300, "TC4");

        // --- TC5: Interaction with Data Bus ---
        rst = 0; load = 1; data_in = 32'd500;
        @(posedge clk); #1;
        check(32'd500, "TC5.1");
        
        rst = 0; load = 0; data_in = 32'd500;
        @(posedge clk); #1;
        check(32'd500, "TC5.2");

        // --- TC6: Reset Priority Check ---
        rst = 1; load = 1; data_in = 32'd4444;
        @(posedge clk); #1;
        check(32'd0, "TC6.1");
        
        rst = 0; load = 1; data_in = 32'd4444;
        @(posedge clk); #1;
        check(32'd4444, "TC6.2");

        // --- TC7: Boundary Values ---
        rst = 0; load = 1; data_in = 32'hFFFFFFFF;
        @(posedge clk); #1;
        check(32'hFFFFFFFF, "TC7.1");
        
        rst = 0; load = 1; data_in = 32'd0;
        @(posedge clk); #1;
        check(32'd0, "TC7.2");

        // --- TC8: Rapid Toggling ---
        rst = 0; load = 1; data_in = 32'hAAAAAAAA;
        @(posedge clk); #1;
        check(32'hAAAAAAAA, "TC8.1");
        
        rst = 0; load = 1; data_in = 32'h55555555;
        @(posedge clk); #1;
        check(32'h55555555, "TC8.2");
        
        rst = 0; load = 0; data_in = 32'd305419896;
        @(posedge clk); #1;
        check(32'h55555555, "TC8.3");

        $display("\n===== Register Testbench: %0d PASSED, %0d FAILED =====", pass_count, fail_count);
        $finish;
        
    end
endmodule
