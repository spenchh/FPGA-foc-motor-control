`timescale 1ns / 1ps

module tb_phase_current_limit_monitor;

    localparam WIDTH = 16;

    reg sample_valid;
    reg signed [WIDTH-1:0] ia_q;
    reg signed [WIDTH-1:0] ib_q;
    reg signed [WIDTH-1:0] ic_q;
    reg signed [WIDTH-1:0] current_limit_q;

    wire [2:0] phase_over_limit;
    wire current_out_of_range;

    phase_current_limit_monitor #(
        .WIDTH(WIDTH)
    ) dut (
        .sample_valid(sample_valid),
        .ia_q(ia_q),
        .ib_q(ib_q),
        .ic_q(ic_q),
        .current_limit_q(current_limit_q),
        .phase_over_limit(phase_over_limit),
        .current_out_of_range(current_out_of_range)
    );

    initial begin
        $display("Starting phase current limit monitor testbench");

        sample_valid = 1'b1;
        current_limit_q = 16'sd1200;

        ia_q = 16'sd1000;
        ib_q = -16'sd1000;
        ic_q = 16'sd0;
        #1;
        if (current_out_of_range || phase_over_limit != 3'b000) begin
            $display("ERROR: in-range current case failed");
            $stop;
        end

        ia_q = 16'sd1400;
        ib_q = -16'sd1400;
        ic_q = 16'sd0;
        #1;
        if (!current_out_of_range || phase_over_limit != 3'b011) begin
            $display("ERROR: per-phase limit case failed");
            $stop;
        end

        sample_valid = 1'b0;
        #1;
        if (current_out_of_range) begin
            $display("ERROR: invalid sample should suppress current limit");
            $stop;
        end

        $display("PASS: phase current limit monitor testbench completed");
        $finish;
    end

endmodule
