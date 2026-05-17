`timescale 1ns / 1ps

module cpu_tb1;

    // -- DUT signals --
    reg  clk;
    reg  rst;
    wire halt;

    
    cpu uut (
        .clk (clk),
        .rst (rst),
        .halt(halt)
    );

    // -- Clock: 10 ns period --
    initial clk = 0;
    always #5 clk = ~clk;


    task display_cpu_state;
        begin
            $display("time=%5t | PC=%2d | State=%3b | Op=%3b | AC=%0d | Halt=%b",
                      $time, uut.u_pc.pc_out, uut.u_ctrl.state, 
                      uut.opcode, uut.u_ac.data_out, halt);
            
            if (uut.u_ctrl.state == 3'b110) begin
                case (uut.opcode)
                    3'b010: $display("   >>> ACTION: Performing ADD operation...");
                    3'b100: $display("   >>> ACTION: Performing XOR operation...");
                    3'b011: $display("   >>> ACTION: Performing AND operation...");
                    3'b110: $display("   >>> ACTION: Performing STO (Store) operation...");
                    3'b000: $display("   >>> HALT DETECTED . Stopping CPU");
                endcase
            end
        end
    endtask

    // -- Nạp chương trình và điều khiển mô phỏng --
    initial begin
        // 1. Nạp chương trình: Pythagoras (3^2 + 4^2) + Logic (XOR, AND)
        
        // ---  A^2 (3*3 = 9) ---
        uut.u_memory.mem[0] = 32'hB4; // LDA 20
        uut.u_memory.mem[1] = 32'h54; // ADD 20
        uut.u_memory.mem[2] = 32'h54; // ADD 20
        uut.u_memory.mem[3] = 32'hD6; // STO 22 (Lưu A^2 = 9)

        // ---  B^2 (4*4 = 16) ---
        uut.u_memory.mem[4] = 32'hB5; // LDA 21
        uut.u_memory.mem[5] = 32'h55; // ADD 21
        uut.u_memory.mem[6] = 32'h55; // ADD 21
        uut.u_memory.mem[7] = 32'h55; // ADD 21

        // ---  A^2 + B^2 = 25 ---
        uut.u_memory.mem[8] = 32'h56; // ADD 22

        // --- Logic Operations ---
        uut.u_memory.mem[9]  = 32'h98; // XOR 24 (25 ^ 7 = 30)
        uut.u_memory.mem[10] = 32'h79; // AND 25 (30 & 15 = 14)
        
        // ---  HALT ---
        uut.u_memory.mem[11] = 32'hD7; // STO 23 (Kết quả cuối)
        uut.u_memory.mem[12] = 32'h00; // HLT (Dừng CPU tại đây)


        uut.u_memory.mem[20] = 32'd3;  // A
        uut.u_memory.mem[21] = 32'd4;  // B
        uut.u_memory.mem[22] = 32'd0;  // Temp
        uut.u_memory.mem[23] = 32'd0;  // Final Result
        uut.u_memory.mem[24] = 32'd7;  // XOR mask
        uut.u_memory.mem[25] = 32'd15; // AND mask

      
        rst = 1;
        repeat (2) @(posedge clk);
        #1; rst = 0;

        $display("--- CPU PYTHAGOREAN + LOGIC TEST STARTED ---");
    end

    
    always @(posedge clk) begin
        if (!rst) display_cpu_state();
    end

    
    initial begin
        
        wait (halt === 1'b1);
        repeat (2) @(posedge clk);

        $display("--- FINAL RESULT CHECK ---");
        $display("Mem[23] (Final Logic Result): %0d", uut.u_memory.mem[23]);
        
        if (uut.u_memory.mem[23] == 14)
            $display("--- TEST STATUS: PASS (Pythagoras & Logic Verified) ---");
        else
            $display("--- TEST STATUS: FAIL ---");
            
    end

    // Safety Timeout
    initial #1100
     $finish;

endmodule