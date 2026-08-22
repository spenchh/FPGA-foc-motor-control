`timescale 1ns / 1ps

module tb_clarke_park_transform;

    localparam DATA_WIDTH = 16;
    localparam FRAC_BITS = 15;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg sample_valid = 1'b0;
    reg signed [DATA_WIDTH-1:0] ia_q = 16'sd0;
    reg signed [DATA_WIDTH-1:0] ib_q = 16'sd0;
    reg signed [DATA_WIDTH-1:0] ic_q = 16'sd0;
    reg signed [DATA_WIDTH-1:0] sin_theta_q = 16'sd0;
    reg signed [DATA_WIDTH-1:0] cos_theta_q = 16'sd0;

    wire transform_valid;
    wire signed [DATA_WIDTH-1:0] i_alpha_q;
    wire signed [DATA_WIDTH-1:0] i_beta_q;
    wire signed [DATA_WIDTH-1:0] i_d_q;
    wire signed [DATA_WIDTH-1:0] i_q_q;
    wire input_balance_warning;

    always #5 clk = ~clk;

    clarke_park_transform dut (
        .clk(clk),
        .rst(rst),
        .sample_valid(sample_valid),
        .ia_q(ia_q),
        .ib_q(ib_q),
        .ic_q(ic_q),
        .sin_theta_q(sin_theta_q),
        .cos_theta_q(cos_theta_q),
        .transform_valid(transform_valid),
        .i_alpha_q(i_alpha_q),
        .i_beta_q(i_beta_q),
        .i_d_q(i_d_q),
        .i_q_q(i_q_q),
        .input_balance_warning(input_balance_warning)
    );

    task drive_sample;
        input signed [DATA_WIDTH-1:0] ia_in;
        input signed [DATA_WIDTH-1:0] ib_in;
        input signed [DATA_WIDTH-1:0] ic_in;
        input signed [DATA_WIDTH-1:0] sin_in;
        input signed [DATA_WIDTH-1:0] cos_in;
        begin
            @(negedge clk);
            ia_q = ia_in;
            ib_q = ib_in;
            ic_q = ic_in;
            sin_theta_q = sin_in;
            cos_theta_q = cos_in;
            sample_valid = 1'b1;
            @(negedge clk);
            sample_valid = 1'b0;
        end
    endtask

    task check_result;
        input signed [DATA_WIDTH-1:0] alpha_expected;
        input signed [DATA_WIDTH-1:0] beta_expected;
        input signed [DATA_WIDTH-1:0] d_expected;
        input signed [DATA_WIDTH-1:0] q_expected;
        input balance_warning_expected;
        begin
            while (!transform_valid) begin
                @(posedge clk);
            end
            #1;

            if (i_alpha_q != alpha_expected ||
                i_beta_q != beta_expected ||
                i_d_q != d_expected ||
                i_q_q != q_expected ||
                input_balance_warning != balance_warning_expected) begin
                $display("ERROR: transform mismatch");
                $display("alpha got %0d expected %0d", i_alpha_q, alpha_expected);
                $display("beta  got %0d expected %0d", i_beta_q, beta_expected);
                $display("d     got %0d expected %0d", i_d_q, d_expected);
                $display("q     got %0d expected %0d", i_q_q, q_expected);
                $display("balance got %0d expected %0d",
                    input_balance_warning, balance_warning_expected);
                $stop;
            end

        end
    endtask

    initial begin
        $display("Starting Clarke/Park transform testbench");

        repeat (4) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        // ia=0.25, ib=-0.125, ic=-0.125, theta=0
        drive_sample(16'sd8192, -16'sd4096, -16'sd4096, 16'sd0, 16'sd32767);
        check_result(16'sd8192, 16'sd0, 16'sd8191, 16'sd0, 1'b0);

        // ia=0, ib=0.25, ic=-0.25, theta=0
        drive_sample(16'sd0, 16'sd8192, -16'sd8192, 16'sd0, 16'sd32767);
        check_result(16'sd0, 16'sd9459, 16'sd0, 16'sd9458, 1'b0);

        // Same current vector as above, theta=90 electrical degrees
        drive_sample(16'sd0, 16'sd8192, -16'sd8192, 16'sd32767, 16'sd0);
        check_result(16'sd0, 16'sd9459, 16'sd9458, 16'sd0, 1'b0);

        // Non-zero phase-current sum should flag the balance warning
        drive_sample(16'sd8192, 16'sd0, 16'sd0, 16'sd0, 16'sd32767);
        check_result(16'sd8192, 16'sd4729, 16'sd8191, 16'sd4728, 1'b1);

        $display("PASS: Clarke/Park transform testbench completed");
        $finish;
    end

endmodule
