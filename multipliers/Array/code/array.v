//=====================================================================
// Module      : array_multiplier
// Description : 16x16 unsigned combinational Array Multiplier
//=====================================================================
module array_multiplier (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [31:0] product
);

    wire [31:0] pp  [0:15];
    wire [31:0] sum [0:16];

    genvar i;

    // Generate shifted partial products
    generate
        for (i = 0; i < 16; i = i + 1) begin : GEN_PP
            assign pp[i] = b[i] ? ({16'b0, a} << i) : 32'b0;
        end
    endgenerate

    // Row-by-row accumulation
    assign sum[0] = 32'b0;

    generate
        for (i = 0; i < 16; i = i + 1) begin : GEN_ADD
            assign sum[i+1] = sum[i] + pp[i];
        end
    endgenerate

    assign product = sum[16];

endmodule


//=====================================================================
// Basys3 Top Module
//
// Operation:
//   1. Put operand A on SW[15:0]
//   2. Press BTNU (Start) -> A is stored
//   3. Put operand B on SW[15:0]
//   4. Press BTNU again -> B is stored and multiplication is performed
//   5. Product[15:0] is displayed on LD[15:0]
//      LD15 (MSB) is also enough to indicate that the product has upper bits.
//
// Reset: BTNC
//
// NOTE:
// The Basys3 has only 16 switches and 16 LEDs, so a complete 32-bit
// product cannot be displayed simultaneously. The full product is still
// calculated internally; LEDs show the lower 16 bits.
//=====================================================================
module top_array_multiplier (
    input  wire        clk,
    input  wire        btn_rst,
    input  wire        btn_start,
    input  wire [15:0] sw,
    output wire [15:0] led
);

    reg [15:0] a_reg;
    reg [15:0] b_reg;
    reg        load_b;
    reg        valid;

    wire [31:0] product;

    // Debounce is intentionally not included; for an assignment/demo,
    // release the button before pressing it again.
    always @(posedge clk) begin
        if (btn_rst) begin
            a_reg  <= 16'b0;
            b_reg  <= 16'b0;
            load_b <= 1'b0;
            valid  <= 1'b0;
        end
        else if (btn_start) begin
            if (!load_b) begin
                // First press stores A
                a_reg  <= sw;
                load_b <= 1'b1;
                valid  <= 1'b0;
            end
            else begin
                // Second press stores B
                b_reg <= sw;
                valid <= 1'b1;
            end
        end
    end

    array_multiplier U_ARRAY (
        .a(a_reg),
        .b(b_reg),
        .product(product)
    );

    // Show lower 16 product bits.
    // If valid=0, LEDs are off.
    assign led = valid ? product[15:0] : 16'b0;

endmodule
