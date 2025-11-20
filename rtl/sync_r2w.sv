//==============================================================================
// File: sync_r2w.sv
// Description: Synchronizer for read pointer to write clock domain
//              Uses multi-stage flip-flop synchronizer to handle CDC
//==============================================================================

module sync_r2w #(
    parameter ADDR_WIDTH = 4,
    parameter SYNC_STAGES = 2
)(
    input  wire                  wclk,
    input  wire                  wrst_n,
    input  wire [ADDR_WIDTH:0]   rptr_gray,
    output reg  [ADDR_WIDTH:0]   rptr_gray_sync
);

    // Synchronizer chain
    (* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] sync_reg [SYNC_STAGES-1:0];

    integer i;
    
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (i = 0; i < SYNC_STAGES; i = i + 1)
                sync_reg[i] <= '0;
            rptr_gray_sync <= '0;
        end else begin
            sync_reg[0] <= rptr_gray;
            for (i = 1; i < SYNC_STAGES; i = i + 1)
                sync_reg[i] <= sync_reg[i-1];
            rptr_gray_sync <= sync_reg[SYNC_STAGES-1];
        end
    end

endmodule