`timescale 1ns / 1ps

module tb_adc_current_scaler_q15;

    localparam ADC_WIDTH = 12;
    localparam DATA_WIDTH = 16;
    localparam SCALE_WIDTH = 24;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg sample_valid = 1'b0;
    reg [ADC_WIDTH-1:0] adc_a = 12'd0;
    reg [ADC_WIDTH-1:0] adc_b = 12'd0;
    reg [ADC_WIDTH-1:0] adc_c = 12'd0;
    reg [ADC_WIDTH-1:0] offset_a = 12'd2048;
    reg [ADC_WIDTH-1:0] offset_b = 12'd2048;
    reg [ADC_WIDTH-1:0] offset_c = 12'd2048;
    reg signed [SCALE_WIDTH-1:0] scale_q = 24'sd32768;

    wire current_valid;
    wire signed [DATA_WIDTH-1:0] ia_q;
    wire signed [DATA_WIDTH-1:0] ib_q;
    wire signed [DATA_WIDTH-1:0] ic_q;

    always #5 clk = ~clk;

    adc_current_scaler_q15 dut (
        .clk(clk),
        .rst(rst),
        .sample_valid(sample_valid),
        .adc_a(adc_a),
        .adc_b(adc_b),
        .adc_c(adc_c),
        .offset_a(offset_a),
        .offset_b(offset_b),
        .offset_c(offset_c),
        .scale_q(scale_q),
        .current_valid(current_valid),
        .ia_q(ia_q),
        .ib_q(ib_q),
        .ic_q(ic_q)
    );

    task drive_sample;
        input [ADC_WIDTH-1:0] adc_a_in;
        input [ADC_WIDTH-1:0] adc_b_in;
        input [ADC_WIDTH-1:0] adc_c_in;
        begin
            @(negedge clk);
            adc_a = adc_a_in;
            adc_b = adc_b_in;
            adc_c = adc_c_in;
            sample_valid = 1'b1;
            @(negedge clk);
            sample_valid = 1'b0;
        end
    endtask

    task check_currents;
        input signed [DATA_WIDTH-1:0] ia_expected;
        input signed [DATA_WIDTH-1:0] ib_expected;
        input signed [DATA_WIDTH-1:0] ic_expected;
        begin
            while (!current_valid) begin
                @(posedge clk);
            end
            #1;

            if (ia_q != ia_expected || ib_q != ib_expected || ic_q != ic_expected) begin
                $display("ERROR: ADC current scaling mismatch");
                $display("ia got %0d expected %0d", ia_q, ia_expected);
                $display("ib got %0d expected %0d", ib_q, ib_expected);
                $display("ic got %0d expected %0d", ic_q, ic_expected);
                $stop;
            end

        end
    endtask

    initial begin
        $display("Starting ADC current scaler testbench");

        repeat (4) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        drive_sample(12'd2148, 12'd1948, 12'd2048);
        check_currents(16'sd100, -16'sd100, 16'sd0);

        drive_sample(12'd2048, 12'd2049, 12'd2047);
        check_currents(16'sd0, 16'sd1, -16'sd1);

        scale_q = 24'sd65536;
        drive_sample(12'd2058, 12'd2038, 12'd2048);
        check_currents(16'sd20, -16'sd20, 16'sd0);

        $display("PASS: ADC current scaler testbench completed");
        $finish;
    end

endmodule
