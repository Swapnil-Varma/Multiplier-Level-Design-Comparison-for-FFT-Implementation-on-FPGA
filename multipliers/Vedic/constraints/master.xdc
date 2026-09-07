//=====================================================================
// Vedic Multiplier (Urdhva Tiryagbhyam sutra) - 16x16 unsigned
// Built hierarchically: 16x16 <- four 8x8 blocks <- four 4x4 blocks.
//   For operands split into halves {Hi, Lo}:
//     P = (Hi_a*Hi_b)<<W + (Hi_a*Lo_b + Lo_a*Hi_b)<<(W/2) + Lo_a*Lo_b
//=====================================================================

// ---- Base case : 4x4 ----
module vedic_mult_4x4 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [7:0] p
);
    assign p = a * b;   // small enough for direct synthesis mapping
endmodule

// ---- 8x8 built from four 4x4 blocks ----
module vedic_mult_8x8 (
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    output wire [15:0] p
);
    wire [3:0] ah = a[7:4], al = a[3:0];
    wire [3:0] bh = b[7:4], bl = b[3:0];

    wire [7:0] p_hh, p_hl, p_lh, p_ll;

    vedic_mult_4x4 m_hh (.a(ah), .b(bh), .p(p_hh));
    vedic_mult_4x4 m_hl (.a(ah), .b(bl), .p(p_hl));
    vedic_mult_4x4 m_lh (.a(al), .b(bh), .p(p_lh));
    vedic_mult_4x4 m_ll (.a(al), .b(bl), .p(p_ll));

    wire [8:0] mid = {1'b0, p_hl} + {1'b0, p_lh};   // cross terms

    assign p = ({8'b0, p_hh} << 8) + ({7'b0, mid} << 4) + {8'b0, p_ll};
endmodule

// ---- 16x16 built from four 8x8 blocks ----
module vedic_multiplier (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [31:0] product
);
    wire [7:0] ah = a[15:8], al = a[7:0];
    wire [7:0] bh = b[15:8], bl = b[7:0];

    wire [15:0] p_hh, p_hl, p_lh, p_ll;

    vedic_mult_8x8 m_hh (.a(ah), .b(bh), .p(p_hh));
    vedic_mult_8x8 m_hl (.a(ah), .b(bl), .p(p_hl));
    vedic_mult_8x8 m_lh (.a(al), .b(bh), .p(p_lh));
    vedic_mult_8x8 m_ll (.a(al), .b(bl), .p(p_ll));

    wire [16:0] mid = {1'b0, p_hl} + {1'b0, p_lh};

    assign product = ({16'b0, p_hh} << 16) + ({15'b0, mid} << 8) + {16'b0, p_ll};
endmodule