`timescale 1ns / 1ps

module inverse_park_transform #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS = 15
) (
    input  logic                         clk,
    input  logic                         rst,
    input  logic                         sample_valid,
    input  logic signed [DATA_WIDTH-1:0] v_d_q,
    input  logic signed [DATA_WIDTH-1:0] v_q_q,
    input  logic signed [DATA_WIDTH-1:0] sin_theta_q,
    input  logic signed [DATA_WIDTH-1:0] cos_theta_q,
    output logic                          inverse_valid,
    output logic signed [DATA_WIDTH-1:0]  v_alpha_q,
    output logic signed [DATA_WIDTH-1:0]  v_beta_q
);

    localparam PRODUCT_WIDTH = 2 * DATA_WIDTH;
    localparam SUM_WIDTH = PRODUCT_WIDTH + 1;
    localparam signed [SUM_WIDTH-1:0] OUT_MAX =
        ({{(SUM_WIDTH-1){1'b0}}, 1'b1} <<< (DATA_WIDTH-1)) - 1'b1;
    localparam signed [SUM_WIDTH-1:0] OUT_MIN =
        -({{(SUM_WIDTH-1){1'b0}}, 1'b1} <<< (DATA_WIDTH-1));

    logic v1;
    logic signed [PRODUCT_WIDTH-1:0] vd_cos_s1, vq_sin_s1;
    logic signed [PRODUCT_WIDTH-1:0] vd_sin_s1, vq_cos_s1;

    wire signed [SUM_WIDTH-1:0] alpha_sum =
        {{(SUM_WIDTH-PRODUCT_WIDTH){vd_cos_s1[PRODUCT_WIDTH-1]}}, vd_cos_s1} -
        {{(SUM_WIDTH-PRODUCT_WIDTH){vq_sin_s1[PRODUCT_WIDTH-1]}}, vq_sin_s1};
    wire signed [SUM_WIDTH-1:0] beta_sum =
        {{(SUM_WIDTH-PRODUCT_WIDTH){vd_sin_s1[PRODUCT_WIDTH-1]}}, vd_sin_s1} +
        {{(SUM_WIDTH-PRODUCT_WIDTH){vq_cos_s1[PRODUCT_WIDTH-1]}}, vq_cos_s1};

    function signed [DATA_WIDTH-1:0] sat_sum;
        input signed [SUM_WIDTH-1:0] value;
        logic signed [SUM_WIDTH-1:0] shifted;
        begin
            shifted = value >>> FRAC_BITS;

            if (shifted > OUT_MAX)
                sat_sum = {1'b0, {(DATA_WIDTH-1){1'b1}}};
            else if (shifted < OUT_MIN)
                sat_sum = {1'b1, {(DATA_WIDTH-1){1'b0}}};
            else
                sat_sum = shifted[DATA_WIDTH-1:0];
        end
    endfunction

    always_ff @(posedge clk) begin
        if (rst) begin
            v1 <= 1'b0;
            inverse_valid <= 1'b0;
            vd_cos_s1 <= 0;
            vq_sin_s1 <= 0;
            vd_sin_s1 <= 0;
            vq_cos_s1 <= 0;
            v_alpha_q <= 0;
            v_beta_q <= 0;
        end else begin
            v1 <= sample_valid;
            inverse_valid <= v1;

            if (sample_valid) begin
                vd_cos_s1 <= v_d_q * cos_theta_q;
                vq_sin_s1 <= v_q_q * sin_theta_q;
                vd_sin_s1 <= v_d_q * sin_theta_q;
                vq_cos_s1 <= v_q_q * cos_theta_q;
            end

            if (v1) begin
                v_alpha_q <= sat_sum(alpha_sum);
                v_beta_q <= sat_sum(beta_sum);
            end
        end
    end

endmodule
