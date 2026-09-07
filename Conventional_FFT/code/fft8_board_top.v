// fft8_board_top.v
// Basys-3 board wrapper around fft8_top for a live hardware demo.
//
// - Fixed test vector (same 8 samples used in the verified testbench) is
//   hardwired as input - no ADC/UART yet, that's a later addition.
// - BTNC = reset, BTNU = start (each converted from a button level into a
//   clean single-cycle pulse via a 2-flop synchronizer + edge detect).
// - SW[2:0] selects which output X0-X7 to view (0-7).
// - SW[3]   selects real (0) or imaginary (1) part of the selected output.
// - LD[15:0] shows the selected 16-bit Q1.15 value.
// - LD15 (reused as a "valid/ready" heartbeat) - see note below if you'd
//   rather dedicate a separate LED to it instead of overlaying.
//
// Clocking: fft8_top failed timing at the full 100 MHz board clock
// (worst path needed ~12.77 ns, only 10 ns was available). Rather than
// restructure the pipeline now, everything below the clk_div4 instance
// runs on a divided 25 MHz clock (40 ns period), giving comfortable
// margin. This keeps the whole design in ONE clock domain, so there is
// no clock-domain-crossing to worry about - buttons, the FFT core, and
// the LED output register are all clocked by clk25.

module fft8_board_top (
    input        clk,        // 100 MHz onboard clock, pin W5
    input        btnC,       // reset button
    input        btnU,       // start button
    input  [3:0] sw,         // sw[2:0]=output index, sw[3]=re/im select
    output [15:0] led
);

    // ---- 100 MHz -> 25 MHz for the whole design ----
    wire clk25;
    clk_div4 u_clk_div (
        .clk_in  (clk),
        .clk_out (clk25)
    );

    // ---- reset: simple synchronizer (buttons are active-high on Basys-3) ----
    reg rst_sync0, rst_sync1;
    always @(posedge clk25) begin
        rst_sync0 <= btnC;
        rst_sync1 <= rst_sync0;
    end
    wire rst = rst_sync1;

    // ---- start: synchronize + rising-edge detect -> clean 1-cycle pulse ----
    reg btnU_sync0, btnU_sync1, btnU_sync2;
    always @(posedge clk25) begin
        btnU_sync0 <= btnU;
        btnU_sync1 <= btnU_sync0;
        btnU_sync2 <= btnU_sync1;
    end
    wire start_pulse = btnU_sync1 & ~btnU_sync2;

    // ---- fixed test vector (matches fft8_tb.v reference input) ----
    // x[n] = [0.10, 0.20, -0.10, 0.15, -0.20, 0.05, 0.25, -0.15]
    localparam signed [15:0] X0_RE = 16'sh0CCD, X0_IM = 16'sh0000;
    localparam signed [15:0] X1_RE = 16'sh199A, X1_IM = 16'sh0000;
    localparam signed [15:0] X2_RE = 16'shF333, X2_IM = 16'sh0000;
    localparam signed [15:0] X3_RE = 16'sh1333, X3_IM = 16'sh0000;
    localparam signed [15:0] X4_RE = 16'shE666, X4_IM = 16'sh0000;
    localparam signed [15:0] X5_RE = 16'sh0666, X5_IM = 16'sh0000;
    localparam signed [15:0] X6_RE = 16'sh2000, X6_IM = 16'sh0000;
    localparam signed [15:0] X7_RE = 16'shECCD, X7_IM = 16'sh0000;

    wire signed [15:0] Y0_re, Y0_im, Y1_re, Y1_im, Y2_re, Y2_im, Y3_re, Y3_im;
    wire signed [15:0] Y4_re, Y4_im, Y5_re, Y5_im, Y6_re, Y6_im, Y7_re, Y7_im;
    wire valid;

    fft8_top dut (
        .clk(clk25), .rst(rst), .start(start_pulse),
        .x0_re(X0_RE), .x0_im(X0_IM), .x1_re(X1_RE), .x1_im(X1_IM),
        .x2_re(X2_RE), .x2_im(X2_IM), .x3_re(X3_RE), .x3_im(X3_IM),
        .x4_re(X4_RE), .x4_im(X4_IM), .x5_re(X5_RE), .x5_im(X5_IM),
        .x6_re(X6_RE), .x6_im(X6_IM), .x7_re(X7_RE), .x7_im(X7_IM),
        .X0_re(Y0_re), .X0_im(Y0_im), .X1_re(Y1_re), .X1_im(Y1_im),
        .X2_re(Y2_re), .X2_im(Y2_im), .X3_re(Y3_re), .X3_im(Y3_im),
        .X4_re(Y4_re), .X4_im(Y4_im), .X5_re(Y5_re), .X5_im(Y5_im),
        .X6_re(Y6_re), .X6_im(Y6_im), .X7_re(Y7_re), .X7_im(Y7_im),
        .valid(valid)
    );

    // ---- latch outputs on valid, so LEDs hold a stable value between runs ----
    reg signed [15:0] hold_re [0:7];
    reg signed [15:0] hold_im [0:7];
    integer i;
    always @(posedge clk25) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                hold_re[i] <= 16'sh0000;
                hold_im[i] <= 16'sh0000;
            end
        end else if (valid) begin
            hold_re[0] <= Y0_re; hold_im[0] <= Y0_im;
            hold_re[1] <= Y1_re; hold_im[1] <= Y1_im;
            hold_re[2] <= Y2_re; hold_im[2] <= Y2_im;
            hold_re[3] <= Y3_re; hold_im[3] <= Y3_im;
            hold_re[4] <= Y4_re; hold_im[4] <= Y4_im;
            hold_re[5] <= Y5_re; hold_im[5] <= Y5_im;
            hold_re[6] <= Y6_re; hold_im[6] <= Y6_im;
            hold_re[7] <= Y7_re; hold_im[7] <= Y7_im;
        end
    end

    // ---- switch-selected display ----
    wire [15:0] selected = sw[3] ? hold_im[sw[2:0]] : hold_re[sw[2:0]];
    assign led = selected;

endmodule