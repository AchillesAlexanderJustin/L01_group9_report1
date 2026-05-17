// =============================================================================
// Module: Program Counter (PC)
// Description: 5-bit counter with synchronous reset (active high),
//              load enable, and increment enable.
//              - On reset: counter = 0
//              - On load:  counter = load_data
//              - On inc:   counter = counter + 1
// =============================================================================

module pc (
    input  wire       clk,
    input  wire       rst,
    input  wire       ld_pc,    // load enable
    input  wire       inc_pc,   // increment enable
    input  wire [31:0] load_data,// data to load
    output reg  [31:0] pc_out    // current program counter
);

    always @(posedge clk) begin
        if (rst)
            pc_out <= 32'b0;
        else if (ld_pc)
            pc_out <= load_data;
        else if (inc_pc)
            pc_out <= pc_out + 32'b1;
    end
    
endmodule
