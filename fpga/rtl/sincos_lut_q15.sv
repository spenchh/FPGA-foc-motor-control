`timescale 1ns / 1ps

module sincos_lut_q15 (
    input  logic        clk,
    input  logic        rst,
    input  logic        angle_valid,
    input  logic [15:0] angle_q,
    output logic         sincos_valid,
    output logic signed [15:0] sin_theta_q,
    output logic signed [15:0] cos_theta_q
);

    wire [1:0] quadrant = angle_q[15:14];
    wire [5:0] quarter_index = angle_q[13:8];
    wire [6:0] index_ext = {1'b0, quarter_index};
    wire [6:0] mirror_index = 7'd64 - index_ext;

    wire signed [15:0] sin_base = quarter_sin_q15(index_ext);
    wire signed [15:0] cos_base = quarter_sin_q15(mirror_index);

    logic signed [15:0] sin_next;
    logic signed [15:0] cos_next;

    function signed [15:0] quarter_sin_q15;
        input [6:0] index;
        begin
            case (index)
                7'd0: quarter_sin_q15 = 16'sd0;
                7'd1: quarter_sin_q15 = 16'sd804;
                7'd2: quarter_sin_q15 = 16'sd1608;
                7'd3: quarter_sin_q15 = 16'sd2410;
                7'd4: quarter_sin_q15 = 16'sd3212;
                7'd5: quarter_sin_q15 = 16'sd4011;
                7'd6: quarter_sin_q15 = 16'sd4808;
                7'd7: quarter_sin_q15 = 16'sd5602;
                7'd8: quarter_sin_q15 = 16'sd6393;
                7'd9: quarter_sin_q15 = 16'sd7179;
                7'd10: quarter_sin_q15 = 16'sd7962;
                7'd11: quarter_sin_q15 = 16'sd8739;
                7'd12: quarter_sin_q15 = 16'sd9512;
                7'd13: quarter_sin_q15 = 16'sd10278;
                7'd14: quarter_sin_q15 = 16'sd11039;
                7'd15: quarter_sin_q15 = 16'sd11793;
                7'd16: quarter_sin_q15 = 16'sd12539;
                7'd17: quarter_sin_q15 = 16'sd13279;
                7'd18: quarter_sin_q15 = 16'sd14010;
                7'd19: quarter_sin_q15 = 16'sd14732;
                7'd20: quarter_sin_q15 = 16'sd15446;
                7'd21: quarter_sin_q15 = 16'sd16151;
                7'd22: quarter_sin_q15 = 16'sd16846;
                7'd23: quarter_sin_q15 = 16'sd17530;
                7'd24: quarter_sin_q15 = 16'sd18204;
                7'd25: quarter_sin_q15 = 16'sd18868;
                7'd26: quarter_sin_q15 = 16'sd19519;
                7'd27: quarter_sin_q15 = 16'sd20159;
                7'd28: quarter_sin_q15 = 16'sd20787;
                7'd29: quarter_sin_q15 = 16'sd21403;
                7'd30: quarter_sin_q15 = 16'sd22005;
                7'd31: quarter_sin_q15 = 16'sd22594;
                7'd32: quarter_sin_q15 = 16'sd23170;
                7'd33: quarter_sin_q15 = 16'sd23731;
                7'd34: quarter_sin_q15 = 16'sd24279;
                7'd35: quarter_sin_q15 = 16'sd24811;
                7'd36: quarter_sin_q15 = 16'sd25329;
                7'd37: quarter_sin_q15 = 16'sd25832;
                7'd38: quarter_sin_q15 = 16'sd26319;
                7'd39: quarter_sin_q15 = 16'sd26790;
                7'd40: quarter_sin_q15 = 16'sd27245;
                7'd41: quarter_sin_q15 = 16'sd27683;
                7'd42: quarter_sin_q15 = 16'sd28105;
                7'd43: quarter_sin_q15 = 16'sd28510;
                7'd44: quarter_sin_q15 = 16'sd28898;
                7'd45: quarter_sin_q15 = 16'sd29268;
                7'd46: quarter_sin_q15 = 16'sd29621;
                7'd47: quarter_sin_q15 = 16'sd29956;
                7'd48: quarter_sin_q15 = 16'sd30273;
                7'd49: quarter_sin_q15 = 16'sd30571;
                7'd50: quarter_sin_q15 = 16'sd30852;
                7'd51: quarter_sin_q15 = 16'sd31113;
                7'd52: quarter_sin_q15 = 16'sd31356;
                7'd53: quarter_sin_q15 = 16'sd31580;
                7'd54: quarter_sin_q15 = 16'sd31785;
                7'd55: quarter_sin_q15 = 16'sd31971;
                7'd56: quarter_sin_q15 = 16'sd32137;
                7'd57: quarter_sin_q15 = 16'sd32285;
                7'd58: quarter_sin_q15 = 16'sd32412;
                7'd59: quarter_sin_q15 = 16'sd32521;
                7'd60: quarter_sin_q15 = 16'sd32609;
                7'd61: quarter_sin_q15 = 16'sd32678;
                7'd62: quarter_sin_q15 = 16'sd32728;
                7'd63: quarter_sin_q15 = 16'sd32757;
                7'd64: quarter_sin_q15 = 16'sd32767;
                default: quarter_sin_q15 = 16'sd0;
            endcase
        end
    endfunction

    always_comb begin
        case (quadrant)
            2'd0: begin
                sin_next = sin_base;
                cos_next = cos_base;
            end
            2'd1: begin
                sin_next = cos_base;
                cos_next = -sin_base;
            end
            2'd2: begin
                sin_next = -sin_base;
                cos_next = -cos_base;
            end
            default: begin
                sin_next = -cos_base;
                cos_next = sin_base;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            sincos_valid <= 1'b0;
            sin_theta_q <= 16'sd0;
            cos_theta_q <= 16'sd0;
        end else begin
            sincos_valid <= angle_valid;

            if (angle_valid) begin
                sin_theta_q <= sin_next;
                cos_theta_q <= cos_next;
            end
        end
    end

endmodule
