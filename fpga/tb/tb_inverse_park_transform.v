`timescale 1ns / 1ps

module tb_inverse_park_transform;

    localparam DATA_WIDTH = 16;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg sample_valid = 1'b0;
    reg signed [DATA_WIDTH-1:0] v_d_q = 16'sd0;
    reg signed [DATA_WIDTH-1:0] v_q_q = 16'sd0;
    reg signed [DATA_WIDTH-1:0] sin_theta_q = 16'sd0;
    reg signed [DATA_WIDTH-1:0] cos_theta_q = 16'sd0;

    wire inverse_valid;
    wire signed [DATA_WIDTH-1:0] v_alpha_q;
    wire signed [DATA_WIDTH-1:0] v_beta_q;

    always #5 clk = ~clk;

    inverse_park_transform dut (
        .clk(clk),
        .rst(rst),
        .sample_valid(sample_valid),
        .v_d_q(v_d_q),
        .v_q_q(v_q_q),
        .sin_theta_q(sin_theta_q),
        .cos_theta_q(cos_theta_q),
        .inverse_valid(inverse_valid),
        .v_alpha_q(v_alpha_q),
        .v_beta_q(v_beta_q)
    );

    task drive_sample;
        input signed [DATA_WIDTH-1:0] vd_in;
        input signed [DATA_WIDTH-1:0] vq_in;
        input signed [DATA_WIDTH-1:0] sin_in;
        input signed [DATA_WIDTH-1:0] cos_in;
        begin
            @(negedge clk);
            v_d_q = vd_in;
            v_q_q = vq_in;
            sin_theta_q = sin_in;
            cos_theta_q = cos_in;
            sample_valid = 1'b1;
            @(negedge clk);
            sample_valid = 1'b0;
        end
    endtask

    task check_inverse;
        input signed [DATA_WIDTH-1:0] alpha_expected;
        input signed [DATA_WIDTH-1:0] beta_expected;
        begin
            while (!inverse_valid) begin
                @(posedge clk);
            end
            #1;

            if (v_alpha_q != alpha_expected || v_beta_q != beta_expected) begin
                $display("ERROR: inverse Park mismatch");
                $display("alpha got %0d expected %0d", v_alpha_q, alpha_expected);
                $display("beta  got %0d expected %0d", v_beta_q, beta_expected);
                $stop;
            end

        end
    endtask

    initial begin
        $display("Starting inverse Park transform testbench");

        repeat (4) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        drive_sample(16'sd8192, 16'sd4096, 16'sd0, 16'sd32767);
        check_inverse(16'sd8191, 16'sd4095);

        drive_sample(16'sd8192, 16'sd4096, 16'sd32767, 16'sd0);
        check_inverse(-16'sd4095, 16'sd8191);

        $display("PASS: inverse Park transform testbench completed");
        $finish;
    end

endmodule
