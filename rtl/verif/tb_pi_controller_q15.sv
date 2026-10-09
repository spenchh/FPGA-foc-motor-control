`timescale 1ns / 1ps

module tb_pi_controller_q15;

    localparam DATA_WIDTH = 16;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg enable = 1'b0;
    reg sample_valid = 1'b0;
    reg clear_integrator = 1'b0;
    reg signed [DATA_WIDTH-1:0] reference_q = 16'sd0;
    reg signed [DATA_WIDTH-1:0] feedback_q = 16'sd0;
    reg signed [DATA_WIDTH-1:0] kp_q = 16'sd16384;
    reg signed [DATA_WIDTH-1:0] ki_q = 16'sd8192;
    reg signed [DATA_WIDTH-1:0] output_min_q = -16'sd16000;
    reg signed [DATA_WIDTH-1:0] output_max_q = 16'sd16000;

    wire control_valid;
    wire signed [DATA_WIDTH-1:0] output_q;
    wire signed [DATA_WIDTH-1:0] error_q;
    wire signed [DATA_WIDTH-1:0] integrator_q;

    always #5 clk = ~clk;

    pi_controller_q15 dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .sample_valid(sample_valid),
        .clear_integrator(clear_integrator),
        .reference_q(reference_q),
        .feedback_q(feedback_q),
        .kp_q(kp_q),
        .ki_q(ki_q),
        .output_min_q(output_min_q),
        .output_max_q(output_max_q),
        .control_valid(control_valid),
        .output_q(output_q),
        .error_q(error_q),
        .integrator_q(integrator_q)
    );

    task pulse_sample;
        begin
            @(negedge clk);
            sample_valid = 1'b1;
            @(negedge clk);
            sample_valid = 1'b0;
            @(posedge clk);
            #1;
            while (!control_valid) begin
                @(posedge clk);
                #1;
            end
        end
    endtask

    initial begin
        $display("Starting PI controller testbench");

        repeat (4) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
        enable = 1'b1;
        reference_q = 16'sd8192;
        feedback_q = 16'sd4096;

        pulse_sample();
        if (!control_valid || error_q != 16'sd4096 ||
            integrator_q != 16'sd1024 || output_q != 16'sd3072) begin
            $display("ERROR: first PI update mismatch");
            $display("valid=%0d error=%0d integrator=%0d output=%0d",
                control_valid, error_q, integrator_q, output_q);
            $fatal(1, "Testbench check failed");
        end

        pulse_sample();
        if (!control_valid || integrator_q != 16'sd2048 || output_q != 16'sd4096) begin
            $display("ERROR: second PI update mismatch");
            $display("integrator=%0d output=%0d", integrator_q, output_q);
            $fatal(1, "Testbench check failed");
        end

        reference_q = 16'sd32767;
        feedback_q = -16'sd32768;
        kp_q = 16'sd32767;
        ki_q = 16'sd32767;
        pulse_sample();
        if (output_q != output_max_q || integrator_q != output_max_q) begin
            $display("ERROR: PI clamp high failed");
            $display("integrator=%0d output=%0d", integrator_q, output_q);
            $fatal(1, "Testbench check failed");
        end

        @(negedge clk);
        reference_q = 16'sd8192;
        feedback_q = 16'sd4096;
        kp_q = 16'sd16384;
        ki_q = 16'sd8192;
        clear_integrator = 1'b1;
        pulse_sample();
        if (output_q != 16'sd2048 || integrator_q != 16'sd0) begin
            $display("ERROR: clear integrator failed");
            $display("integrator=%0d output=%0d", integrator_q, output_q);
            $fatal(1, "Testbench check failed");
        end

        $display("PASS: PI controller testbench completed");
        $finish;
    end

    initial begin
        #1000000;
        $fatal(1, "Testbench timed out after 1 ms");
    end

endmodule
