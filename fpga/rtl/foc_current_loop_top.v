`timescale 1ns / 1ps

module foc_current_loop_top #(
    parameter ADC_WIDTH = 12,
    parameter DATA_WIDTH = 16,
    parameter FRAC_BITS = 15,
    parameter SCALE_WIDTH = 24,
    parameter COUNTER_WIDTH = 16,
    parameter BALANCE_WIDTH = DATA_WIDTH + 2
) (
    input  wire                         clk,
    input  wire                         rst,
    input  wire                         enable_request,
    input  wire                         sample_valid,
    input  wire [ADC_WIDTH-1:0]         adc_ia,
    input  wire [ADC_WIDTH-1:0]         adc_ib,
    input  wire [ADC_WIDTH-1:0]         adc_ic,
    input  wire [ADC_WIDTH-1:0]         adc_offset_a,
    input  wire [ADC_WIDTH-1:0]         adc_offset_b,
    input  wire [ADC_WIDTH-1:0]         adc_offset_c,
    input  wire signed [SCALE_WIDTH-1:0] current_scale_q,
    input  wire [15:0]                  electrical_angle_q,
    input  wire signed [DATA_WIDTH-1:0] id_ref_q,
    input  wire signed [DATA_WIDTH-1:0] iq_ref_q,
    input  wire signed [DATA_WIDTH-1:0] kp_d_q,
    input  wire signed [DATA_WIDTH-1:0] ki_d_q,
    input  wire signed [DATA_WIDTH-1:0] kp_q_q,
    input  wire signed [DATA_WIDTH-1:0] ki_q_q,
    input  wire signed [DATA_WIDTH-1:0] voltage_min_q,
    input  wire signed [DATA_WIDTH-1:0] voltage_max_q,
    input  wire signed [DATA_WIDTH-1:0] current_limit_q,
    input  wire signed [BALANCE_WIDTH-1:0] balance_limit_q,
    input  wire [COUNTER_WIDTH-1:0]     pwm_period,
    input  wire [COUNTER_WIDTH-1:0]     nonoverlap_ticks,
    input  wire                         voltage_out_of_range,
    input  wire                         external_inhibit_request,
    input  wire                         clear_protection_latch,
    output wire                         pwm_hi_a,
    output wire                         pwm_lo_a,
    output wire                         pwm_hi_b,
    output wire                         pwm_lo_b,
    output wire                         pwm_hi_c,
    output wire                         pwm_lo_c,
    output wire                         disable_cmd,
    output wire                         pwm_enable,
    output wire                         protection_latched,
    output wire [3:0]                   status_code,
    output wire signed [DATA_WIDTH-1:0] ia_q,
    output wire signed [DATA_WIDTH-1:0] ib_q,
    output wire signed [DATA_WIDTH-1:0] ic_q,
    output wire signed [DATA_WIDTH-1:0] id_meas_q,
    output wire signed [DATA_WIDTH-1:0] iq_meas_q,
    output wire [COUNTER_WIDTH-1:0]     duty_a,
    output wire [COUNTER_WIDTH-1:0]     duty_b,
    output wire [COUNTER_WIDTH-1:0]     duty_c,
    output wire                         current_out_of_range,
    output wire                         balance_out_of_range,
    output wire                         configuration_error
);

    wire current_valid;
    wire sincos_valid;
    wire signed [DATA_WIDTH-1:0] sin_theta_q;
    wire signed [DATA_WIDTH-1:0] cos_theta_q;

    reg sensor_ready;
    reg angle_ready;
    reg duty_ready;
    reg signed [DATA_WIDTH-1:0] sin_theta_hold_q;
    reg signed [DATA_WIDTH-1:0] cos_theta_hold_q;
    reg transform_sample_valid;
    reg inverse_sample_valid;
    reg duty_sample_valid;

    wire transform_valid;
    wire pi_d_valid;
    wire pi_q_valid;
    wire inverse_valid;
    wire duty_valid;
    wire signed [DATA_WIDTH-1:0] i_alpha_q;
    wire signed [DATA_WIDTH-1:0] i_beta_q;
    wire signed [DATA_WIDTH-1:0] vd_q;
    wire signed [DATA_WIDTH-1:0] vq_q;
    wire signed [DATA_WIDTH-1:0] v_alpha_q;
    wire signed [DATA_WIDTH-1:0] v_beta_q;
    wire [2:0] phase_over_limit;
    wire signed [BALANCE_WIDTH-1:0] balance_error_q;
    wire signed [BALANCE_WIDTH-1:0] balance_abs_q;
    wire input_balance_warning;
    wire pwm_peak_strobe;
    wire pwm_cycle_strobe;

    always @(posedge clk) begin
        if (rst) begin
            sensor_ready <= 1'b0;
            angle_ready <= 1'b0;
            duty_ready <= 1'b0;
            sin_theta_hold_q <= 0;
            cos_theta_hold_q <= 0;
            transform_sample_valid <= 1'b0;
            inverse_sample_valid <= 1'b0;
            duty_sample_valid <= 1'b0;
        end else begin
            if (current_valid)
                sensor_ready <= 1'b1;

            if (sincos_valid) begin
                angle_ready <= 1'b1;
                sin_theta_hold_q <= sin_theta_q;
                cos_theta_hold_q <= cos_theta_q;
            end

            if (duty_valid)
                duty_ready <= 1'b1;

            transform_sample_valid <= current_valid && angle_ready;
            inverse_sample_valid <= pi_d_valid && pi_q_valid;
            duty_sample_valid <= inverse_valid;
        end
    end

    adc_current_scaler_q15 #(
        .ADC_WIDTH(ADC_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .SCALE_WIDTH(SCALE_WIDTH)
    ) current_scaler (
        .clk(clk),
        .rst(rst),
        .sample_valid(sample_valid),
        .adc_a(adc_ia),
        .adc_b(adc_ib),
        .adc_c(adc_ic),
        .offset_a(adc_offset_a),
        .offset_b(adc_offset_b),
        .offset_c(adc_offset_c),
        .scale_q(current_scale_q),
        .current_valid(current_valid),
        .ia_q(ia_q),
        .ib_q(ib_q),
        .ic_q(ic_q)
    );

    sincos_lut_q15 sincos (
        .clk(clk),
        .rst(rst),
        .angle_valid(sample_valid),
        .angle_q(electrical_angle_q),
        .sincos_valid(sincos_valid),
        .sin_theta_q(sin_theta_q),
        .cos_theta_q(cos_theta_q)
    );

    clarke_park_transform #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) clarke_park (
        .clk(clk),
        .rst(rst),
        .sample_valid(transform_sample_valid),
        .ia_q(ia_q),
        .ib_q(ib_q),
        .ic_q(ic_q),
        .sin_theta_q(sin_theta_hold_q),
        .cos_theta_q(cos_theta_hold_q),
        .transform_valid(transform_valid),
        .i_alpha_q(i_alpha_q),
        .i_beta_q(i_beta_q),
        .i_d_q(id_meas_q),
        .i_q_q(iq_meas_q),
        .input_balance_warning(input_balance_warning)
    );

    pi_controller_q15 #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) d_axis_pi (
        .clk(clk),
        .rst(rst),
        .enable(pwm_enable),
        .sample_valid(transform_valid),
        .clear_integrator(!pwm_enable),
        .reference_q(id_ref_q),
        .feedback_q(id_meas_q),
        .kp_q(kp_d_q),
        .ki_q(ki_d_q),
        .output_min_q(voltage_min_q),
        .output_max_q(voltage_max_q),
        .control_valid(pi_d_valid),
        .output_q(vd_q),
        .error_q(),
        .integrator_q()
    );

    pi_controller_q15 #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) q_axis_pi (
        .clk(clk),
        .rst(rst),
        .enable(pwm_enable),
        .sample_valid(transform_valid),
        .clear_integrator(!pwm_enable),
        .reference_q(iq_ref_q),
        .feedback_q(iq_meas_q),
        .kp_q(kp_q_q),
        .ki_q(ki_q_q),
        .output_min_q(voltage_min_q),
        .output_max_q(voltage_max_q),
        .control_valid(pi_q_valid),
        .output_q(vq_q),
        .error_q(),
        .integrator_q()
    );

    inverse_park_transform #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) inverse_park (
        .clk(clk),
        .rst(rst),
        .sample_valid(inverse_sample_valid),
        .v_d_q(vd_q),
        .v_q_q(vq_q),
        .sin_theta_q(sin_theta_hold_q),
        .cos_theta_q(cos_theta_hold_q),
        .inverse_valid(inverse_valid),
        .v_alpha_q(v_alpha_q),
        .v_beta_q(v_beta_q)
    );

    alpha_beta_to_duty #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) duty_generator (
        .clk(clk),
        .rst(rst),
        .sample_valid(duty_sample_valid),
        .v_alpha_q(v_alpha_q),
        .v_beta_q(v_beta_q),
        .period(pwm_period),
        .duty_valid(duty_valid),
        .duty_a(duty_a),
        .duty_b(duty_b),
        .duty_c(duty_c)
    );

    phase_current_limit_monitor #(
        .WIDTH(DATA_WIDTH)
    ) current_limit_monitor (
        .sample_valid(current_valid),
        .ia_q(ia_q),
        .ib_q(ib_q),
        .ic_q(ic_q),
        .current_limit_q(current_limit_q),
        .phase_over_limit(phase_over_limit),
        .current_out_of_range(current_out_of_range)
    );

    phase_current_balance_monitor #(
        .WIDTH(DATA_WIDTH),
        .BALANCE_WIDTH(BALANCE_WIDTH)
    ) current_balance_monitor (
        .sample_valid(current_valid),
        .ia_q(ia_q),
        .ib_q(ib_q),
        .ic_q(ic_q),
        .balance_limit_q(balance_limit_q),
        .balance_error_q(balance_error_q),
        .balance_abs_q(balance_abs_q),
        .balance_out_of_range(balance_out_of_range)
    );

    pcb_disable_control disable_control (
        .clk(clk),
        .rst(rst),
        .sensor_data_valid(sensor_ready),
        .enable_request(enable_request),
        .current_out_of_range(current_out_of_range || balance_out_of_range),
        .voltage_out_of_range(voltage_out_of_range),
        .external_inhibit_request(external_inhibit_request),
        .clear_latch(clear_protection_latch),
        .pwm_enable(pwm_enable),
        .disable_cmd(disable_cmd),
        .protection_latched(protection_latched),
        .status_code(status_code)
    );

    pwm_3phase_center_aligned #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) pwm_generator (
        .clk(clk),
        .rst(rst),
        .enable(pwm_enable),
        .pwm_inhibit(!duty_ready || current_out_of_range || balance_out_of_range || voltage_out_of_range),
        .period(pwm_period),
        .nonoverlap_ticks(nonoverlap_ticks),
        .duty_a(duty_a),
        .duty_b(duty_b),
        .duty_c(duty_c),
        .pwm_hi_a(pwm_hi_a),
        .pwm_lo_a(pwm_lo_a),
        .pwm_hi_b(pwm_hi_b),
        .pwm_lo_b(pwm_lo_b),
        .pwm_hi_c(pwm_hi_c),
        .pwm_lo_c(pwm_lo_c),
        .pwm_peak_strobe(pwm_peak_strobe),
        .cycle_strobe(pwm_cycle_strobe),
        .configuration_error(configuration_error)
    );

endmodule
