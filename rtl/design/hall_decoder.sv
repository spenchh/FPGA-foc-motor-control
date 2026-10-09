`timescale 1ns / 1ps

module hall_decoder (
    input  wire       clk,
    input  wire       rst,
    input  wire       hall_a,
    input  wire       hall_b,
    input  wire       hall_c,
    output reg  [2:0] sector,
    output reg        hall_valid,
    output reg        direction_forward,
    output reg        transition_strobe,
    output reg        illegal_state,
    output reg        bad_transition,
    output reg [31:0] transition_count,
    output reg [31:0] bad_transition_count
);

    reg [2:0] hall_sync_0;
    reg [2:0] hall_sync_1;
    reg [2:0] last_sector;
    reg       last_valid;

    wire [2:0] hall_raw = {hall_a, hall_b, hall_c};

    function [2:0] decode_sector;
        input [2:0] hall;
        begin
            case (hall)
                3'b001: decode_sector = 3'd0;
                3'b101: decode_sector = 3'd1;
                3'b100: decode_sector = 3'd2;
                3'b110: decode_sector = 3'd3;
                3'b010: decode_sector = 3'd4;
                3'b011: decode_sector = 3'd5;
                default: decode_sector = 3'd7;
            endcase
        end
    endfunction

    function is_forward_step;
        input [2:0] previous_sector;
        input [2:0] current_sector;
        begin
            is_forward_step =
                ((previous_sector == 3'd0) && (current_sector == 3'd1)) ||
                ((previous_sector == 3'd1) && (current_sector == 3'd2)) ||
                ((previous_sector == 3'd2) && (current_sector == 3'd3)) ||
                ((previous_sector == 3'd3) && (current_sector == 3'd4)) ||
                ((previous_sector == 3'd4) && (current_sector == 3'd5)) ||
                ((previous_sector == 3'd5) && (current_sector == 3'd0));
        end
    endfunction

    function is_reverse_step;
        input [2:0] previous_sector;
        input [2:0] current_sector;
        begin
            is_reverse_step =
                ((previous_sector == 3'd0) && (current_sector == 3'd5)) ||
                ((previous_sector == 3'd5) && (current_sector == 3'd4)) ||
                ((previous_sector == 3'd4) && (current_sector == 3'd3)) ||
                ((previous_sector == 3'd3) && (current_sector == 3'd2)) ||
                ((previous_sector == 3'd2) && (current_sector == 3'd1)) ||
                ((previous_sector == 3'd1) && (current_sector == 3'd0));
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            hall_sync_0          <= 3'b000;
            hall_sync_1          <= 3'b000;
            sector               <= 3'd7;
            hall_valid           <= 1'b0;
            direction_forward    <= 1'b1;
            transition_strobe    <= 1'b0;
            illegal_state        <= 1'b0;
            bad_transition       <= 1'b0;
            transition_count     <= 32'd0;
            bad_transition_count <= 32'd0;
            last_sector          <= 3'd7;
            last_valid           <= 1'b0;
        end else begin
            hall_sync_0       <= hall_raw;
            hall_sync_1       <= hall_sync_0;
            transition_strobe <= 1'b0;
            illegal_state     <= 1'b0;
            bad_transition    <= 1'b0;

            sector     <= decode_sector(hall_sync_1);
            hall_valid <= (decode_sector(hall_sync_1) != 3'd7);

            if (decode_sector(hall_sync_1) != 3'd7) begin
                if (!last_valid) begin
                    last_sector <= decode_sector(hall_sync_1);
                    last_valid  <= 1'b1;
                end else if (decode_sector(hall_sync_1) != last_sector) begin
                    transition_strobe <= 1'b1;
                    transition_count  <= transition_count + 32'd1;

                    if (is_forward_step(last_sector, decode_sector(hall_sync_1))) begin
                        direction_forward <= 1'b1;
                    end else if (is_reverse_step(last_sector, decode_sector(hall_sync_1))) begin
                        direction_forward <= 1'b0;
                    end else begin
                        bad_transition       <= 1'b1;
                        bad_transition_count <= bad_transition_count + 32'd1;
                    end

                    last_sector <= decode_sector(hall_sync_1);
                end
            end else begin
                illegal_state <= 1'b1;

                if (last_valid) begin
                    bad_transition       <= 1'b1;
                    bad_transition_count <= bad_transition_count + 32'd1;
                end

                last_valid <= 1'b0;
            end
        end
    end

endmodule
