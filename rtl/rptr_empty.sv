//==============================================================================
// File: rptr_empty.sv
// Description: Read pointer and empty flag generation with Gray code conversion
//==============================================================================

module rptr_empty #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                  rclk,
    input  wire                  rrst_n,
    input  wire                  rinc,
    input  wire [ADDR_WIDTH:0]   wptr_gray_sync,
    output reg                   rempty,
    output reg  [ADDR_WIDTH:0]   rptr,
    output reg  [ADDR_WIDTH:0]   rptr_gray,
    output wire [ADDR_WIDTH-1:0] raddr
);

    reg [ADDR_WIDTH:0] rbin;
    wire [ADDR_WIDTH:0] rbin_next, rgray_next;
    wire rempty_val;

    // Binary read pointer
    assign raddr = rbin[ADDR_WIDTH-1:0];
    assign rbin_next = rbin + (rinc & ~rempty);
    assign rgray_next = (rbin_next >> 1) ^ rbin_next;  // Binary to Gray

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rbin <= '0;
            rptr <= '0;
            rptr_gray <= '0;
        end else begin
            rbin <= rbin_next;
            rptr <= rbin_next;
            rptr_gray <= rgray_next;
        end
    end

    // Empty flag generation
    // FIFO is empty when Gray pointers are equal
    assign rempty_val = (rgray_next == wptr_gray_sync);

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rempty <= 1'b1;
        else
            rempty <= rempty_val;
    end

endmodule