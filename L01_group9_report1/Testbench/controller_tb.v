module controller_tb;
    reg         clk, rst;
    reg  [2:0]  opcode;
    reg         zero;
    wire        sel, rd, ld_ir, halt;
    wire        inc_pc, ld_ac, ld_pc, wr, data_e;

    controller uut (
        .clk(clk), .rst(rst), .opcode(opcode), .zero(zero),
        .sel(sel), .rd(rd), .ld_ir(ld_ir), .halt(halt),
        .inc_pc(inc_pc), .ld_ac(ld_ac), .ld_pc(ld_pc),
        .wr(wr), .data_e(data_e)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer pass_count = 0;
    integer fail_count = 0;

   
    task check_outputs;
        input       exp_sel, exp_rd, exp_ld_ir, exp_halt;
        input       exp_inc_pc, exp_ld_ac, exp_ld_pc, exp_wr, exp_data_e;
        input [160:0] test_name;
        begin
            if (sel    === exp_sel    && rd     === exp_rd     &&
                ld_ir  === exp_ld_ir  && halt   === exp_halt   &&
                inc_pc === exp_inc_pc && ld_ac  === exp_ld_ac  &&
                ld_pc  === exp_ld_pc  && wr     === exp_wr     &&
                data_e === exp_data_e) begin
                $display("[PASS] %0s", test_name);
                $display("       IN: opcode=%b zero=%b | OUT: sel=%b rd=%b ld_ir=%b halt=%b inc_pc=%b ld_ac=%b ld_pc=%b wr=%b data_e=%b",
                         opcode, zero, sel, rd, ld_ir, halt, inc_pc, ld_ac, ld_pc, wr, data_e);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s", test_name);
                $display("       INPUTS:   opcode=%b zero=%b", opcode, zero);
                $display("       EXPECTED: sel=%b rd=%b ld_ir=%b halt=%b inc_pc=%b ld_ac=%b ld_pc=%b wr=%b data_e=%b",
                         exp_sel, exp_rd, exp_ld_ir, exp_halt, exp_inc_pc, exp_ld_ac, exp_ld_pc, exp_wr, exp_data_e);
                $display("       GOT:      sel=%b rd=%b ld_ir=%b halt=%b inc_pc=%b ld_ac=%b ld_pc=%b wr=%b data_e=%b",
                         sel, rd, ld_ir, halt, inc_pc, ld_ac, ld_pc, wr, data_e);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("controller_tb.vcd");
        $dumpvars(0, controller_tb);

        $display("Starting Controller Testbench...\n");
        // --- TC1: System Reset ---
        rst = 1; opcode = 3'b000; zero = 0;
        @(posedge clk); #1;
        check_outputs(1, 0, 0, 0, 0, 0, 0, 0, 0, "TC1: Reset System");

        // --- TC2 & TC3: Fetch Phase ---
        rst = 0;
        check_outputs(1, 0, 0, 0, 0, 0, 0, 0, 0, "TC2: 0:INST_ADDR");

        @(posedge clk); #1;
        check_outputs(1, 1, 0, 0, 0, 0, 0, 0, 0, "TC2: 1:INST_FETCH");

        @(posedge clk); #1;
        check_outputs(1, 1, 1, 0, 0, 0, 0, 0, 0, "TC3: 2:INST_LOAD");

        @(posedge clk); #1;
        check_outputs(1, 1, 1, 0, 0, 0, 0, 0, 0, "TC3: 3:IDLE");

        // --- TC4: Execution Phase (ADD) ---
        opcode = 3'b010;
        @(posedge clk); #1; 
        check_outputs(0, 0, 0, 0, 1, 0, 0, 0, 0, "TC4: 4:OP_ADDR (ADD)");

        @(posedge clk); #1; 
        check_outputs(0, 1, 0, 0, 0, 0, 0, 0, 0, "TC4: 5:OP_FETCH (ADD)");

        @(posedge clk); #1; 
        check_outputs(0, 1, 0, 0, 0, 0, 0, 0, 0, "TC4: 6:ALU_OP (ADD)");

        @(posedge clk); #1; 
        check_outputs(0, 1, 0, 0, 0, 1, 0, 0, 0, "TC4: 7:STORE (ADD)");

        // --- TC4: Execution Phase (STO) ---
        @(posedge clk); #1; 
        opcode = 3'b110;
        @(posedge clk); #1; // FETCH
        @(posedge clk); #1; // LOAD
        @(posedge clk); #1; // IDLE
        @(posedge clk); #1; 
        check_outputs(0, 0, 0, 0, 1, 0, 0, 0, 0, "TC4: 4:OP_ADDR (STO)");

        @(posedge clk); #1; 
        check_outputs(0, 0, 0, 0, 0, 0, 0, 0, 0, "TC4: 5:OP_FETCH (STO)");

        @(posedge clk); #1; 
        check_outputs(0, 0, 0, 0, 0, 0, 0, 0, 1, "TC4: 6:ALU_OP (STO)");

        @(posedge clk); #1; 
        check_outputs(0, 0, 0, 0, 0, 0, 0, 1, 1, "TC4: 7:STORE (STO)");

        // --- TC4: Execution Phase (JMP) ---
        @(posedge clk); #1; 
        opcode = 3'b111;
        @(posedge clk); #1; @(posedge clk); #1; @(posedge clk); #1;
        @(posedge clk); #1; 
        check_outputs(0, 0, 0, 0, 1, 0, 0, 0, 0, "TC4: 4:OP_ADDR (JMP)");

        @(posedge clk); #1; 
        check_outputs(0, 0, 0, 0, 0, 0, 0, 0, 0, "TC4: 5:OP_FETCH (JMP)");

        @(posedge clk); #1; 
        check_outputs(0, 0, 0, 0, 0, 0, 1, 0, 0, "TC4: 6:ALU_OP (JMP)");

        @(posedge clk); #1; 
        check_outputs(0, 0, 0, 0, 0, 0, 1, 0, 0, "TC4: 7:STORE (JMP)");

        // --- TC4: Execution Phase (HLT) ---
        @(posedge clk); #1; 
        opcode = 3'b000;
        @(posedge clk); #1; @(posedge clk); #1; @(posedge clk); #1;
        @(posedge clk); #1; 
        check_outputs(0, 0, 0, 1, 1, 0, 0, 0, 0, "TC4: 4:OP_ADDR (HLT)");

        @(posedge clk); #1; 
      check_outputs(0, 0, 0, 0, 0, 0, 0, 0, 0, "TC4: 5:OP_FETCH (HLT)");

        @(posedge clk); #1; 
      check_outputs(0, 0, 0, 0, 0, 0, 0, 0, 0, "TC4: 6:ALU_OP (HLT)");

        @(posedge clk); #1; 
      check_outputs(0, 0, 0, 0, 0, 0, 0, 0, 0, "TC4: 7:STORE (HLT)");

        // --- TC5: Conditional Jump (SKZ) ---
        @(posedge clk); #1; 
        opcode = 3'b001; zero = 0;
        @(posedge clk); #1; @(posedge clk); #1; @(posedge clk); #1;
        @(posedge clk); #1; 
      check_outputs(0, 0, 0, 0, 1, 0, 0, 0, 0, "TC5: 4:OP_ADDR (SKZ, z=0)");
        @(posedge clk); #1; 
      check_outputs(0, 0, 0, 0, 0, 0, 0, 0, 0, "TC5: 5:OP_FETCH (SKZ, z=0)");
        @(posedge clk); #1; 
      check_outputs(0, 0, 0, 0, 0, 0, 0, 0, 0, "TC5: 6:ALU_OP (SKZ, z=0)");
        @(posedge clk); #1; 
      check_outputs(0, 0, 0, 0, 0, 0, 0, 0, 0, "TC5: 7:STORE (SKZ, z=0)");

        @(posedge clk); #1; 
        opcode = 3'b001; zero = 1;
        @(posedge clk); #1; @(posedge clk); #1; @(posedge clk); #1;
        @(posedge clk); #1; 
      check_outputs(0, 0, 0, 0, 1, 0, 0, 0, 0, "TC5: 4:OP_ADDR (SKZ, z=1)");
        @(posedge clk); #1; 
      check_outputs(0, 0, 0, 0, 0, 0, 0, 0, 0, "TC5: 5:OP_FETCH (SKZ, z=1)");
        @(posedge clk); #1; 
      check_outputs(0, 0, 0, 0, 1, 0, 0, 0, 0, "TC5: 6:ALU_OP (SKZ, z=1)");
        @(posedge clk); #1; 
      check_outputs(0, 0, 0, 0, 0, 0, 0, 0, 0, "TC5: 7:STORE (SKZ, z=1)");

        // --- TC6: Sync Signals (Async Reset check) ---
        rst = 1; opcode = 3'b001; zero = 1;
      
        @(posedge clk);      
         #1;
        check_outputs(1, 0, 0, 0, 0, 0, 0, 0, 0, "TC6: Reset ync check");

        $display("\n===== Controller Testbench: %0d PASSED, %0d FAILED =====", pass_count, fail_count);
        #10;
        $finish;
    end
endmodule