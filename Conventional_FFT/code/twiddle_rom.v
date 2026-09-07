// twiddle_rom.v
// Precomputed twiddle factors W8^k = e^(-j*2*pi*k/8), k = 0..3, in Q1.15.
// Only 4 unique values are needed for an 8-point FFT (symmetry covers the rest).
// Values verified against a NumPy reference (see project notes).
//
//   W8^0 =  1.000000 + j 0.000000  -> 0x7FFF, 0x0000
//   W8^1 =  0.707107 - j 0.707107  -> 0x5A82, 0xA57E
//   W8^2 =  0.000000 - j 1.000000  -> 0x0000, 0x8000
//   W8^3 = -0.707107 - j 0.707107  -> 0xA57E, 0xA57E

module twiddle_rom (
    input  [1:0]          k,        // twiddle index 0-3
    output reg signed [15:0] w_re,
    output reg signed [15:0] w_im
);

    always @(*) begin
        case (k)
            2'd0: begin w_re = 16'sh7FFF; w_im = 16'sh0000; end
            2'd1: begin w_re = 16'sh5A82; w_im = 16'shA57E; end
            2'd2: begin w_re = 16'sh0000; w_im = 16'sh8000; end
            2'd3: begin w_re = 16'shA57E; w_im = 16'shA57E; end
            default: begin w_re = 16'sh0000; w_im = 16'sh0000; end
        endcase
    end

endmodule
