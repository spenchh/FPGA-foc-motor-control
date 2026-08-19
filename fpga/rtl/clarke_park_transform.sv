`timescale 1ns / 1ps

module clarke_park_transform #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS = 15,
    parameter signed [DATA_WIDTH-1:0] INV_SQRT3_Q = 16'sd18919
) (
    input  logic                         clk,
    input  logic                         rst,
    input  logic                         sample_valid,
    input  logic signed [DATA_WIDTH-1:0] ia_q,
    input  logic signed [DATA_WIDTH-1:0] ib_q,
    input  logic signed [DATA_WIDTH-1:0] ic_q,
    input  logic signed [DATA_WIDTH-1:0] sin_theta_q,
    input  logic signed [DATA_WIDTH-1:0] cos_theta_q,
    output logic                          transform_valid,
    output logic signed [DATA_WIDTH-1:0] i_alpha_q,
    output logic signed [DATA_WIDTH-1:0] i_beta_q,
    output logic signed [DATA_WIDTH-1:0] i_d_q,
    output logic signed [DATA_WIDTH-1:0] i_q_q,
    output logic                          input_balance_warning
);

    localparam PRODUCT_WIDTH = 2 * DATA_WIDTH;
    localparam SUM_WIDTH = PRODUCT_WIDTH + 1;

    localparam signed [SUM_WIDTH-1:0] OUT_MAX =
        ({{(SUM_WIDTH-1){1'b0}}, 1'b1} <<< (DATA_WIDTH-1)) - 1'b1;
    localparam signed [SUM_WIDTH-1:0] OUT_MIN =
        -({{(SUM_WIDTH-1){1'b0}}, 1'b1} <<< (DATA_WIDTH-1));

    logic v1, v2, v3;
    logic balance_s1, balance_s2, balance_s3;
    logic signed [DATA_WIDTH-1:0] alpha_s1, alpha_s2, alpha_s3;
    logic signed [DATA_WIDTH-1:0] sin_s1, sin_s2;
    logic signed [DATA_WIDTH-1:0] cos_s1, cos_s2;
    logic signed [DATA_WIDTH:0] beta_delta_s1;
    logic signed [PRODUCT_WIDTH:0] beta_prod_s2;
    logic signed [PRODUCT_WIDTH-1:0] alpha_cos_s3;
    logic signed [PRODUCT_WIDTH-1:0] alpha_sin_s3;
    logic signed [PRODUCT_WIDTH-1:0] beta_cos_s3;
    logic signed [PRODUCT_WIDTH-1:0] beta_sin_s3;
    logic signed [DATA_WIDTH-1:0] beta_s3;

    wire signed [DATA_WIDTH+1:0] current_sum =
        {ia_q[DATA_WIDTH-1], ia_q[DATA_WIDTH-1], ia_q} +
        {ib_q[DATA_WIDTH-1], ib_q[DATA_WIDTH-1], ib_q} +
        {ic_q[DATA_WIDTH-1], ic_q[DATA_WIDTH-1], ic_q};

    wire signed [SUM_WIDTH-1:0] d_sum =
        {{(SUM_WIDTH-PRODUCT_WIDTH){alpha_cos_s3[PRODUCT_WIDTH-1]}}, alpha_cos_s3} +
        {{(SUM_WIDTH-PRODUCT_WIDTH){beta_sin_s3[PRODUCT_WIDTH-1]}}, beta_sin_s3};
    wire signed [SUM_WIDTH-1:0] q_sum =
        {{(SUM_WIDTH-PRODUCT_WIDTH){beta_cos_s3[PRODUCT_WIDTH-1]}}, beta_cos_s3} -
        {{(SUM_WIDTH-PRODUCT_WIDTH){alpha_sin_s3[PRODUCT_WIDTH-1]}}, alpha_sin_s3};

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

    function signed [DATA_WIDTH-1:0] sat_product;
        input signed [PRODUCT_WIDTH:0] value;
        logic signed [SUM_WIDTH-1:0] value_ext;
        begin
            value_ext = value;
            sat_product = sat_sum(value_ext <<< FRAC_BITS);
        end
    endfunction

    always_ff @(posedge clk) begin
        if (rst) begin
            v1 <= 1'b0;
            v2 <= 1'b0;
            v3 <= 1'b0;
            transform_valid <= 1'b0;
            balance_s1 <= 1'b0;
            balance_s2 <= 1'b0;
            balance_s3 <= 1'b0;
            alpha_s1 <= 0;
            alpha_s2 <= 0;
            alpha_s3 <= 0;
            beta_delta_s1 <= 0;
            beta_prod_s2 <= 0;
            beta_s3 <= 0;
            sin_s1 <= 0;
            sin_s2 <= 0;
            cos_s1 <= 0;
            cos_s2 <= 0;
            alpha_cos_s3 <= 0;
            alpha_sin_s3 <= 0;
            beta_cos_s3 <= 0;
            beta_sin_s3 <= 0;
            i_alpha_q <= 0;
            i_beta_q <= 0;
            i_d_q <= 0;
            i_q_q <= 0;
            input_balance_warning <= 1'b0;
        end else begin
            v1 <= sample_valid;
            v2 <= v1;
            v3 <= v2;
            transform_valid <= v3;

            if (sample_valid) begin
                alpha_s1 <= ia_q;
                beta_delta_s1 <= {ib_q[DATA_WIDTH-1], ib_q} -
                    {ic_q[DATA_WIDTH-1], ic_q};
                sin_s1 <= sin_theta_q;
                cos_s1 <= cos_theta_q;
                balance_s1 <= |current_sum;
            end

            if (v1) begin
                alpha_s2 <= alpha_s1;
                beta_prod_s2 <= beta_delta_s1 * INV_SQRT3_Q;
                sin_s2 <= sin_s1;
                cos_s2 <= cos_s1;
                balance_s2 <= balance_s1;
            end

            if (v2) begin
                alpha_s3 <= alpha_s2;
                beta_s3 <= sat_product(beta_prod_s2 >>> FRAC_BITS);
                alpha_cos_s3 <= alpha_s2 * cos_s2;
                alpha_sin_s3 <= alpha_s2 * sin_s2;
                beta_cos_s3 <= sat_product(beta_prod_s2 >>> FRAC_BITS) * cos_s2;
                beta_sin_s3 <= sat_product(beta_prod_s2 >>> FRAC_BITS) * sin_s2;
                balance_s3 <= balance_s2;
            end

            if (v3) begin
                i_alpha_q <= alpha_s3;
                i_beta_q <= beta_s3;
                i_d_q <= sat_sum(d_sum);
                i_q_q <= sat_sum(q_sum);
                input_balance_warning <= balance_s3;
            end
        end
    end

endmodule
