`timescale 1ns / 1ps

module tb_foc_current_loop_top;

    localparam ADC_WIDTH = 12;
    localparam DATA_WIDTH = 16;
    localparam SCALE_WIDTH = 24;
    localparam COUNTER_WIDTH = 16;
    localparam BALANCE_WIDTH = DATA_WIDTH + 2;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg enable_request = 1'b0;
    reg sample_valid = 1'b0;
    reg [ADC_WIDTH-1:0] adc_ia = 12'd2048;
    reg [ADC_WIDTH-1:0] adc_ib = 12'd2048;
    reg [ADC_WIDTH-1:0] adc_ic = 12'd2048;
    reg [ADC_WIDTH-1:0] adc_offset_a = 12'd2048;
    reg [ADC_WIDTH-1:0] adc_offset_b = 12'd2048;
    reg [ADC_WIDTH-1:0] adc_offset_c = 12'd2048;
    reg signed [SCALE_WIDTH-1:0] current_scale_q = 24'sd32768;
    reg [15:0] electrical_angle_q = 16'h0000;
    reg signed [DATA_WIDTH-1:0] id_ref_q = 16'sd0;
    reg signed [DATA_WIDTH-1:0] iq_ref_q = 16'sd4096;
    reg signed [DATA_WIDTH-1:0] kp_d_q = 16'sd16384;
    reg signed [DATA_WIDTH-1:0] ki_d_q = 16'sd0;
    reg signed [DATA_WIDTH-1:0] kp_q_q = 16'sd16384;
    reg signed [DATA_WIDTH-1:0] ki_q_q = 16'sd0;
    reg signed [DATA_WIDTH-1:0] voltage_min_q = -16'sd16000;
    reg signed [DATA_WIDTH-1:0] voltage_max_q = 16'sd16000;
    reg signed [DATA_WIDTH-1:0] current_limit_q = 16'sd1000;
    reg signed [BALANCE_WIDTH-1:0] balance_limit_q = 18'sd100;
    reg [COUNTER_WIDTH-1:0] pwm_period = 16'd1000;
    reg [COUNTER_WIDTH-1:0] nonoverlap_ticks = 16'd2;
    reg voltage_out_of_range = 1'b0;
    reg external_inhibit_request = 1'b0;
    reg clear_protection_latch = 1'b0;

    wire pwm_hi_a;
    wire pwm_lo_a;
    wire pwm_hi_b;
    wire pwm_lo_b;
    wire pwm_hi_c;
    wire pwm_lo_c;
    wire disable_cmd;
    wire pwm_enable;
    wire protection_latched;
    wire [3:0] status_code;
    wire signed [DATA_WIDTH-1:0] ia_q;
    wire signed [DATA_WIDTH-1:0] ib_q;
    wire signed [DATA_WIDTH-1:0] ic_q;
    wire signed [DATA_WIDTH-1:0] id_meas_q;
    wire signed [DATA_WIDTH-1:0] iq_meas_q;
    wire [COUNTER_WIDTH-1:0] duty_a;
    wire [COUNTER_WIDTH-1:0] duty_b;
    wire [COUNTER_WIDTH-1:0] duty_c;
    wire current_out_of_range;
    wire balance_out_of_range;
    wire configuration_error;

    always #5 clk = ~clk;

    foc_current_loop_top dut (
        .clk(clk),
        .rst(rst),
        .enable_request(enable_request),
        .sample_valid(sample_valid),
        .adc_ia(adc_ia),
        .adc_ib(adc_ib),
        .adc_ic(adc_ic),
        .adc_offset_a(adc_offset_a),
        .adc_offset_b(adc_offset_b),
        .adc_offset_c(adc_offset_c),
        .current_scale_q(current_scale_q),
        .electrical_angle_q(electrical_angle_q),
        .id_ref_q(id_ref_q),
        .iq_ref_q(iq_ref_q),
        .kp_d_q(kp_d_q),
        .ki_d_q(ki_d_q),
        .kp_q_q(kp_q_q),
        .ki_q_q(ki_q_q),
        .voltage_min_q(voltage_min_q),
        .voltage_max_q(voltage_max_q),
        .current_limit_q(current_limit_q),
        .balance_limit_q(balance_limit_q),
        .pwm_period(pwm_period),
        .nonoverlap_ticks(nonoverlap_ticks),
        .voltage_out_of_range(voltage_out_of_range),
        .external_inhibit_request(external_inhibit_request),
        .clear_protection_latch(clear_protection_latch),
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

    initial begin
        $display("Starting FOC current loop top testbench");

        repeat (4) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
        enable_request = 1'b1;
        sample_valid = 1'b1;

        repeat (40) @(posedge clk);
        #1;

        if (!pwm_enable || disable_cmd) begin
            $display("ERROR: PWM did not enable in nominal case");
            $display("pwm_enable=%0d disable_cmd=%0d status=%0d",
                pwm_enable, disable_cmd, status_code);
            $fatal(1, "Testbench check failed");
        end

        if (current_out_of_range || balance_out_of_range) begin
            $display("ERROR: nominal current case tripped protection");
            $fatal(1, "Testbench check failed");
        end

        if (configuration_error) begin
            $display("ERROR: PWM configuration error stayed asserted");
            $fatal(1, "Testbench check failed");
        end

        if (!(duty_b > duty_c)) begin
            $display("ERROR: q-axis command did not produce expected phase ordering");
            $display("duty_a=%0d duty_b=%0d duty_c=%0d", duty_a, duty_b, duty_c);
            $fatal(1, "Testbench check failed");
        end

        @(negedge clk);
        adc_ia = 12'd3200;
        adc_ib = 12'd2048;
        adc_ic = 12'd2048;

        repeat (8) @(posedge clk);
        #1;

        if (!current_out_of_range || !protection_latched || !disable_cmd) begin
            $display("ERROR: overcurrent did not inhibit the loop");
            $display("current_out=%0d latched=%0d disable=%0d status=%0d",
                current_out_of_range, protection_latched, disable_cmd, status_code);
            $fatal(1, "Testbench check failed");
        end

        $display("PASS: FOC current loop top testbench completed");
        $finish;
    end

    initial begin
        #1000000;
        $fatal(1, "Testbench timed out after 1 ms");
    end

endmodule
