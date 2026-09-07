// complex_add_sub.v
// Complex addition and subtraction in Q1.15 fixed-point (16-bit signed).
// Purely combinational - used inside the butterfly unit.

module complex_add_sub (
    input  signed [15:0] a_re, a_im,   // operand A
    input  signed [15:0] b_re, b_im,   // operand B
    output signed [15:0] sum_re, sum_im, // A + B
    output signed [15:0] diff_re, diff_im // A - B
);

    assign sum_re  = a_re + b_re;
    assign sum_im  = a_im + b_im;
    assign diff_re = a_re - b_re;
    assign diff_im = a_im - b_im;

endmodule
