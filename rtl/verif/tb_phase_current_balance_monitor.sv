`timescale 1ns / 1ps

module tb_phase_current_balance_monitor;

    localparam WIDTH = 16;
    localparam BALANCE_WIDTH = WIDTH + 2;

    reg sample_valid;
    reg signed [WIDTH-1:0] ia_q;
    reg signed [WIDTH-1:0] ib_q;
    reg signed [WIDTH-1:0] ic_q;
    reg signed [BALANCE_WIDTH-1:0] balance_limit_q;

    wire signed [BALANCE_WIDTH-1:0] balance_error_q;
    wire signed [BALANCE_WIDTH-1:0] balance_abs_q;
    wire balance_out_of_range;

    phase_current_balance_monitor #(
        .WIDTH(WIDTH),
        .BALANCE_WIDTH(BALANCE_WIDTH)
    ) dut (
        .sample_valid(sample_valid),
        .ia_q(ia_q),
        .ib_q(ib_q),
        .ic_q(ic_q),
        .balance_limit_q(balance_limit_q),
        .balance_error_q(balance_error_q),
        .balance_abs_q(balance_abs_q),
        .balance_out_of_range(balance_out_of_range)
    );

    initial begin
        $display("Starting phase current balance monitor testbench");

        sample_valid = 1'b1;
        balance_limit_q = 18'sd50;

        ia_q = 16'sd1000;
        ib_q = -16'sd250;
        ic_q = -16'sd750;
        #1;
        if (balance_error_q != 18'sd0 || balance_out_of_range) begin
            $display("ERROR: balanced current case failed");
            $fatal(1, "Testbench check failed");
        end

        ia_q = 16'sd1000;
        ib_q = -16'sd200;
        ic_q = -16'sd750;
        #1;
        if (balance_error_q != 18'sd50 || balance_abs_q != 18'sd50 || balance_out_of_range) begin
            $display("ERROR: balance limit edge case failed");
            $fatal(1, "Testbench check failed");
        end

        ia_q = 16'sd1000;
        ib_q = -16'sd100;
        ic_q = -16'sd750;
        #1;
        if (balance_error_q != 18'sd150 || !balance_out_of_range) begin
            $display("ERROR: positive out-of-range check failed");
            $fatal(1, "Testbench check failed");
        end

        sample_valid = 1'b0;
        #1;
        if (balance_out_of_range) begin
            $display("ERROR: invalid sample should suppress balance warning");
            $fatal(1, "Testbench check failed");
        end

        $display("PASS: phase current balance monitor testbench completed");
        $finish;
    end

    initial begin
        #1000000;
        $fatal(1, "Testbench timed out after 1 ms");
    end

endmodule
