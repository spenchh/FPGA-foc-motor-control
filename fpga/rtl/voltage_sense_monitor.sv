`timescale 1ns / 1ps

module voltage_sense_monitor #(
    parameter WIDTH = 16
) (
    input  wire [WIDTH-1:0] phase_v_q,
    input  wire [WIDTH-1:0] bus_v_q,
    input  wire [WIDTH-1:0] phase_v_min_q,
    input  wire [WIDTH-1:0] phase_v_max_q,
    input  wire [WIDTH-1:0] bus_v_min_q,
    input  wire [WIDTH-1:0] bus_v_max_q,
    output wire             phase_v_out_of_range,
    output wire             bus_v_out_of_range,
    output wire             voltage_out_of_range
);

    assign phase_v_out_of_range = (phase_v_q < phase_v_min_q) || (phase_v_q > phase_v_max_q);
    assign bus_v_out_of_range = (bus_v_q < bus_v_min_q) || (bus_v_q > bus_v_max_q);
    assign voltage_out_of_range = phase_v_out_of_range || bus_v_out_of_range;

endmodule
