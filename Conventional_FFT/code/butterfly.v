// butterfly.v
// One radix-2 DIT butterfly:
//   t      = W * B
//   A_out  = A + t
//   B_out  = A - t
//
// This module is instantiated 12 times (4 per stage x 3 stages) in fft8_top.v.
// It is combinational; fft8_top.v adds pipeline registers between stages.

module butterfly (
    input  signed [15:0] a_re, a_im,   // input A
    input  signed [15:0] b_re, b_im,   // input B
    input  signed [15:0] w_re, w_im,   // twiddle factor
    output signed [15:0] a_out_re, a_out_im,
    output signed [15:0] b_out_re, b_out_im
);

    wire signed [15:0] t_re, t_im;

    // t = W * B  (baseline array multiplier - swap this instantiation
    // for complex_mult_booth / complex_mult_vedic / complex_mult_wallace
    // when doing the multiplier comparison stage)
    complex_mult_array u_mult (
        .a_re (w_re), .a_im (w_im),
        .b_re (b_re), .b_im (b_im),
        .p_re (t_re), .p_im (t_im)
    );

    complex_add_sub u_addsub (
        .a_re (a_re), .a_im (a_im),
        .b_re (t_re), .b_im (t_im),
        .sum_re  (a_out_re), .sum_im  (a_out_im),
        .diff_re (b_out_re), .diff_im (b_out_im)
    );

endmodule
