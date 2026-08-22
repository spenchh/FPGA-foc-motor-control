`timescale 1ns / 1ps

module tb_sincos_lut_q15;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg angle_valid = 1'b0;
    reg [15:0] angle_q = 16'h0000;

    wire sincos_valid;
    wire signed [15:0] sin_theta_q;
    wire signed [15:0] cos_theta_q;

    always #5 clk = ~clk;

    sincos_lut_q15 dut (
        .clk(clk),
        .rst(rst),
        .angle_valid(angle_valid),
        .angle_q(angle_q),
        .sincos_valid(sincos_valid),
        .sin_theta_q(sin_theta_q),
        .cos_theta_q(cos_theta_q)
    );

    task drive_angle;
        input [15:0] angle_in;
        begin
            @(negedge clk);
            angle_q = angle_in;
            angle_valid = 1'b1;
        end
    endtask

    task check_sincos;
        input signed [15:0] sin_expected;
        input signed [15:0] cos_expected;
        begin
            @(posedge clk);
            #1;

            if (!sincos_valid) begin
                $display("ERROR: sincos_valid was not asserted");
                $stop;
            end

            if (sin_theta_q != sin_expected || cos_theta_q != cos_expected) begin
                $display("ERROR: sin/cos mismatch");
                $display("sin got %0d expected %0d", sin_theta_q, sin_expected);
                $display("cos got %0d expected %0d", cos_theta_q, cos_expected);
                $stop;
            end

            @(negedge clk);
            angle_valid = 1'b0;
        end
    endtask

    initial begin
        $display("Starting sin/cos LUT testbench");

        repeat (4) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        drive_angle(16'h0000);
        check_sincos(16'sd0, 16'sd32767);

        drive_angle(16'h4000);
        check_sincos(16'sd32767, 16'sd0);

        drive_angle(16'h8000);
        check_sincos(16'sd0, -16'sd32767);

        drive_angle(16'hC000);
        check_sincos(-16'sd32767, 16'sd0);

        drive_angle(16'h2000);
        check_sincos(16'sd23170, 16'sd23170);

        drive_angle(16'h6000);
        check_sincos(16'sd23170, -16'sd23170);

        $display("PASS: sin/cos LUT testbench completed");
        $finish;
    end

endmodule
