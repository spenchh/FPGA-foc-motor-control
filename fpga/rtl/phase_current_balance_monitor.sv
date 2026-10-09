`timescale 1ns / 1ps

module phase_current_balance_monitor #(
    parameter WIDTH = 16,
    parameter BALANCE_WIDTH = WIDTH + 2
) (
    input  wire                             sample_valid,
    input  wire signed [WIDTH-1:0]         ia_q,
    input  wire signed [WIDTH-1:0]         ib_q,
    input  wire signed [WIDTH-1:0]         ic_q,
    input  wire signed [BALANCE_WIDTH-1:0] balance_limit_q,
    output reg  signed [BALANCE_WIDTH-1:0] balance_error_q,
    output reg  signed [BALANCE_WIDTH-1:0] balance_abs_q,
    output reg                             balance_out_of_range
);

    reg signed [BALANCE_WIDTH-1:0] ia_ext;
    reg signed [BALANCE_WIDTH-1:0] ib_ext;
    reg signed [BALANCE_WIDTH-1:0] ic_ext;
    reg signed [BALANCE_WIDTH-1:0] limit_abs_q;

    always @* begin
        ia_ext = {{(BALANCE_WIDTH-WIDTH){ia_q[WIDTH-1]}}, ia_q};
        ib_ext = {{(BALANCE_WIDTH-WIDTH){ib_q[WIDTH-1]}}, ib_q};
        ic_ext = {{(BALANCE_WIDTH-WIDTH){ic_q[WIDTH-1]}}, ic_q};

        balance_error_q = ia_ext + ib_ext + ic_ext;

        if (balance_error_q < 0) begin
            balance_abs_q = -balance_error_q;
        end else begin
            balance_abs_q = balance_error_q;
        end

        if (balance_limit_q < 0) begin
            limit_abs_q = -balance_limit_q;
        end else begin
            limit_abs_q = balance_limit_q;
        end

        balance_out_of_range = sample_valid && (balance_abs_q > limit_abs_q);
    end

endmodule
