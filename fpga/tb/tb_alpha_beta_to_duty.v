`timescale 1ns / 1ps

module tb_alpha_beta_to_duty;

    localparam DATA_WIDTH = 16;
    localparam COUNTER_WIDTH = 16;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg sample_valid = 1'b0;
    reg signed [DATA_WIDTH-1:0] v_alpha_q = 16'sd0;
    reg signed [DATA_WIDTH-1:0] v_beta_q = 16'sd0;
    reg [COUNTER_WIDTH-1:0] period = 16'd1000;

    wire duty_valid;
    wire [COUNTER_WIDTH-1:0] duty_a;
    wire [COUNTER_WIDTH-1:0] duty_b;
    wire [COUNTER_WIDTH-1:0] duty_c;

    always #5 clk = ~clk;

    alpha_beta_to_duty dut (
        .clk(clk),
        .rst(rst),
        .sample_valid(sample_valid),
        .v_alpha_q(v_alpha_q),
        .v_beta_q(v_beta_q),
        .period(period),
        .duty_valid(duty_valid),
        .duty_a(duty_a),
        .duty_b(duty_b),
        .duty_c(duty_c)
    );

    task drive_vector;
        input signed [DATA_WIDTH-1:0] alpha_in;
        input signed [DATA_WIDTH-1:0] beta_in;
        begin
            @(negedge clk);
            v_alpha_q = alpha_in;
            v_beta_q = beta_in;
            sample_valid = 1'b1;
            @(negedge clk);
            sample_valid = 1'b0;
        end
    endtask

    task check_duty;
        input [COUNTER_WIDTH-1:0] duty_a_expected;
        input [COUNTER_WIDTH-1:0] duty_b_expected;
        input [COUNTER_WIDTH-1:0] duty_c_expected;
        begin
            while (!duty_valid) begin
                @(posedge clk);
            end
            #1;

            if (duty_a != duty_a_expected ||
                duty_b != duty_b_expected ||
                duty_c != duty_c_expected) begin
                $display("ERROR: duty mismatch");
                $display("A got %0d expected %0d", duty_a, duty_a_expected);
                $display("B got %0d expected %0d", duty_b, duty_b_expected);
                $display("C got %0d expected %0d", duty_c, duty_c_expected);
                $stop;
            end

        end
    endtask

    initial begin
        $display("Starting alpha/beta to duty testbench");

        repeat (4) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        drive_vector(16'sd0, 16'sd0);
        check_duty(16'd500, 16'd500, 16'd500);

        drive_vector(16'sd16384, 16'sd0);
        check_duty(16'd750, 16'd375, 16'd375);

        drive_vector(-16'sd16384, 16'sd0);
        check_duty(16'd250, 16'd625, 16'd625);

        $display("PASS: alpha/beta to duty testbench completed");
        $finish;
    end

endmodule
