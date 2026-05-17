// =============================================================================
// Module: Arithmetic Logic Unit (ALU)
// Description: Performs 8 operations on 8-bit operands based on 3-bit opcode.
//              is_zero is asynchronous and checks if inA == 0.
//
//   Opcode | Mnemonic | Output
//   -------|----------|----------
//    000   |  HLT     | inA
//    001   |  SKZ     | inA
//    010   |  ADD     | inA + inB
//    011   |  AND     | inA & inB
//    100   |  XOR     | inA ^ inB
//    101   |  LDA     | inB
//    110   |  STO     | inA
//    111   |  JMP     | inA
// =============================================================================

module alu (
    input  wire [2:0] opcode,
    input  wire [31:0] inA,     // from accumulator
    input  wire [31:0] inB,     // from memory
    output reg  [31:0] alu_out, // result
    output wire       is_zero  // async: inA == 0?
);

    // is_zero is asynchronous - checks inA
    assign is_zero = (inA == 32'b0);

    // ALU operation
    always @(*) begin
        case (opcode)
            3'b000: alu_out = inA;          // HLT - pass through
            3'b001: alu_out = inA;          // SKZ - pass through
            3'b010: alu_out = inA + inB;    // ADD
            3'b011: alu_out = inA & inB;    // AND
            3'b100: alu_out = inA ^ inB;    // XOR
            3'b101: alu_out = inB;          // LDA - load from memory
            3'b110: alu_out = inA;          // STO - pass through
            3'b111: alu_out = inA;          // JMP - pass through
            default: alu_out = 32'b0;
        endcase
    end

endmodule
