`timescale 1ns / 1ps

module phase_current_limit_monitor #(
    parameter WIDTH = 16
) (
    input  wire                     sample_valid,
    input  wire signed [WIDTH-1:0] ia_q,
    input  wire signed [WIDTH-1:0] ib_q,
    input  wire signed [WIDTH-1:0] ic_q,
    input  wire signed [WIDTH-1:0] current_limit_q,
    output reg  [2:0]              phase_over_limit,
    output wire                    current_out_of_range
);

    reg signed [WIDTH-1:0] ia_abs_q;
    reg signed [WIDTH-1:0] ib_abs_q;
    reg signed [WIDTH-1:0] ic_abs_q;
    reg signed [WIDTH-1:0] limit_abs_q;

    assign current_out_of_range = |phase_over_limit;

    always @* begin
        ia_abs_q = (ia_q < 0) ? -ia_q : ia_q;
        ib_abs_q = (ib_q < 0) ? -ib_q : ib_q;
        ic_abs_q = (ic_q < 0) ? -ic_q : ic_q;
        limit_abs_q = (current_limit_q < 0) ? -current_limit_q : current_limit_q;

        phase_over_limit[0] = sample_valid && (ia_abs_q > limit_abs_q);
        phase_over_limit[1] = sample_valid && (ib_abs_q > limit_abs_q);
        phase_over_limit[2] = sample_valid && (ic_abs_q > limit_abs_q);
    end

endmodule
