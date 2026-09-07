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