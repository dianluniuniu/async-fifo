//==============================================================================
// File: sync_w2r.sv
// Description: Synchronizer for write pointer to read clock domain
//              Uses multi-stage flip-flop synchronizer to handle CDC
//==============================================================================

module sync_w2r #(
    parameter ADDR_WIDTH = 4,
    parameter SYNC_STAGES = 2
)(
    input  wire                  rclk,
    input  wire                  rrst_n,
    input  wire [ADDR_WIDTH:0]   wptr_gray,
    output reg  [ADDR_WIDTH:0]   wptr_gray_sync
);

    // Synchronizer chain
    (* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] sync_reg [SYNC_STAGES-1:0];

    integer i;
    
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                sync_reg[i] <= '0;
            wptr_gray_sync <= '0;
        end else begin
            sync_reg[0] <= wptr_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                sync_reg[i] <= sync_reg[i-1];
            wptr_gray_sync <= sync_reg[SYNC_STAGES-1];
        end
    end

endmodule