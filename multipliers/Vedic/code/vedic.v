//=====================================================================
// 16x16 Unsigned Vedic Multiplier (Urdhva Tiryagbhyam)
// Hierarchy: 16x16 -> 8x8 -> 4x4
// Includes a Basys3 hardware top module.
//=====================================================================

module vedic_mult_4x4 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [7:0] p
);
    assign p = a * b;
endmodule

module vedic_mult_8x8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [15:0] p
);
    wire [3:0] ah = a[7:4];
    wire [3:0] al = a[3:0];
    wire [3:0] bh = b[7:4];
    wire [3:0] bl = b[3:0];

    wire [7:0] p_hh, p_hl, p_lh, p_ll;
    wire [8:0] mid;

    vedic_mult_4x4 m_hh (.a(ah), .b(bh), .p(p_hh));
    vedic_mult_4x4 m_hl (.a(ah), .b(bl), .p(p_hl));
    vedic_mult_4x4 m_lh (.a(al), .b(bh), .p(p_lh));
    vedic_mult_4x4 m_ll (.a(al), .b(bl), .p(p_ll));

    assign mid = {1'b0, p_hl} + {1'b0, p_lh};

    assign p = ({8'b0, p_hh} << 8) +
               ({7'b0, mid} << 4) +
               {8'b0, p_ll};
endmodule

module vedic_multiplier (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [31:0] product
);
    wire [7:0] ah = a[15:8];
    wire [7:0] al = a[7:0];
    wire [7:0] bh = b[15:8];
    wire [7:0] bl = b[7:0];

    wire [15:0] p_hh, p_hl, p_lh, p_ll;
    wire [16:0] mid;

    vedic_mult_8x8 m_hh (.a(ah), .b(bh), .p(p_hh));
    vedic_mult_8x8 m_hl (.a(ah), .b(bl), .p(p_hl));
    vedic_mult_8x8 m_lh (.a(al), .b(bh), .p(p_lh));
    vedic_mult_8x8 m_ll (.a(al), .b(bl), .p(p_ll));

    assign mid = {1'b0, p_hl} + {1'b0, p_lh};

    assign product = ({16'b0, p_hh} << 16) +
                     ({15'b0, mid} << 8) +
                     {16'b0, p_ll};
endmodule

//=====================================================================
// Basys3 Hardware Top
//
// First BTNU press : store A from SW[15:0]
// Second BTNU press: store B from SW[15:0]
// LEDs             : product[15:0]
// BTNC              : reset
//=====================================================================
module top_vedic_multiplier (
    input  wire clk,
    input  wire btn_rst,
    input  wire btn_start,
    input  wire [15:0] sw,
    output wire [15:0] led
);
    reg [15:0] a_reg;
    reg [15:0] b_reg;
    reg b_phase;
    reg valid;

    wire [31:0] product;

    always @(posedge clk) begin
        if (btn_rst) begin
            a_reg   <= 16'b0;
            b_reg   <= 16'b0;
            b_phase <= 1'b0;
            valid   <= 1'b0;
        end
        else if (btn_start) begin
            if (!b_phase) begin
                a_reg   <= sw;
                b_phase <= 1'b1;
                valid   <= 1'b0;
            end
            else begin
                b_reg   <= sw;
                valid   <= 1'b1;
            end
        end
    end

    vedic_multiplier U_VEDIC (
        .a(a_reg),
        .b(b_reg),
        .product(product)
    );

    assign led = valid ? product[15:0] : 16'b0;
endmodule
