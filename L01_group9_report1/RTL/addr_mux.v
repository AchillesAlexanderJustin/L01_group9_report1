// =============================================================================
// Module: Address Multiplexer
// Description: 2-to-1 mux, parameterized width (default 5-bit).
//              sel=1 -> selects pc_addr (instruction fetch phase)
//              sel=0 -> selects ir_addr (operand fetch phase)
// =============================================================================

module addr_mux #(
    parameter WIDTH = 32
)(
    input  wire             sel,
    input  wire [WIDTH-1:0] pc_addr,  // from program counter
    input  wire [WIDTH-1:0] ir_addr,  // from instruction register (operand)
    output wire [WIDTH-1:0] addr_out  // to memory
);

    assign addr_out = sel ? pc_addr : ir_addr;

endmodule
