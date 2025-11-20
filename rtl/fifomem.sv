//==============================================================================
// File: fifomem.sv
// Description: Dual-port RAM for FIFO storage
//==============================================================================

module fifomem #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 1 << ADDR_WIDTH
)(
    input  wire                    wclk,
    input  wire                    wfull,
    input  wire                    winc,
    input  wire [ADDR_WIDTH-1:0]   waddr,
    input  wire [DATA_WIDTH-1:0]   wdata,
    input  wire [ADDR_WIDTH-1:0]   raddr,
    output reg  [DATA_WIDTH-1:0]   rdata
);

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write operation
    always @(posedge wclk) begin
        if (winc && !wfull)
            mem[waddr] <= wdata;
    end

    // Read operation (asynchronous read)
    always @(*) begin
        rdata = mem[raddr];
    end

    // Initialize memory for simulation
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = '0;
    end

endmodule