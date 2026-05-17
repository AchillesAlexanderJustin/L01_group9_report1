// =============================================================================
// Module: CPU Top-Level
// Description: Simple RISC CPU integrating all sub-modules:
//              - Program Counter (PC)
//              - Address Mux
//              - Memory
//              - Instruction Register (IR)
//              - Accumulator Register (AC)
//              - ALU
//              - Controller (FSM)
// =============================================================================

module cpu (
    input  wire clk,
    input  wire rst,
    output wire halt
);

    // =========================================================================
    // Internal wires
    // =========================================================================

    // Program Counter
    wire [31:0] pc_out;

    // Address Mux
    wire [31:0] addr;

    // Memory data bus (bidirectional)
    wire [31:0] data_bus;

    // Instruction Register
    wire [31:0] ir_out;
    wire [2:0] opcode;
    wire [31:0] ir_addr;

    // Accumulator
    wire [31:0] ac_out;

    // ALU
    wire [31:0] alu_out;
    wire       is_zero;

    // Controller signals
    wire sel, rd, ld_ir;
    wire inc_pc, ld_ac, ld_pc, wr, data_e;
    
    // =========================================================================
    // Decode instruction register
    // =========================================================================
    assign opcode  = ir_out[7:5];
    assign ir_addr = {27'b0,ir_out[4:0]};

    // =========================================================================
    // Accumulator drives data bus when data_e is asserted (for STO instruction)
    // =========================================================================
    assign data_bus = data_e ? ac_out : 32'bz;

    // =========================================================================
    // Module instantiations
    // =========================================================================

    // Program Counter
    pc u_pc (
        .clk       (clk),
        .rst       (rst),
        .ld_pc     (ld_pc),
        .inc_pc    (inc_pc),
        .load_data (ir_addr),  // JMP target address from IR
        .pc_out    (pc_out)
    );

    // Address Multiplexer
    addr_mux #(.WIDTH(32)) u_addr_mux (
        .sel      (sel),
        .pc_addr  (pc_out),
        .ir_addr  (ir_addr),
        .addr_out (addr)
    );

    // Memory
    memory u_memory (
        .clk  (clk),
        .rd   (rd),
        .wr   (wr),
        .addr (addr),
        .data (data_bus)
    );

    // Instruction Register
    register u_ir (
        .clk      (clk),
        .rst      (rst),
        .load     (ld_ir),
        .data_in  (data_bus),
        .data_out (ir_out)
    );

    // ALU
    alu u_alu (
        .opcode  (opcode),
        .inA     (ac_out),
        .inB     (data_bus),
        .alu_out (alu_out),
        .is_zero (is_zero)
    );

    // Accumulator Register
    register u_ac (
        .clk      (clk),
        .rst      (rst),
        .load     (ld_ac),
        .data_in  (alu_out),
        .data_out (ac_out)
    );

    // Controller FSM
    controller u_ctrl (
        .clk    (clk),
        .rst    (rst),
        .opcode (opcode),
        .zero   (is_zero),
        .sel    (sel),
        .rd     (rd),
        .ld_ir  (ld_ir),
        .halt   (halt),
        .inc_pc (inc_pc),
        .ld_ac  (ld_ac),
        .ld_pc  (ld_pc),
        .wr     (wr),
        .data_e (data_e)
    );

endmodule
