`timescale 1ns / 1ps

module adc_current_scaler_q15 #(
    parameter ADC_WIDTH = 12,
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS = 15,
    parameter SCALE_WIDTH = 24
) (
    input  logic                         clk,
    input  logic                         rst,
    input  logic                         sample_valid,
    input  logic [ADC_WIDTH-1:0]         adc_a,
    input  logic [ADC_WIDTH-1:0]         adc_b,
    input  logic [ADC_WIDTH-1:0]         adc_c,
    input  logic [ADC_WIDTH-1:0]         offset_a,
    input  logic [ADC_WIDTH-1:0]         offset_b,
    input  logic [ADC_WIDTH-1:0]         offset_c,
    input  logic signed [SCALE_WIDTH-1:0] scale_q,
    output logic                          current_valid,
    output logic signed [DATA_WIDTH-1:0]  ia_q,
    output logic signed [DATA_WIDTH-1:0]  ib_q,
    output logic signed [DATA_WIDTH-1:0]  ic_q
);

    localparam DELTA_WIDTH = ADC_WIDTH + 1;
    localparam PRODUCT_WIDTH = DELTA_WIDTH + SCALE_WIDTH;
    localparam signed [PRODUCT_WIDTH-1:0] OUT_MAX =
        ({{(PRODUCT_WIDTH-1){1'b0}}, 1'b1} <<< (DATA_WIDTH-1)) - 1'b1;
    localparam signed [PRODUCT_WIDTH-1:0] OUT_MIN =
        -({{(PRODUCT_WIDTH-1){1'b0}}, 1'b1} <<< (DATA_WIDTH-1));

    logic v1, v2;
    logic signed [DELTA_WIDTH-1:0] da_s1, db_s1, dc_s1;
    logic signed [SCALE_WIDTH-1:0] scale_s1;
    logic signed [PRODUCT_WIDTH-1:0] pa_s2, pb_s2, pc_s2;

    function signed [DATA_WIDTH-1:0] sat_q;
        input signed [PRODUCT_WIDTH-1:0] value;
        logic signed [PRODUCT_WIDTH-1:0] shifted;
        begin
            shifted = value >>> FRAC_BITS;

            if (shifted > OUT_MAX)
                sat_q = {1'b0, {(DATA_WIDTH-1){1'b1}}};
            else if (shifted < OUT_MIN)
                sat_q = {1'b1, {(DATA_WIDTH-1){1'b0}}};
            else
                sat_q = shifted[DATA_WIDTH-1:0];
        end
    endfunction

    always_ff @(posedge clk) begin
        if (rst) begin
            v1 <= 1'b0;
            v2 <= 1'b0;
            current_valid <= 1'b0;
            da_s1 <= 0;
            db_s1 <= 0;
            dc_s1 <= 0;
            scale_s1 <= 0;
            pa_s2 <= 0;
            pb_s2 <= 0;
            pc_s2 <= 0;
            ia_q <= 0;
            ib_q <= 0;
            ic_q <= 0;
        end else begin
            v1 <= sample_valid;
            v2 <= v1;
            current_valid <= v2;

            if (sample_valid) begin
                da_s1 <= {1'b0, adc_a} - {1'b0, offset_a};
                db_s1 <= {1'b0, adc_b} - {1'b0, offset_b};
                dc_s1 <= {1'b0, adc_c} - {1'b0, offset_c};
                scale_s1 <= scale_q;
            end

            if (v1) begin
                pa_s2 <= da_s1 * scale_s1;
                pb_s2 <= db_s1 * scale_s1;
                pc_s2 <= dc_s1 * scale_s1;
            end

            if (v2) begin
                ia_q <= sat_q(pa_s2);
                ib_q <= sat_q(pb_s2);
                ic_q <= sat_q(pc_s2);
            end
        end
    end

endmodule
