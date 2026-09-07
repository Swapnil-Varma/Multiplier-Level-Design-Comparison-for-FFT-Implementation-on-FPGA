//=====================================================================
// Module      : array_multiplier
// Description : 16x16 unsigned Array Multiplier.
//               Generates 16 shifted partial products and accumulates
//               them row-by-row, mirroring the classic array-multiplier
//               hardware structure (a mesh of adders).
//=====================================================================
module array_multiplier (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output wire [31:0] product
);

    wire [31:0] pp  [0:15];   // 16 zero-extended, shifted partial products
    wire [31:0] sum [0:16];   // running accumulation (row-by-row)

    genvar i;

    generate
        for (i = 0; i < 16; i = i + 1) begin : GEN_PP
            // partial product row i = (b[i] ? a : 0) << i
            assign pp[i] = b[i] ? ({16'b0, a} << i) : 32'b0;
        end
    endgenerate

    assign sum[0] = 32'b0;

    generate
        for (i = 0; i < 16; i = i + 1) begin : GEN_ADD
            assign sum[i+1] = sum[i] + pp[i];
        end
    endgenerate

    assign product = sum[16];

endmodule
