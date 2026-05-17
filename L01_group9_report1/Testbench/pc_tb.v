// =============================================================================
// Testbench: Program Counter (Updated with full TC suite)
// =============================================================================
`timescale 1ns/1ps

module pc_tb;
    reg         clk, rst, ld_pc, inc_pc;
    reg  [31:0] load_data;
    wire [31:0] pc_out;

    pc uut (
        .clk(clk), .rst(rst), .ld_pc(ld_pc),
        .inc_pc(inc_pc), .load_data(load_data), .pc_out(pc_out)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    integer pass_count = 0;
    integer fail_count = 0;

    task check;
        input [31:0] expected;
        input [127:0] test_name; // Increased size for longer names
        begin
            if (pc_out === expected) begin
                $display("[PASS] %0s: pc_out = %0d", test_name, pc_out);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s: expected %0d, got %0d", test_name, expected, pc_out);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("pc_tb.vcd");
        $dumpvars(0, pc_tb);

        // --- TC1: RESET ---
        rst = 1; ld_pc = 0; inc_pc = 0; load_data = 32'b0;
        @(posedge clk); #1;
        check(32'd0, "TC1_RESET");

        // --- TC2: INCREMENT ---
        rst = 0; inc_pc = 1;
        @(posedge clk); #1; check(32'd1, "TC2_INC_1");
        @(posedge clk); #1; check(32'd2, "TC2_INC_2");
        @(posedge clk); #1; check(32'd3, "TC2_INC_3");

        // --- TC3: LOAD ---
        inc_pc = 0; ld_pc = 1; load_data = 32'd20;
        @(posedge clk); #1;
        check(32'd20, "TC3_LOAD_20");
        
        ld_pc = 0; // Stop loading
        @(posedge clk); #1;
        check(32'd20, "TC3_HOLD_AFTER_LD");

        // --- TC4: PRIORITY (RST > LD > INC) ---
        // Case: All signals high -> Should Reset
        rst = 1; ld_pc = 1; inc_pc = 1; load_data = 32'd99;
        @(posedge clk); #1;
        check(32'd0, "TC4_PRI_RST");

        // Case: LD and INC high -> Should Load
        rst = 0; ld_pc = 1; inc_pc = 1; load_data = 32'd99;
        @(posedge clk); #1;
        check(32'd99, "TC4_PRI_LD");

        // Case: Only INC high -> Should Increment
        ld_pc = 0; inc_pc = 1;
        @(posedge clk); #1;
        check(32'd100, "TC4_PRI_INC");

        // --- TC5: HOLD STATE ---
        rst = 0; ld_pc = 0; inc_pc = 0;
        @(posedge clk); #1; check(32'd100, "TC5_HOLD_1");
        @(posedge clk); #1; check(32'd100, "TC5_HOLD_2");

        // --- TC6: WRAP-AROUND (32-BIT) ---
        ld_pc = 1; load_data = 32'hFFFF_FFFF;
        @(posedge clk); #1;
        ld_pc = 0; inc_pc = 1;
        @(posedge clk); #1;
        check(32'd0, "TC6_WRAP_OVF");

        // --- TC7: JUMP & INCREMENT ---
        ld_pc = 1; load_data = 32'd1000;
        @(posedge clk); #1;
        ld_pc = 0; inc_pc = 1;
        @(posedge clk); #1; check(32'd1001, "TC7_JMP_INC1");
        @(posedge clk); #1; check(32'd1002, "TC7_JMP_INC2");

        // --- TC8: RESET FROM HIGH VALUE ---
        ld_pc = 1; load_data = 32'd2882396160;
        @(posedge clk); #1;
        rst = 1; ld_pc = 0; inc_pc = 0;
        @(posedge clk); #1;
        check(32'd0, "TC8_RST_HIGH");

        // --- TC9: DATA NOISE IMMUNITY ---
        rst = 0; ld_pc = 0; inc_pc = 1; load_data = 32'd2882396160;
        @(posedge clk); #1; // PC goes to 1
        load_data = 32'hFFFF_FFFF; // Data changes but ld_pc is low
        @(posedge clk); #1;
        check(32'd2, "TC9_NOISE_IMM");

        $display("\n===== PC Testbench: %0d PASSED, %0d FAILED =====", pass_count, fail_count);
        $finish;
    end
endmodule