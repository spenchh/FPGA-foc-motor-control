`timescale 1ns / 1ps

module foc_synth_wrapper #(
    parameter ADC_WIDTH = 12,
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS = 15,
    parameter SCALE_WIDTH = 24,
    parameter COUNTER_WIDTH = 16,
    parameter BALANCE_WIDTH = DATA_WIDTH + 2
) (
    input  logic        clk,
    input  logic        rst,
    output logic [15:0] debug_sink
);

    logic enable_request;
    logic sample_valid;
    logic [15:0] angle_accum;
    logic [ADC_WIDTH-1:0] adc_ia;
    logic [ADC_WIDTH-1:0] adc_ib;
    logic [ADC_WIDTH-1:0] adc_ic;

    logic pwm_hi_a;
    logic pwm_lo_a;
    logic pwm_hi_b;
    logic pwm_lo_b;
    logic pwm_hi_c;
    logic pwm_lo_c;
    logic disable_cmd;
    logic pwm_enable;
    logic protection_latched;
    logic [3:0] status_code;
    logic signed [DATA_WIDTH-1:0] ia_q;
    logic signed [DATA_WIDTH-1:0] ib_q;
    logic signed [DATA_WIDTH-1:0] ic_q;
    logic signed [DATA_WIDTH-1:0] id_meas_q;
    logic signed [DATA_WIDTH-1:0] iq_meas_q;
    logic [COUNTER_WIDTH-1:0] duty_a;
    logic [COUNTER_WIDTH-1:0] duty_b;
    logic [COUNTER_WIDTH-1:0] duty_c;
    logic current_out_of_range;
    logic balance_out_of_range;
    logic configuration_error;

    always_ff @(posedge clk) begin
        if (rst) begin
            enable_request <= 1'b0;
            sample_valid <= 1'b0;
            angle_accum <= 16'd0;
            adc_ia <= 12'd2048;
            adc_ib <= 12'd2048;
            adc_ic <= 12'd2048;
        end else begin
            enable_request <= 1'b1;
            sample_valid <= 1'b1;
            angle_accum <= angle_accum + 16'd257;
            adc_ia <= 12'd2048 + angle_accum[11:0];
            adc_ib <= 12'd2048 - {1'b0, angle_accum[10:0]};
            adc_ic <= 12'd2048 + {2'b00, angle_accum[9:0]};
        end
    end

    (* keep_hierarchy = "yes", dont_touch = "yes" *)
    foc_current_loop_top #(
        .ADC_WIDTH(ADC_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .SCALE_WIDTH(SCALE_WIDTH),
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .BALANCE_WIDTH(BALANCE_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable_request(enable_request),
        .sample_valid(sample_valid),
        .adc_ia(adc_ia),
        .adc_ib(adc_ib),
        .adc_ic(adc_ic),
        .adc_offset_a(12'd2048),
        .adc_offset_b(12'd2048),
        .adc_offset_c(12'd2048),
        .current_scale_q(24'sd32768),
        .electrical_angle_q(angle_accum),
        .id_ref_q(16'sd0),
        .iq_ref_q(16'sd4096),
        .kp_d_q(16'sd16384),
        .ki_d_q(16'sd512),
        .kp_q_q(16'sd16384),
        .ki_q_q(16'sd512),
        .voltage_min_q(-16'sd16000),
        .voltage_max_q(16'sd16000),
        .current_limit_q(16'sd28000),
        .balance_limit_q(18'sd8000),
        .pwm_period(16'd1000),
        .nonoverlap_ticks(16'd2),
        .voltage_out_of_range(1'b0),
        .external_inhibit_request(1'b0),
        .clear_protection_latch(1'b0),
        .pwm_hi_a(pwm_hi_a),
        .pwm_lo_a(pwm_lo_a),
        .pwm_hi_b(pwm_hi_b),
        .pwm_lo_b(pwm_lo_b),
        .pwm_hi_c(pwm_hi_c),
        .pwm_lo_c(pwm_lo_c),
        .disable_cmd(disable_cmd),
        .pwm_enable(pwm_enable),
        .protection_latched(protection_latched),
        .status_code(status_code),
        .ia_q(ia_q),
        .ib_q(ib_q),
        .ic_q(ic_q),
        .id_meas_q(id_meas_q),
        .iq_meas_q(iq_meas_q),
        .duty_a(duty_a),
        .duty_b(duty_b),
        .duty_c(duty_c),
        .current_out_of_range(current_out_of_range),
        .balance_out_of_range(balance_out_of_range),
        .configuration_error(configuration_error)
    );

    always_comb begin
        debug_sink[0]  = pwm_hi_a;
        debug_sink[1]  = pwm_lo_a;
        debug_sink[2]  = pwm_hi_b;
        debug_sink[3]  = pwm_lo_b;
        debug_sink[4]  = pwm_hi_c;
        debug_sink[5]  = pwm_lo_c;
        debug_sink[6]  = disable_cmd;
        debug_sink[7]  = pwm_enable;
        debug_sink[8]  = protection_latched;
        debug_sink[9]  = current_out_of_range;
        debug_sink[10] = balance_out_of_range;
        debug_sink[11] = configuration_error;
        debug_sink[12] = ^status_code;
        debug_sink[13] = ^{ia_q, ib_q, ic_q};
        debug_sink[14] = ^{id_meas_q, iq_meas_q};
        debug_sink[15] = ^{duty_a, duty_b, duty_c};
    end

endmodule
