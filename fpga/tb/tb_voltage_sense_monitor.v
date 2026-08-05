`timescale 1ns / 1ps

module tb_voltage_sense_monitor;

    localparam WIDTH = 16;

    reg [WIDTH-1:0] phase_v_q;
    reg [WIDTH-1:0] bus_v_q;
    reg [WIDTH-1:0] phase_v_min_q;
    reg [WIDTH-1:0] phase_v_max_q;
    reg [WIDTH-1:0] bus_v_min_q;
    reg [WIDTH-1:0] bus_v_max_q;

    wire phase_v_out_of_range;
    wire bus_v_out_of_range;
    wire voltage_out_of_range;

    voltage_sense_monitor #(
        .WIDTH(WIDTH)
    ) dut (
        .phase_v_q(phase_v_q),
        .bus_v_q(bus_v_q),
        .phase_v_min_q(phase_v_min_q),
        .phase_v_max_q(phase_v_max_q),
        .bus_v_min_q(bus_v_min_q),
        .bus_v_max_q(bus_v_max_q),
        .phase_v_out_of_range(phase_v_out_of_range),
        .bus_v_out_of_range(bus_v_out_of_range),
        .voltage_out_of_range(voltage_out_of_range)
    );

    initial begin
        $display("Starting voltage sense monitor testbench");

        phase_v_min_q = 16'd1000;
        phase_v_max_q = 16'd3000;
        bus_v_min_q = 16'd2000;
        bus_v_max_q = 16'd5000;

        phase_v_q = 16'd2000;
        bus_v_q = 16'd3500;
        #1;
        if (phase_v_out_of_range || bus_v_out_of_range || voltage_out_of_range) begin
            $display("ERROR: valid voltage case failed");
            $stop;
        end

        phase_v_q = 16'd500;
        bus_v_q = 16'd3500;
        #1;
        if (!phase_v_out_of_range || bus_v_out_of_range || !voltage_out_of_range) begin
            $display("ERROR: phase low-voltage case failed");
            $stop;
        end

        phase_v_q = 16'd2000;
        bus_v_q = 16'd6000;
        #1;
        if (phase_v_out_of_range || !bus_v_out_of_range || !voltage_out_of_range) begin
            $display("ERROR: bus high-voltage case failed");
            $stop;
        end

        $display("PASS: voltage sense monitor testbench completed");
        $finish;
    end

endmodule
