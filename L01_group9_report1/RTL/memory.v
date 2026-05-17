// =============================================================================
// Module: Memory (32 x 8-bit)
// Description: Synchronous memory with single bidirectional data port.
//              - 5-bit address (32 locations)
//              - 8-bit data width
//              - Separate rd/wr control signals (cannot read and write simultaneously)
//              - Bidirectional data port using inout
//              - Initial contents loaded from external file via $readmemb
// =============================================================================

module memory (
    input  wire       clk,
    input  wire       rd,       // read enable
    input  wire       wr,       // write enable
    input  wire [31:0] addr,     // 5-bit address
    inout  wire [31:0] data      // bidirectional data port
);

    reg [31:0] mem [0:31];       // 32 x 8-bit memory array

    // Drive data bus during read, high-Z otherwise
    assign data = (rd && !wr) ? mem[addr] : 32'bz;

    // Write on rising edge of clock when wr is asserted
    always @(posedge clk) begin
        if (wr && !rd)
            mem[addr] <= data;
    end

    // Memory initialization - load from file
    // The file path will be set by the testbench using $readmemb
    // or initial block. Default initialization to 0.
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            mem[i] = 32'b0;
    end

endmodule
