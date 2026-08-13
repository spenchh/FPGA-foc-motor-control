`timescale 1ns / 1ps

module alpha_beta_to_duty #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS = 15,
    parameter COUNTER_WIDTH = 16,
    parameter signed [DATA_WIDTH-1:0] NEG_HALF_Q = -16'sd16384,
    parameter signed [DATA_WIDTH-1:0] SQRT3_OVER_2_Q = 16'sd28378
) (
    input  wire                         clk,
    input  wire                         rst,
    input  wire                         sample_valid,
    input  wire signed [DATA_WIDTH-1:0] v_alpha_q,
    input  wire signed [DATA_WIDTH-1:0] v_beta_q,
    input  wire [COUNTER_WIDTH-1:0]     period,
    output reg                          duty_valid,
    output reg  [COUNTER_WIDTH-1:0]     duty_a,
    output reg  [COUNTER_WIDTH-1:0]     duty_b,
    output reg  [COUNTER_WIDTH-1:0]     duty_c
);

    localparam PRODUCT_WIDTH = 2 * DATA_WIDTH;
    localparam PHASE_WIDTH = DATA_WIDTH + 2;
    localparam DUTY_PRODUCT_WIDTH = PHASE_WIDTH + COUNTER_WIDTH;

    reg v1, v2;
    reg [COUNTER_WIDTH-1:0] period_s1, period_s2;
    reg signed [DATA_WIDTH-1:0] alpha_s1;
    reg signed [PRODUCT_WIDTH-1:0] alpha_half_mult_s1;
    reg signed [PRODUCT_WIDTH-1:0] beta_sqrt_mult_s1;
    reg signed [PHASE_WIDTH-1:0] phase_a_s2;
    reg signed [PHASE_WIDTH-1:0] phase_b_s2;
    reg signed [PHASE_WIDTH-1:0] phase_c_s2;

    wire signed [PRODUCT_WIDTH-1:0] alpha_half_mult = v_alpha_q * NEG_HALF_Q;
    wire signed [PRODUCT_WIDTH-1:0] beta_sqrt_mult = v_beta_q * SQRT3_OVER_2_Q;

    wire signed [DATA_WIDTH-1:0] alpha_half_q =
        alpha_half_mult_s1 >>> FRAC_BITS;
    wire signed [DATA_WIDTH-1:0] beta_sqrt_q =
        beta_sqrt_mult_s1 >>> FRAC_BITS;

    function [COUNTER_WIDTH-1:0] phase_to_duty;
        input signed [PHASE_WIDTH-1:0] phase_q;
        input [COUNTER_WIDTH-1:0] period_in;
        reg signed [DUTY_PRODUCT_WIDTH-1:0] phase_ext;
        reg signed [DUTY_PRODUCT_WIDTH-1:0] period_ext;
        reg signed [DUTY_PRODUCT_WIDTH-1:0] midpoint_ext;
        reg signed [DUTY_PRODUCT_WIDTH-1:0] delta_counts;
        reg signed [DUTY_PRODUCT_WIDTH-1:0] duty_ext;
        begin
            phase_ext = {{(DUTY_PRODUCT_WIDTH-PHASE_WIDTH){phase_q[PHASE_WIDTH-1]}}, phase_q};
            period_ext = {{(DUTY_PRODUCT_WIDTH-COUNTER_WIDTH){1'b0}}, period_in};
            midpoint_ext = period_ext >>> 1;
            delta_counts = (phase_ext * period_ext) >>> (FRAC_BITS + 1);
            duty_ext = midpoint_ext + delta_counts;

            if (duty_ext < 0)
                phase_to_duty = {COUNTER_WIDTH{1'b0}};
            else if (duty_ext > period_ext)
                phase_to_duty = period_in;
            else
                phase_to_duty = duty_ext[COUNTER_WIDTH-1:0];
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            v1 <= 1'b0;
            v2 <= 1'b0;
            duty_valid <= 1'b0;
            period_s1 <= 0;
            period_s2 <= 0;
            alpha_s1 <= 0;
            alpha_half_mult_s1 <= 0;
            beta_sqrt_mult_s1 <= 0;
            phase_a_s2 <= 0;
            phase_b_s2 <= 0;
            phase_c_s2 <= 0;
            duty_a <= 0;
            duty_b <= 0;
            duty_c <= 0;
        end else begin
            v1 <= sample_valid;
            v2 <= v1;
            duty_valid <= v2;

            if (sample_valid) begin
                alpha_s1 <= v_alpha_q;
                alpha_half_mult_s1 <= alpha_half_mult;
                beta_sqrt_mult_s1 <= beta_sqrt_mult;
                period_s1 <= period;
            end

            if (v1) begin
                phase_a_s2 <= {{(PHASE_WIDTH-DATA_WIDTH){alpha_s1[DATA_WIDTH-1]}}, alpha_s1};
                phase_b_s2 <=
                    {{(PHASE_WIDTH-DATA_WIDTH){alpha_half_q[DATA_WIDTH-1]}}, alpha_half_q} +
                    {{(PHASE_WIDTH-DATA_WIDTH){beta_sqrt_q[DATA_WIDTH-1]}}, beta_sqrt_q};
                phase_c_s2 <=
                    {{(PHASE_WIDTH-DATA_WIDTH){alpha_half_q[DATA_WIDTH-1]}}, alpha_half_q} -
                    {{(PHASE_WIDTH-DATA_WIDTH){beta_sqrt_q[DATA_WIDTH-1]}}, beta_sqrt_q};
                period_s2 <= period_s1;
            end

            if (v2) begin
                duty_a <= phase_to_duty(phase_a_s2, period_s2);
                duty_b <= phase_to_duty(phase_b_s2, period_s2);
                duty_c <= phase_to_duty(phase_c_s2, period_s2);
            end
        end
    end

endmodule
