`timescale 1ns / 1ps

module tb_pwm_3phase_center_aligned;

    localparam COUNTER_WIDTH = 8;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg enable = 1'b0;
    reg pwm_inhibit = 1'b0;
    reg [COUNTER_WIDTH-1:0] period = 8'd100;
    reg [COUNTER_WIDTH-1:0] nonoverlap_ticks = 8'd2;
    reg [COUNTER_WIDTH-1:0] duty_a = 8'd25;
    reg [COUNTER_WIDTH-1:0] duty_b = 8'd50;
    reg [COUNTER_WIDTH-1:0] duty_c = 8'd75;

    wire pwm_hi_a;
    wire pwm_lo_a;
    wire pwm_hi_b;
    wire pwm_lo_b;
    wire pwm_hi_c;
    wire pwm_lo_c;
    wire pwm_peak_strobe;
    wire cycle_strobe;
    wire configuration_error;

    integer peak_count = 0;
    integer cycle_count = 0;

    always #5 clk = ~clk;

    pwm_3phase_center_aligned #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .pwm_inhibit(pwm_inhibit),
        .period(period),
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
        .cycle_strobe(cycle_strobe),
        .configuration_error(configuration_error)
    );

    always @(posedge clk) begin
        if (pwm_peak_strobe) peak_count = peak_count + 1;
        if (cycle_strobe) cycle_count = cycle_count + 1;

        if ((pwm_hi_a && pwm_lo_a) || (pwm_hi_b && pwm_lo_b) || (pwm_hi_c && pwm_lo_c)) begin
            $display("ERROR: HI/LO pair overlapped");
            $stop;
        end
    end

    initial begin
        $display("Starting 3PWM testbench");

        repeat (4) @(posedge clk);
        rst = 1'b0;
        enable = 1'b1;

        repeat (450) @(posedge clk);

        if (configuration_error) begin
            $display("ERROR: valid PWM configuration was flagged invalid");
            $stop;
        end

        if (peak_count < 2) begin
            $display("ERROR: peak strobe did not fire enough times");
            $stop;
        end

        if (cycle_count < 2) begin
            $display("ERROR: cycle strobe did not fire enough times");
            $stop;
        end

        pwm_inhibit = 1'b1;
        repeat (3) @(posedge clk);

        if (pwm_hi_a || pwm_lo_a || pwm_hi_b || pwm_lo_b || pwm_hi_c || pwm_lo_c) begin
            $display("ERROR: PWM outputs did not shut off when inhibited");
            $stop;
        end

        pwm_inhibit = 1'b0;
        repeat (5) @(posedge clk);

        duty_a = 8'd120;
        repeat (250) @(posedge clk);

        if (!configuration_error) begin
            $display("ERROR: invalid duty did not raise configuration error");
            $stop;
        end

        $display("PASS: 3PWM testbench completed");
        $finish;
    end

endmodule
