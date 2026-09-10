//=====================================================================
// Module      : booth_multiplier
// Description : 16x16 SIGNED multiplier using Radix-2 Booth Algorithm.
//               Sequential implementation.
//               16 clock cycles per multiplication.
//               Controlled using start/done handshake.
//=====================================================================

module booth_multiplier (
    input  wire               clk,
    input  wire               rst,          // synchronous, active-high
    input  wire               start,

    input  wire signed [15:0] multiplicand, // M
    input  wire signed [15:0] multiplier,   // Q

    output reg signed [31:0]  product,
    output reg                done
);

    // ---------------------------------------------------------------
    // Booth registers
    // ---------------------------------------------------------------

    reg signed [16:0] A;       // Accumulator with guard/sign bit
    reg signed [16:0] M_ext;   // Sign-extended multiplicand
    reg        [15:0] Q;       // Multiplier
    reg               Q_1;     // Previous Q[0]

    reg [4:0] count;

    // ALU result
    reg signed [16:0] alu_out;

    // Combined Booth register after arithmetic right shift
    reg signed [33:0] shifted;

    // ---------------------------------------------------------------
    // State machine
    // ---------------------------------------------------------------

    localparam IDLE   = 2'd0;
    localparam RUN    = 2'd1;
    localparam FINISH = 2'd2;

    reg [1:0] state;

    // ---------------------------------------------------------------
    // Booth ALU
    //
    // Q[0] Q_1
    //
    // 01 -> A = A + M
    // 10 -> A = A - M
    // 00 -> No operation
    // 11 -> No operation
    // ---------------------------------------------------------------

    always @(*) begin

        case ({Q[0], Q_1})

            2'b01:
                alu_out = A + M_ext;

            2'b10:
                alu_out = A - M_ext;

            default:
                alu_out = A;

        endcase

        // Arithmetic right shift of:
        //
        // {A, Q, Q_1}
        //
        // Total width = 17 + 16 + 1 = 34 bits

        shifted = $signed({alu_out, Q, Q_1}) >>> 1;

    end

    // ---------------------------------------------------------------
    // Sequential controller
    // ---------------------------------------------------------------

    always @(posedge clk) begin

        if (rst) begin

            state   <= IDLE;
            done    <= 1'b0;
            product <= 32'b0;

            A       <= 17'b0;
            M_ext   <= 17'b0;
            Q       <= 16'b0;
            Q_1     <= 1'b0;
            count   <= 5'b0;

        end

        else begin

            case (state)

                // ---------------------------------------------------
                // IDLE
                // ---------------------------------------------------

                IDLE: begin

                    done <= 1'b0;

                    if (start) begin

                        A     <= 17'b0;

                        // Sign-extend multiplicand
                        M_ext <= {multiplicand[15], multiplicand};

                        Q     <= multiplier;

                        Q_1   <= 1'b0;

                        // 16 Booth iterations
                        count <= 5'd16;

                        state <= RUN;

                    end

                end

                // ---------------------------------------------------
                // RUN
                // ---------------------------------------------------

                RUN: begin

                    // Perform Booth operation and arithmetic shift
                    {A, Q, Q_1} <= shifted;

                    count <= count - 1'b1;

                    if (count == 5'd1)
                        state <= FINISH;

                end

                // ---------------------------------------------------
                // FINISH
                // ---------------------------------------------------

                FINISH: begin

                    // Final 32-bit signed product
                    product <= $signed({A[15:0], Q});

                    done  <= 1'b1;

                    state <= IDLE;

                end

                // ---------------------------------------------------
                // Safety
                // ---------------------------------------------------

                default: begin

                    state <= IDLE;
                    done  <= 1'b0;

                end

            endcase

        end

    end

endmodule


//=====================================================================
// Basys3 Hardware Top - 16x16 Signed Booth Multiplier
//
// IMPORTANT:
//   This wrapper waits one clock after capturing B before asserting START.
//   This is required because B is stored using a nonblocking assignment.
//
// Hardware operation:
//   BTNC -> reset
//   Set SW[15:0] = signed A -> press/release BTNU
//   Set SW[15:0] = signed B -> press/release BTNU
//   Booth multiplier runs for 16 clock cycles
//   LD[15:0] = lower 16 bits of the final 32-bit product
//
// Signed input examples:
//   +5  = 16'h0005
//   -5  = 16'hFFFB
//
// The full 32-bit product is retained internally.
//=====================================================================
module top_booth_multiplier (
    input  wire        clk,
    input  wire        btn_rst,
    input  wire        btn_start,
    input  wire [15:0] sw,
    output wire [15:0] led
);

    reg signed [15:0] multiplicand_reg;
    reg signed [15:0] multiplier_reg;

    // 0 = waiting for A
    // 1 = waiting for B
    // 2 = B captured; start Booth on next clock
    reg [1:0] phase;

    reg btn_start_d;
    wire btn_start_rise = btn_start & ~btn_start_d;

    reg booth_start;
    reg result_valid;
    reg [15:0] result_low;

    wire signed [31:0] booth_product;
    wire booth_done;

    always @(posedge clk) begin
        if (btn_rst) begin
            multiplicand_reg <= 16'sd0;
            multiplier_reg   <= 16'sd0;
            phase            <= 2'd0;
            btn_start_d      <= 1'b0;
            booth_start      <= 1'b0;
            result_valid     <= 1'b0;
            result_low       <= 16'b0;
        end
        else begin
            // Store previous button state for rising-edge detection.
            btn_start_d <= btn_start;

            // START is a one-clock pulse.
            booth_start <= 1'b0;

            // A new operation invalidates the previous displayed result.
            if (btn_start_rise && (phase == 2'd0 ||
                                   phase == 2'd1))
                result_valid <= 1'b0;

            // ---------------------------------------------------------
            // Capture operands and start only AFTER B has been stored.
            // ---------------------------------------------------------
            case (phase)
                2'd0: begin
                    if (btn_start_rise) begin
                        multiplicand_reg <= $signed(sw);
                        phase <= 2'd1;
                    end
                end

                2'd1: begin
                    if (btn_start_rise) begin
                        multiplier_reg <= $signed(sw);
                        phase <= 2'd2;
                    end
                end

                2'd2: begin
                    // B is already registered from the previous clock.
                    booth_start <= 1'b1;
                    phase <= 2'd3;
                end

                2'd3: begin
                    // Wait for Booth to finish.
                    if (booth_done) begin
                        result_low   <= booth_product[15:0];
                        result_valid <= 1'b1;
                        phase        <= 2'd0;
                    end
                end

                default: phase <= 2'd0;
            endcase

            // Defensive result capture in case DONE occurs in this state.
            if (booth_done) begin
                result_low   <= booth_product[15:0];
                result_valid <= 1'b1;
            end
        end
    end

    booth_multiplier U_BOOTH (
        .clk          (clk),
        .rst          (btn_rst),
        .start        (booth_start),
        .multiplicand (multiplicand_reg),
        .multiplier   (multiplier_reg),
        .product      (booth_product),
        .done         (booth_done)
    );

    // Hold the result on LEDs; don't gate directly with the one-cycle DONE.
    assign led = result_valid ? result_low : 16'b0;

endmodule
