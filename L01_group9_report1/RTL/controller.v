// =============================================================================
// Module: Controller (FSM)
// Description: 8-state FSM that generates control signals for the CPU.
//              States cycle: INST_ADDR -> INST_FETCH -> INST_LOAD -> IDLE
//                         -> OP_ADDR -> OP_FETCH -> ALU_OP -> STORE -> (repeat)
//              Synchronous reset (active high) returns to INST_ADDR.
//
// Control signals are determined by current state and opcode.
// =============================================================================

module controller (
    input  wire       clk,
    input  wire       rst,
    input  wire [2:0] opcode,   // from instruction register [7:5]
    input  wire       zero,     // is_zero flag from ALU
    output reg        sel,      // address mux select
    output reg        rd,       // memory read
    output reg        ld_ir,    // load instruction register
    output reg        halt,     // halt signal
    output reg        inc_pc,   // increment program counter
    output reg        ld_ac,    // load accumulator
    output reg        ld_pc,    // load program counter
    output reg        wr,       // memory write
    output reg        data_e    // data enable (accumulator -> memory bus)
);

    // State encoding
    localparam [2:0]
        INST_ADDR  = 3'b000,
        INST_FETCH = 3'b001,
        INST_LOAD  = 3'b010,
        IDLE       = 3'b011,
        OP_ADDR    = 3'b100,
        OP_FETCH   = 3'b101,
        ALU_OP     = 3'b110,
        STORE      = 3'b111;

    // Opcode encoding
    localparam [2:0]
        HLT = 3'b000,
        SKZ = 3'b001,
        ADD = 3'b010,
        AND = 3'b011,
        XOR = 3'b100,
        LDA = 3'b101,
        STO = 3'b110,
        JMP = 3'b111;

    reg [2:0] state, next_state;

    // Internal helper signals
    wire alu_op_needed;  // ALU needs to read from memory: ADD, AND, XOR, LDA

    assign alu_op_needed = (opcode == ADD) || (opcode == AND) ||
                           (opcode == XOR) || (opcode == LDA);

    // State register - sequential
    always @(posedge clk) begin
        if (rst)
            state <= INST_ADDR;
        else
            state <= next_state;
    end

    // Next state logic - always cycles through 8 states
    always @(*) begin
        case (state)
            INST_ADDR:  next_state = INST_FETCH;
            INST_FETCH: next_state = INST_LOAD;
            INST_LOAD:  next_state = IDLE;
            IDLE:       next_state = OP_ADDR;
            OP_ADDR:    next_state = OP_FETCH;
            OP_FETCH:   next_state = ALU_OP;
            ALU_OP:     next_state = STORE;
            STORE:      next_state = INST_ADDR;
            default:    next_state = INST_ADDR;
        endcase
    end

    // Output logic - combinational, based on state and opcode
    always @(*) begin
        // Default all outputs to 0
        sel    = 1'b0;
        rd     = 1'b0;
        ld_ir  = 1'b0;
        halt   = 1'b0;
        inc_pc = 1'b0;
        ld_ac  = 1'b0;
        ld_pc  = 1'b0;
        wr     = 1'b0;
        data_e = 1'b0;

        case (state)
            INST_ADDR: begin
                sel = 1'b1;
            end

            INST_FETCH: begin
                sel = 1'b1;
                rd  = 1'b1;
            end

            INST_LOAD: begin
                sel   = 1'b1;
                rd    = 1'b1;
                ld_ir = 1'b1;
            end

            IDLE: begin
                sel   = 1'b1;
                rd    = 1'b1;
                ld_ir = 1'b1;
            end

            OP_ADDR: begin
                halt   = (opcode == HLT);
                inc_pc = 1'b1;
            end

            OP_FETCH: begin
                rd = alu_op_needed;
            end

            ALU_OP: begin
                rd     = alu_op_needed;
                inc_pc = (opcode == SKZ) && zero;
                ld_pc  = (opcode == JMP);
                data_e = (opcode == STO);
            end

            STORE: begin
                rd     = alu_op_needed;
                ld_ac  = alu_op_needed;
                ld_pc  = (opcode == JMP);
                wr     = (opcode == STO);
                data_e = (opcode == STO);
            end
        endcase
    end

endmodule