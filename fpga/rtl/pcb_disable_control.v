`timescale 1ns / 1ps

module pcb_disable_control #(
    parameter DISABLE_ACTIVE_LEVEL = 1'b1
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       sensor_data_valid,
    input  wire       enable_request,
    input  wire       current_out_of_range,
    input  wire       voltage_out_of_range,
    input  wire       external_inhibit_request,
    input  wire       clear_latch,
    output wire       pwm_enable,
    output wire       disable_cmd,
    output reg        protection_latched,
    output reg  [3:0] status_code
);

    // Updated PCB: DISABLE feeds all UCC21222 DIS pins.
    // It is active high, so drive low to run and high to inhibit the drivers.
    localparam [3:0] STATUS_NONE    = 4'd0;
    localparam [3:0] STATUS_CURRENT = 4'd1;
    localparam [3:0] STATUS_VOLTAGE = 4'd2;
    localparam [3:0] STATUS_EXTERNAL = 4'd3;
    localparam [3:0] STATUS_STARTUP = 4'd4;

    wire startup_inhibit = !sensor_data_valid;
    wire any_inhibit = startup_inhibit || current_out_of_range ||
        voltage_out_of_range || external_inhibit_request;

    assign pwm_enable = !rst && enable_request && !protection_latched && !any_inhibit;
    assign disable_cmd = pwm_enable ? ~DISABLE_ACTIVE_LEVEL : DISABLE_ACTIVE_LEVEL;

    always @(posedge clk) begin
        if (rst) begin
            protection_latched <= 1'b0;
            status_code <= STATUS_NONE;
        end else begin
            if (startup_inhibit) begin
                protection_latched <= 1'b0;
                status_code <= STATUS_STARTUP;
            end else if (current_out_of_range) begin
                protection_latched <= 1'b1;
                status_code <= STATUS_CURRENT;
            end else if (voltage_out_of_range) begin
                protection_latched <= 1'b1;
                status_code <= STATUS_VOLTAGE;
            end else if (external_inhibit_request) begin
                protection_latched <= 1'b1;
                status_code <= STATUS_EXTERNAL;
            end else if (clear_latch && !any_inhibit) begin
                protection_latched <= 1'b0;
                status_code <= STATUS_NONE;
            end else if (!protection_latched) begin
                status_code <= STATUS_NONE;
            end
        end
    end

endmodule
