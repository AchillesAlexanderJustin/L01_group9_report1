// =============================================================================
// Module: Register (8-bit)
// Description: Generic 8-bit register with synchronous reset (active high)
//              and load enable. Used for both Instruction Register and
//              Accumulator Register.
//              - On reset: data_out = 0
//              - On load:  data_out = data_in
//              - Otherwise: data_out holds value
// =============================================================================

module register (
    input  wire       clk,
    input  wire       rst,
    input  wire       load,     // load enable
    input  wire [31:0] data_in,  // input data
    output reg  [31:0] data_out  // output data
);

    always @(posedge clk) begin
        if (rst)
            data_out <= 32'b0;
        else if (load)
            data_out <= data_in;
    end

endmodule
