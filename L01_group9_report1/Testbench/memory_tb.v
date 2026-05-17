// =============================================================================
// Testbench: Memory (bidirectional port) - Updated with TC1-TC5 & Detailed Display
// =============================================================================
`timescale 1ns/1ps

module memory_tb;
    reg         clk, rd, wr;
    reg  [31:0] addr;
    wire [31:0] data;

    // Driver for bidirectional port
    reg  [31:0] data_driver;
    reg         data_drive_en;
    assign data = data_drive_en ? data_driver : 32'bz;

    memory uut (
        .clk(clk), .rd(rd), .wr(wr),
        .addr(addr), .data(data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer pass_count = 0;
    integer fail_count = 0;

    task check_read;
        input [31:0] expected;
        input [63:0] test_name;
        begin
            if (data === expected) begin
                $display("[PASS] %0s: [rd=%b wr=%b addr=%0d] data = %08Xh", 
                         test_name, rd, wr, addr, data);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s: [rd=%b wr=%b addr=%0d] expected %08Xh, got %08Xh", 
                         test_name, rd, wr, addr, expected, data);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("memory_tb.vcd");
        $dumpvars(0, memory_tb);

        $display("Starting Memory Testbench...\n");
        // Initialize
        rd = 0; wr = 0; addr = 0; data_driver = 0; data_drive_en = 0;

        // --- TC1: Write Data ---
        // TC1.1 | rd=0 | wr=1 | addr=10 | data=0xa5a5a5a5
        @(posedge clk); #1;
        rd = 0; wr = 1; addr = 32'd10; data_driver = 32'ha5a5a5a5; data_drive_en = 1;
        
        // TC1.2 | rd=0 | wr=1 | addr=20 | data=0x12345678
        @(posedge clk); #1;
        rd = 0; wr = 1; addr = 32'd20; data_driver = 32'h12345678; data_drive_en = 1;

        @(posedge clk); #1;
        wr = 0; data_drive_en = 0;

        // --- TC2: Read Data ---
        // TC2.1 | rd=1 | wr=0 | addr=10 | data=0xa5a5a5a5
        rd = 1; wr = 0; addr = 32'd10;
        @(posedge clk); #1;
        check_read(32'ha5a5a5a5, "TC2.1   ");

        // TC2.2 | rd=1 | wr=0 | addr=20 | data=0x12345678
        rd = 1; wr = 0; addr = 32'd20;
        @(posedge clk); #1;
        check_read(32'h12345678, "TC2.2   ");

        // --- TC3: High Impedance Check ---
        // TC3 | rd=0 | wr=0 | addr=10 | data=0xzzzzzzzz
        rd = 0; wr = 0; addr = 32'd10; data_drive_en = 0;
        @(posedge clk); #1;
        check_read(32'hzzzzzzzz, "TC3     ");

        // --- TC4: Conflict Prevention ---
        // TC4 | rd=1 | wr=1 | addr=10 | data=0xzzzzzzzz
        rd = 1; wr = 1; addr = 32'd10; data_drive_en = 0;
        @(posedge clk); #1;
        check_read(32'hzzzzzzzz, "TC4     ");

        // --- TC5: Data Persistence ---
        // TC5 | rd=1 | wr=0 | addr=10 | data=0xa5a5a5a5
        rd = 1; wr = 0; addr = 32'd10; data_drive_en = 0;
        @(posedge clk); #1;
        check_read(32'ha5a5a5a5, "TC5     ");

        // --- DONE ---
        @(posedge clk); #1;
        rd = 0; wr = 0; data_drive_en = 0;
        #1; 
        $display("\n===== Memory Testbench: %0d PASSED, %0d FAILED =====", pass_count, fail_count);
        $finish;
    end
endmodule