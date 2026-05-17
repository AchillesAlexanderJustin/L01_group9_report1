// =============================================================================
// Testbench: Address Mux (Final Anti-Racing Version)
// =============================================================================
`timescale 1ns/1ps

module addr_mux_tb;
    reg         sel;
    reg  [31:0] pc_addr, ir_addr;
    wire [31:0] addr_out;

    // Unit Under Test (Standard 32-bit)
    addr_mux #(.WIDTH(32)) uut (
        .sel(sel), .pc_addr(pc_addr),
        .ir_addr(ir_addr), .addr_out(addr_out)
    );

    // Module cho TC4 (Override WIDTH=16)
    wire [15:0] addr_out_16;
    reg  [15:0] pc_addr_16, ir_addr_16;
    addr_mux #(.WIDTH(16)) uut_16 (
        .sel(sel), .pc_addr(pc_addr_16),
        .ir_addr(ir_addr_16), .addr_out(addr_out_16)
    );

    integer pass_count = 0;
    integer fail_count = 0;

    // Task check cải tiến: Tránh racing và in rõ Input/Output
    task check;
        input [31:0] current_val;
        input [31:0] expected;
        input [31:0] in_pc;
        input [31:0] in_ir;
        input        in_sel;
        input [127:0] test_name;
        begin
            if (current_val === expected) begin
                $display("[PASS] %0s | In: sel=%b, pc=%0d, ir=%0d | Out: %0d", 
                          test_name, in_sel, in_pc, in_ir, current_val);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s | In: sel=%b, pc=%0d, ir=%0d | Exp %0d, Got %0d", 
                          test_name, in_sel, in_pc, in_ir, expected, current_val);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("addr_mux_tb.vcd");
        $dumpvars(0, addr_mux_tb);

        $display("--- Starting Address Mux Verification ---");

        // --- Original Testcases ---
        pc_addr = 32'd10; ir_addr = 32'd25; sel = 1;
        #1;
        check(addr_out, 32'd10, pc_addr, ir_addr, sel, "SEL_PC");

        sel = 0;
        #1;
        check(addr_out, 32'd25, pc_addr, ir_addr, sel, "SEL_IR");

        pc_addr = 32'd0; ir_addr = 32'd31; sel = 1;
        #1;
        check(addr_out, 32'd0, pc_addr, ir_addr, sel, "PC_0");

        sel = 0;
        #1;
        check(addr_out, 32'd31, pc_addr, ir_addr, sel, "IR_31");

        // --- TC1: Select pc_addr ---
        sel = 1; pc_addr = 32'd1000; ir_addr = 32'd2000;
        #1;
        check(addr_out, 32'd1000, pc_addr, ir_addr, sel, "TC1");

        // --- TC2: Select ir_addr ---
        sel = 0; pc_addr = 32'd1000; ir_addr = 32'd2000;
        #1;
        check(addr_out, 32'd2000, pc_addr, ir_addr, sel, "TC2");

        // --- TC3: Toggle sel ---
        pc_addr = 32'd5555; ir_addr = 32'd9999;
        sel = 1; #1;
        check(addr_out, 32'd5555, pc_addr, ir_addr, sel, "TC3.1");
        sel = 0; #1;
        check(addr_out, 32'd9999, pc_addr, ir_addr, sel, "TC3.2");
        sel = 1; #1;
        check(addr_out, 32'd5555, pc_addr, ir_addr, sel, "TC3.3");

        // --- TC4: Parameter Override (WIDTH=16) ---
        pc_addr_16 = 16'd500; ir_addr_16 = 16'd600;
        sel = 1; #1;
        check(addr_out_16, 32'd500, pc_addr_16, ir_addr_16, sel, "TC4.1");
        sel = 0; #1;  check(addr_out_16, 32'd600, pc_addr_16, ir_addr_16, sel, "TC4.2");

        // --- TC5: Stability Check ---
        pc_addr = 32'd7777; ir_addr = 32'd1234; sel = 1;
        #1;
        check(addr_out, 32'd7777, pc_addr, ir_addr, sel, "TC5.1");
        pc_addr = 32'd5678; ir_addr = 32'd8888; sel = 0;
        #1;
        check(addr_out, 32'd8888, pc_addr, ir_addr, sel, "TC5.2");

        // --- TC6: Edge Case Addresses ---
        pc_addr = 32'd0; ir_addr = 32'd4294967295;
        sel = 1; #1;
        check(addr_out, 32'd0, pc_addr, ir_addr, sel, "TC6.1");
        sel = 0; #1;
        check(addr_out, 32'd4294967295, pc_addr, ir_addr, sel, "TC6.2");

        // --- TC7: Async Response ---
        ir_addr = 32'd4294967295; sel = 1;
        pc_addr = 32'd1111; #1;
        check(addr_out, 32'd1111, pc_addr, ir_addr, sel, "TC7.1");
        pc_addr = 32'd2222; #1;
        check(addr_out, 32'd2222, pc_addr, ir_addr, sel, "TC7.2");
        pc_addr = 32'd3333; #1;
        check(addr_out, 32'd3333, pc_addr, ir_addr, sel, "TC7.3");

        $display("\n===== Address Mux Testbench: %0d PASSED, %0d FAILED =====", pass_count, fail_count);
        #1;
        $finish;
    end
endmodule