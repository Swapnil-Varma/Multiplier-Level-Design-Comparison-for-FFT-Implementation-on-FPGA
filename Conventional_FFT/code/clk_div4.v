// clk_div4.v
// Divides the 100 MHz Basys-3 clock by 4 -> 25 MHz (40 ns period).
// This gives ~3x margin over the 12.77 ns worst-case path that failed
// timing at 100 MHz, so the design closes cleanly.
//
// Uses an explicit BUFG so the divided clock is routed on a dedicated
// global clock buffer/network instead of ordinary logic routing - this
// is required by Xilinx clocking guidelines for any internally-generated
// clock and avoids skew/DRC issues in implementation.

module clk_div4 (
    input  clk_in,   // 100 MHz in
    output clk_out   // 25 MHz out
);

    (* ASYNC_REG = "TRUE" *) reg [1:0] cnt = 2'b00;

    always @(posedge clk_in) begin
        cnt <= cnt + 1'b1;
    end

    BUFG bufg_i (
        .I (cnt[1]),
        .O (clk_out)
    );

endmodule
