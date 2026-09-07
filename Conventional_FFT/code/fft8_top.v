// fft8_top.v
// 8-point Radix-2 Decimation-In-Time FFT, conventional version (array multiplier).
// 3-stage pipeline: bit-reversal reorder -> Stage1 -> Stage2 -> Stage3 -> output.
// Latency: 4 clock cycles from the 'start' pulse to 'valid' (verified in sim).
//
// Ports are flattened (x0_re, x0_im, x1_re, ... ) instead of arrays, for
// maximum tool compatibility across Vivado versions.

module fft8_top (
    input clk,
    input rst,
    input start,   // pulse 1 cycle to load new input sample set

    // time-domain input samples x[0..7], Q1.15
    input signed [15:0] x0_re, x0_im, x1_re, x1_im, x2_re, x2_im, x3_re, x3_im,
    input signed [15:0] x4_re, x4_im, x5_re, x5_im, x6_re, x6_im, x7_re, x7_im,

    // frequency-domain output X[0..7], Q1.15
    output reg signed [15:0] X0_re, X0_im, X1_re, X1_im, X2_re, X2_im, X3_re, X3_im,
    output reg signed [15:0] X4_re, X4_im, X5_re, X5_im, X6_re, X6_im, X7_re, X7_im,
    output reg valid   // pulses 1 cycle when X0..X7 are valid
);

    // ---- internal sample arrays ----
    reg  signed [15:0] br_re [0:7], br_im [0:7];   // bit-reversed input (registered on start)
    wire signed [15:0] s1_re [0:7], s1_im [0:7];   // stage-1 combinational outputs
    reg  signed [15:0] s1r_re[0:7], s1r_im[0:7];   // stage-1 registered
    wire signed [15:0] s2_re [0:7], s2_im [0:7];   // stage-2 combinational outputs
    reg  signed [15:0] s2r_re[0:7], s2r_im[0:7];   // stage-2 registered
    wire signed [15:0] s3_re [0:7], s3_im [0:7];   // stage-3 combinational outputs

    // twiddle factor lookups
    wire signed [15:0] w0_re, w0_im, w1_re, w1_im, w2_re, w2_im, w3_re, w3_im;
    twiddle_rom tw0 (.k(2'd0), .w_re(w0_re), .w_im(w0_im));
    twiddle_rom tw1 (.k(2'd1), .w_re(w1_re), .w_im(w1_im));
    twiddle_rom tw2 (.k(2'd2), .w_re(w2_re), .w_im(w2_im));
    twiddle_rom tw3 (.k(2'd3), .w_re(w3_re), .w_im(w3_im));

    // ---- bit-reversal reorder on load (index -> reversed index) ----
    // mapping: 0->0, 1->4, 2->2, 3->6, 4->1, 5->5, 6->3, 7->7
    always @(posedge clk) begin
        if (rst) begin
            br_re[0]<=0; br_re[1]<=0; br_re[2]<=0; br_re[3]<=0;
            br_re[4]<=0; br_re[5]<=0; br_re[6]<=0; br_re[7]<=0;
            br_im[0]<=0; br_im[1]<=0; br_im[2]<=0; br_im[3]<=0;
            br_im[4]<=0; br_im[5]<=0; br_im[6]<=0; br_im[7]<=0;
        end else if (start) begin
            br_re[0] <= x0_re; br_im[0] <= x0_im;
            br_re[1] <= x4_re; br_im[1] <= x4_im;
            br_re[2] <= x2_re; br_im[2] <= x2_im;
            br_re[3] <= x6_re; br_im[3] <= x6_im;
            br_re[4] <= x1_re; br_im[4] <= x1_im;
            br_re[5] <= x5_re; br_im[5] <= x5_im;
            br_re[6] <= x3_re; br_im[6] <= x3_im;
            br_re[7] <= x7_re; br_im[7] <= x7_im;
        end
    end

    // ---- Stage 1: pairs (0,1) (2,3) (4,5) (6,7), all twiddle W0 ----
    butterfly bf1_0 (.a_re(br_re[0]),.a_im(br_im[0]),.b_re(br_re[1]),.b_im(br_im[1]),
                      .w_re(w0_re),.w_im(w0_im),
                      .a_out_re(s1_re[0]),.a_out_im(s1_im[0]),.b_out_re(s1_re[1]),.b_out_im(s1_im[1]));
    butterfly bf1_1 (.a_re(br_re[2]),.a_im(br_im[2]),.b_re(br_re[3]),.b_im(br_im[3]),
                      .w_re(w0_re),.w_im(w0_im),
                      .a_out_re(s1_re[2]),.a_out_im(s1_im[2]),.b_out_re(s1_re[3]),.b_out_im(s1_im[3]));
    butterfly bf1_2 (.a_re(br_re[4]),.a_im(br_im[4]),.b_re(br_re[5]),.b_im(br_im[5]),
                      .w_re(w0_re),.w_im(w0_im),
                      .a_out_re(s1_re[4]),.a_out_im(s1_im[4]),.b_out_re(s1_re[5]),.b_out_im(s1_im[5]));
    butterfly bf1_3 (.a_re(br_re[6]),.a_im(br_im[6]),.b_re(br_re[7]),.b_im(br_im[7]),
                      .w_re(w0_re),.w_im(w0_im),
                      .a_out_re(s1_re[6]),.a_out_im(s1_im[6]),.b_out_re(s1_re[7]),.b_out_im(s1_im[7]));

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i=0;i<8;i=i+1) begin s1r_re[i] <= 0; s1r_im[i] <= 0; end
        end else begin
            for (i=0;i<8;i=i+1) begin s1r_re[i] <= s1_re[i]; s1r_im[i] <= s1_im[i]; end
        end
    end

    // ---- Stage 2: groups (0,2)(1,3) w=[W0,W2] and (4,6)(5,7) w=[W0,W2] ----
    // (m=4 twiddle step is wm=W8^2 per hop, NOT W8^1 - that was the bug)
    butterfly bf2_0 (.a_re(s1r_re[0]),.a_im(s1r_im[0]),.b_re(s1r_re[2]),.b_im(s1r_im[2]),
                      .w_re(w0_re),.w_im(w0_im),
                      .a_out_re(s2_re[0]),.a_out_im(s2_im[0]),.b_out_re(s2_re[2]),.b_out_im(s2_im[2]));
    butterfly bf2_1 (.a_re(s1r_re[1]),.a_im(s1r_im[1]),.b_re(s1r_re[3]),.b_im(s1r_im[3]),
                      .w_re(w2_re),.w_im(w2_im),
                      .a_out_re(s2_re[1]),.a_out_im(s2_im[1]),.b_out_re(s2_re[3]),.b_out_im(s2_im[3]));
    butterfly bf2_2 (.a_re(s1r_re[4]),.a_im(s1r_im[4]),.b_re(s1r_re[6]),.b_im(s1r_im[6]),
                      .w_re(w0_re),.w_im(w0_im),
                      .a_out_re(s2_re[4]),.a_out_im(s2_im[4]),.b_out_re(s2_re[6]),.b_out_im(s2_im[6]));
    butterfly bf2_3 (.a_re(s1r_re[5]),.a_im(s1r_im[5]),.b_re(s1r_re[7]),.b_im(s1r_im[7]),
                      .w_re(w2_re),.w_im(w2_im),
                      .a_out_re(s2_re[5]),.a_out_im(s2_im[5]),.b_out_re(s2_re[7]),.b_out_im(s2_im[7]));

    always @(posedge clk) begin
        if (rst) begin
            for (i=0;i<8;i=i+1) begin s2r_re[i] <= 0; s2r_im[i] <= 0; end
        end else begin
            for (i=0;i<8;i=i+1) begin s2r_re[i] <= s2_re[i]; s2r_im[i] <= s2_im[i]; end
        end
    end

    // ---- Stage 3: group (0,4)(1,5)(2,6)(3,7) w=[W0,W1,W2,W3] ----
    butterfly bf3_0 (.a_re(s2r_re[0]),.a_im(s2r_im[0]),.b_re(s2r_re[4]),.b_im(s2r_im[4]),
                      .w_re(w0_re),.w_im(w0_im),
                      .a_out_re(s3_re[0]),.a_out_im(s3_im[0]),.b_out_re(s3_re[4]),.b_out_im(s3_im[4]));
    butterfly bf3_1 (.a_re(s2r_re[1]),.a_im(s2r_im[1]),.b_re(s2r_re[5]),.b_im(s2r_im[5]),
                      .w_re(w1_re),.w_im(w1_im),
                      .a_out_re(s3_re[1]),.a_out_im(s3_im[1]),.b_out_re(s3_re[5]),.b_out_im(s3_im[5]));
    butterfly bf3_2 (.a_re(s2r_re[2]),.a_im(s2r_im[2]),.b_re(s2r_re[6]),.b_im(s2r_im[6]),
                      .w_re(w2_re),.w_im(w2_im),
                      .a_out_re(s3_re[2]),.a_out_im(s3_im[2]),.b_out_re(s3_re[6]),.b_out_im(s3_im[6]));
    butterfly bf3_3 (.a_re(s2r_re[3]),.a_im(s2r_im[3]),.b_re(s2r_re[7]),.b_im(s2r_im[7]),
                      .w_re(w3_re),.w_im(w3_im),
                      .a_out_re(s3_re[3]),.a_out_im(s3_im[3]),.b_out_re(s3_re[7]),.b_out_im(s3_im[7]));

    // ---- output register + valid pulse ----
    // Data path has 3 register stages between input load and the X output
    // register (br -> s1r -> s2r -> X), so the control chain needs 3 delay
    // flops (start_d1/d2/d3) to gate the X load on the correct cycle -
    // matching each register hop exactly, not one cycle early.
    reg start_d1, start_d2, start_d3;
    always @(posedge clk) begin
        if (rst) begin
            start_d1 <= 0; start_d2 <= 0; start_d3 <= 0; valid <= 0;
            X0_re<=0;X0_im<=0;X1_re<=0;X1_im<=0;X2_re<=0;X2_im<=0;X3_re<=0;X3_im<=0;
            X4_re<=0;X4_im<=0;X5_re<=0;X5_im<=0;X6_re<=0;X6_im<=0;X7_re<=0;X7_im<=0;
        end else begin
            start_d1 <= start;
            start_d2 <= start_d1;
            start_d3 <= start_d2;
            valid    <= start_d3;
            if (start_d3) begin
                X0_re<=s3_re[0]; X0_im<=s3_im[0];
                X1_re<=s3_re[1]; X1_im<=s3_im[1];
                X2_re<=s3_re[2]; X2_im<=s3_im[2];
                X3_re<=s3_re[3]; X3_im<=s3_im[3];
                X4_re<=s3_re[4]; X4_im<=s3_im[4];
                X5_re<=s3_re[5]; X5_im<=s3_im[5];
                X6_re<=s3_re[6]; X6_im<=s3_im[6];
                X7_re<=s3_re[7]; X7_im<=s3_im[7];
            end
        end
    end

endmodule
