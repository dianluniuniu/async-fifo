//==============================================================================
// File: wptr_full.sv
// Description: Write pointer and full flag generation with Gray code conversion
//==============================================================================

module wptr_full #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                  wclk,
    input  wire                  wrst_n,
    input  wire                  winc,
    input  wire [ADDR_WIDTH:0]   rptr_gray_sync,
    output reg                   wfull,
    output reg  [ADDR_WIDTH:0]   wptr,
    output reg  [ADDR_WIDTH:0]   wptr_gray,
    output wire [ADDR_WIDTH-1:0] waddr
);

    reg [ADDR_WIDTH:0] wbin;
    wire [ADDR_WIDTH:0] wbin_next, wgray_next;
    wire wfull_val;

    // Binary write pointer
    assign waddr = wbin[ADDR_WIDTH-1:0];
    assign wbin_next = wbin + (winc & ~wfull);
    assign wgray_next = (wbin_next >> 1) ^ wbin_next;  // Binary to Gray

    // Write pointer update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wbin <= '0;
            wptr <= '0;
            wptr_gray <= '0;
        end else begin
            wbin <= wbin_next;
            wptr <= wbin_next;
            wptr_gray <= wgray_next;
        end
    end

    // Full flag generation
    // FIFO is full when:
    // - MSB of Gray pointers are different (wptr[ADDR_WIDTH] != rptr[ADDR_WIDTH])
    // - Second MSB are different (wptr[ADDR_WIDTH-1] != rptr[ADDR_WIDTH-1])
    // - All other bits are same
    assign wfull_val = (wgray_next == {~rptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1], 
                                       rptr_gray_sync[ADDR_WIDTH-2:0]});

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wfull <= 1'b0;
        else
            wfull <= wfull_val;
    end

endmodule