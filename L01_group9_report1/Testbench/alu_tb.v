`timescale 1ns/1ps

module alu_tb;
    reg  [2:0] opcode;
    reg  [31:0] inA, inB;
    wire [31:0] alu_out;
    wire        is_zero;

    alu uut (
        .opcode(opcode), .inA(inA), .inB(inB),
        .alu_out(alu_out), .is_zero(is_zero)
    );

    integer pass_count = 0;
    integer fail_count = 0;

    task check;
        input [31:0] expected_out;
        input        expected_zero;
        input [127:0] test_name;
        begin
            #1;
            if (alu_out === expected_out && is_zero === expected_zero) begin
                $display("[PASS] %-15s | In: opcode=%b, inA=%0d, inB=%0d | Out: %0d, Zero:%b", 
                         test_name, opcode, inA, inB, alu_out, is_zero);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %-15s | In: opcode=%b, inA=%0d, inB=%0d | Exp: %0d, Zero:%b | Got: %0d, Zero:%b",
                         test_name, opcode, inA, inB, expected_out, expected_zero, alu_out, is_zero);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);

        $display("Starting ALU Testbench...\n");

        // --- TC1: Zero Status Flag ---
        opcode = 3'b000; inA = 0; inB = 0;
        #1;
        check(0, 1'b1, "TC1.1_ZERO");

        opcode = 3'b000; inA = 50; inB = 0;
        #1;
        check(50, 1'b0, "TC1.2_NONZERO");

        // --- TC2: Arithmetic & Logic ---
        opcode = 3'b010; inA = 100; inB = 25; #1; check(125, 1'b0, "ADD_TC2");
        opcode = 3'b011; inA = 100; inB = 25; #1; check(0, 1'b0, "AND_TC2");
        opcode = 3'b100; inA = 100; inB = 25; #1; check(125, 1'b0, "XOR_TC2");
        opcode = 3'b101; inA = 100; inB = 25; #1; check(25, 1'b0, "LDA_TC2");

        // --- TC3: Transfer Operations ---
        opcode = 3'b000; inA = 999; inB = 555; #1; check(999, 1'b0, "HLT_TC3");
        opcode = 3'b001; inA = 999; inB = 555; #1; check(999, 1'b0, "SKZ_TC3");
        opcode = 3'b110; inA = 999; inB = 555; #1; check(999, 1'b0, "STO_TC3");
        opcode = 3'b111; inA = 999; inB = 555; #1; check(999, 1'b0, "JMP_TC3");

        // --- TC4: Combinational Property ---
        opcode = 3'b010; inA = 10; inB = 20; #1; check(30, 1'b0, "TC4_COMB");

        // --- TC5: Boundary Cases ---
        opcode = 3'b010; inA = 4294967295; inB = 1; #1; check(0, 1'b0, "TC5.1_OVF");
        opcode = 3'b010; inA = 2147483647; inB = 2147483647; #1; check(4294967294, 1'b0, "TC5.2_BOUND");

        // --- TC6: Complex Logic ---
        opcode = 3'b011; inA = 2863311530; inB = 1431655765; #1; check(0, 1'b0, "TC6_AND_C");
        opcode = 3'b100; inA = 2863311530; inB = 1431655765; #1; check(4294967295, 1'b0, "TC6_XOR_C");

        // --- TC7: Zero Flag Independence ---
        opcode = 3'b001; inA = 0; #1;   check(0, 1'b1, "TC7.1_Z1"); 
        opcode = 3'b001; inA = 100; #1; check(100, 1'b0, "TC7.2_Z0");

        $display("\n===== ALU Testbench: %0d PASSED, %0d FAILED =====", pass_count, fail_count);
        $finish;
    end
endmodule