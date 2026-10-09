`timescale 1ns / 1ps

module tb_pcb_disable_control;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg sensor_data_valid = 1'b0;
    reg enable_request = 1'b0;
    reg current_out_of_range = 1'b0;
    reg voltage_out_of_range = 1'b0;
    reg external_inhibit_request = 1'b0;
    reg clear_latch = 1'b0;

    wire pwm_enable;
    wire disable_cmd;
    wire protection_latched;
    wire [3:0] status_code;

    always #5 clk = ~clk;

    pcb_disable_control #(
        .DISABLE_ACTIVE_LEVEL(1'b1)
    ) dut (
        .clk(clk),
        .rst(rst),
        .sensor_data_valid(sensor_data_valid),
        .enable_request(enable_request),
        .current_out_of_range(current_out_of_range),
        .voltage_out_of_range(voltage_out_of_range),
        .external_inhibit_request(external_inhibit_request),
        .clear_latch(clear_latch),
        .pwm_enable(pwm_enable),
        .disable_cmd(disable_cmd),
        .protection_latched(protection_latched),
        .status_code(status_code)
    );

    initial begin
        $display("Starting PCB disable control testbench");

        repeat (4) @(posedge clk);
        @(negedge clk);
        enable_request = 1'b1;

        if (pwm_enable || !disable_cmd) begin
            $display("ERROR: reset did not force PWM off and DISABLE active");
            $fatal(1, "Testbench check failed");
        end

        rst = 1'b0;
        repeat (2) @(posedge clk);
        #1;

        if (pwm_enable || !disable_cmd || status_code != 4'd4) begin
            $display("ERROR: PWM enabled before sensor data was valid");
            $fatal(1, "Testbench check failed");
        end

        sensor_data_valid = 1'b1;
        repeat (2) @(posedge clk);
        #1;

        if (!pwm_enable || disable_cmd) begin
            $display("ERROR: PWM did not enable when all inhibits were clear");
            $fatal(1, "Testbench check failed");
        end

        current_out_of_range = 1'b1;
        repeat (2) @(posedge clk);
        #1;

        if (!protection_latched || status_code != 4'd1 || pwm_enable || !disable_cmd) begin
            $display("ERROR: current protection did not latch correctly");
            $fatal(1, "Testbench check failed");
        end

        current_out_of_range = 1'b0;
        clear_latch = 1'b1;
        // Keep clear asserted across a sampling edge before releasing it.
        @(posedge clk);
        #1;
        @(negedge clk);
        clear_latch = 1'b0;
        repeat (2) @(posedge clk);
        #1;

        if (protection_latched || !pwm_enable || disable_cmd) begin
            $display("ERROR: clear latch did not restore PWM enable");
            $fatal(1, "Testbench check failed");
        end

        voltage_out_of_range = 1'b1;
        repeat (2) @(posedge clk);
        #1;

        if (!protection_latched || status_code != 4'd2 || pwm_enable || !disable_cmd) begin
            $display("ERROR: voltage protection did not latch correctly");
            $fatal(1, "Testbench check failed");
        end

        voltage_out_of_range = 1'b0;
        clear_latch = 1'b1;
        // Keep clear asserted across a sampling edge before releasing it.
        @(posedge clk);
        #1;
        @(negedge clk);
        clear_latch = 1'b0;
        repeat (2) @(posedge clk);
        #1;

        external_inhibit_request = 1'b1;
        repeat (2) @(posedge clk);
        #1;

        if (!protection_latched || status_code != 4'd3 || pwm_enable || !disable_cmd) begin
            $display("ERROR: external inhibit did not latch correctly");
            $fatal(1, "Testbench check failed");
        end

        $display("PASS: PCB disable control testbench completed");
        $finish;
    end

    initial begin
        #1000000;
        $fatal(1, "Testbench timed out after 1 ms");
    end

endmodule
