`timescale 1ns/1ps

module tb_vedic_multiplier;

    reg [15:0] a, b;
    wire [31:0] product;
    integer errors;
    integer i;

    vedic_multiplier DUT (
        .a(a),
        .b(b),
        .product(product)
    );

    task run_check;
        input [15:0] ta;
        input [15:0] tb;
        reg [31:0] expected;
        begin
            a = ta;
            b = tb;
            #1;
            expected = ta * tb;

            if (product !== expected) begin
                errors = errors + 1;
                $display("FAIL: a=%0d b=%0d product=%0d expected=%0d",
                         ta, tb, product, expected);
            end
            else begin
                $display("PASS: a=%0d b=%0d product=%0d",
                         ta, tb, product);
            end
        end
    endtask

    initial begin
        errors = 0;
        a = 0;
        b = 0;

        run_check(16'd0,     16'd0);
        run_check(16'd1,     16'd1);
        run_check(16'hFFFF,  16'hFFFF);
        run_check(16'hFFFF,  16'd1);
        run_check(16'd12345, 16'd6789);
        run_check(16'h8000,  16'h8000);
        run_check(16'h5555,  16'hAAAA);

        for (i = 0; i < 200; i = i + 1)
            run_check($random, $random);

        if (errors == 0)
            $display("\n*** ALL TESTS PASSED ***");
        else
            $display("\n*** %0d TEST(S) FAILED ***", errors);

        $finish;
    end
endmodule
