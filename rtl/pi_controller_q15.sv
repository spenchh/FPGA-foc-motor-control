`timescale 1ns / 1ps

module pi_controller_q15 #(
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS = 15
) (
    input  logic                         clk,
    input  logic                         rst,
    input  logic                         enable,
    input  logic                         sample_valid,
    input  logic                         clear_integrator,
    input  logic signed [DATA_WIDTH-1:0] reference_q,
    input  logic signed [DATA_WIDTH-1:0] feedback_q,
    input  logic signed [DATA_WIDTH-1:0] kp_q,
    input  logic signed [DATA_WIDTH-1:0] ki_q,
    input  logic signed [DATA_WIDTH-1:0] output_min_q,
    input  logic signed [DATA_WIDTH-1:0] output_max_q,
    output logic                          control_valid,
    output logic signed [DATA_WIDTH-1:0]  output_q,
    output logic signed [DATA_WIDTH-1:0]  error_q,
    output logic signed [DATA_WIDTH-1:0]  integrator_q
);

    localparam ERROR_WIDTH = DATA_WIDTH + 1;
    localparam PRODUCT_WIDTH = ERROR_WIDTH + DATA_WIDTH;

    logic v1, v2, v3;
    logic clr_s1, clr_s2;
    logic signed [ERROR_WIDTH-1:0] err_s1;
    logic signed [DATA_WIDTH-1:0] min_s1, max_s1, min_s2, max_s2, min_s3, max_s3;
    logic signed [PRODUCT_WIDTH-1:0] p_mult_s2, i_mult_s2;
    logic signed [DATA_WIDTH-1:0] integrator_s3;
    logic signed [PRODUCT_WIDTH-1:0] p_term_s3;
    wire signed [PRODUCT_WIDTH-1:0] integrator_ext =
        {{(PRODUCT_WIDTH-DATA_WIDTH){integrator_q[DATA_WIDTH-1]}}, integrator_q};
    wire signed [PRODUCT_WIDTH-1:0] i_step_s2 = i_mult_s2 >>> FRAC_BITS;
    wire signed [DATA_WIDTH-1:0] integrator_next_q =
        clr_s2 ? {DATA_WIDTH{1'b0}} :
        clamp_data(integrator_ext + i_step_s2, min_s2, max_s2);
    wire signed [PRODUCT_WIDTH-1:0] integrator_s3_ext =
        {{(PRODUCT_WIDTH-DATA_WIDTH){integrator_s3[DATA_WIDTH-1]}}, integrator_s3};

    wire signed [ERROR_WIDTH-1:0] err_now =
        {reference_q[DATA_WIDTH-1], reference_q} -
        {feedback_q[DATA_WIDTH-1], feedback_q};

    function signed [DATA_WIDTH-1:0] clamp_data;
        input signed [PRODUCT_WIDTH-1:0] value;
        input signed [DATA_WIDTH-1:0] lo;
        input signed [DATA_WIDTH-1:0] hi;
        logic signed [PRODUCT_WIDTH-1:0] lo_ext;
        logic signed [PRODUCT_WIDTH-1:0] hi_ext;
        begin
            lo_ext = {{(PRODUCT_WIDTH-DATA_WIDTH){lo[DATA_WIDTH-1]}}, lo};
            hi_ext = {{(PRODUCT_WIDTH-DATA_WIDTH){hi[DATA_WIDTH-1]}}, hi};

            if (value > hi_ext)
                clamp_data = hi;
            else if (value < lo_ext)
                clamp_data = lo;
            else
                clamp_data = value[DATA_WIDTH-1:0];
        end
    endfunction

    function signed [DATA_WIDTH-1:0] sat_error;
        input signed [ERROR_WIDTH-1:0] value;
        logic signed [ERROR_WIDTH-1:0] min_error;
        logic signed [ERROR_WIDTH-1:0] max_error;
        begin
            max_error = {{(ERROR_WIDTH-DATA_WIDTH){1'b0}}, 1'b0, {(DATA_WIDTH-1){1'b1}}};
            min_error = {{(ERROR_WIDTH-DATA_WIDTH){1'b1}}, 1'b1, {(DATA_WIDTH-1){1'b0}}};

            if (value > max_error)
                sat_error = max_error[DATA_WIDTH-1:0];
            else if (value < min_error)
                sat_error = min_error[DATA_WIDTH-1:0];
            else
                sat_error = value[DATA_WIDTH-1:0];
        end
    endfunction

    always_ff @(posedge clk) begin
        if (rst) begin
            v1 <= 1'b0;
            v2 <= 1'b0;
            v3 <= 1'b0;
            control_valid <= 1'b0;
            clr_s1 <= 1'b0;
            clr_s2 <= 1'b0;
            err_s1 <= 0;
            min_s1 <= 0;
            max_s1 <= 0;
            min_s2 <= 0;
            max_s2 <= 0;
            min_s3 <= 0;
            max_s3 <= 0;
            p_mult_s2 <= 0;
            i_mult_s2 <= 0;
            integrator_s3 <= 0;
            p_term_s3 <= 0;
            output_q <= 0;
            error_q <= 0;
            integrator_q <= 0;
        end else begin
            v1 <= sample_valid && enable;
            v2 <= v1;
            v3 <= v2;
            control_valid <= v3;

            if (!enable) begin
                v1 <= 1'b0;
                v2 <= 1'b0;
                v3 <= 1'b0;
                control_valid <= 1'b0;
                output_q <= 0;
                integrator_q <= 0;
            end

            if (sample_valid && enable) begin
                err_s1 <= err_now;
                clr_s1 <= clear_integrator;
                min_s1 <= output_min_q;
                max_s1 <= output_max_q;
            end

            if (v1) begin
                p_mult_s2 <= err_s1 * kp_q;
                i_mult_s2 <= err_s1 * ki_q;
                clr_s2 <= clr_s1;
                min_s2 <= min_s1;
                max_s2 <= max_s1;
                error_q <= sat_error(err_s1);
            end

            if (v2) begin
                integrator_q <= integrator_next_q;
                integrator_s3 <= integrator_next_q;
                p_term_s3 <= p_mult_s2 >>> FRAC_BITS;
                min_s3 <= min_s2;
                max_s3 <= max_s2;
            end

            if (v3) begin
                output_q <= clamp_data(
                    p_term_s3 + integrator_s3_ext,
                    min_s3,
                    max_s3
                );
            end
        end
    end

endmodule
