// complex_mult_array.v
// "Conventional" complex multiplier using plain array (direct) multiplication.
// This is the baseline variant. Booth / Vedic / Wallace Tree multipliers
// built later MUST use this exact port interface so they can be swapped
// in without touching butterfly.v or fft8_top.v.
//
// Complex multiply: (a_re + j*a_im) * (b_re + j*b_im)
//   p_re = a_re*b_re - a_im*b_im
//   p_im = a_re*b_im + a_im*b_re
//
// Fixed point: inputs are Q1.15 (16-bit signed, 1 sign + 15 fractional bits).
// A 16x16 signed multiply gives a 32-bit Q2.30 product; bits [30:15] are
// taken as the Q1.15 result (standard truncation - rounding can be added
// later if needed for precision comparison across multiplier variants).

module complex_mult_array (
    input  signed [15:0] a_re, a_im,
    input  signed [15:0] b_re, b_im,
    output signed [15:0] p_re, p_im
);

    wire signed [31:0] ac, bd, ad, bc;

    assign ac = a_re * b_re;
    assign bd = a_im * b_im;
    assign ad = a_re * b_im;
    assign bc = a_im * b_re;

    wire signed [31:0] re_full = ac - bd;
    wire signed [31:0] im_full = ad + bc;

    // round-half-up (add half an LSB before truncating) instead of plain
    // truncation - keeps the bias small and consistent, useful once you're
    // comparing precision across the Booth/Vedic/Wallace variants later.
    wire signed [31:0] re_rounded = re_full + 32'sh0000_4000;
    wire signed [31:0] im_rounded = im_full + 32'sh0000_4000;

    assign p_re = re_rounded[30:15];
    assign p_im = im_rounded[30:15];

endmodule
