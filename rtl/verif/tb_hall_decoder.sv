`timescale 1ns / 1ps

module tb_hall_decoder;

    reg clk = 1'b0;
    reg rst = 1'b1;
    reg hall_a = 1'b0;
    reg hall_b = 1'b0;
    reg hall_c = 1'b0;

    wire [2:0] sector;
    wire hall_valid;
    wire direction_forward;
    wire transition_strobe;
    wire illegal_state;
    wire bad_transition;
    wire [31:0] transition_count;
    wire [31:0] bad_transition_count;

    always #5 clk = ~clk;

    hall_decoder dut (
        .clk(clk),
        .rst(rst),
        .hall_a(hall_a),
        .hall_b(hall_b),
        .hall_c(hall_c),
        .sector(sector),
        .hall_valid(hall_valid),
        .direction_forward(direction_forward),
        .transition_strobe(transition_strobe),
        .illegal_state(illegal_state),
        .bad_transition(bad_transition),
        .transition_count(transition_count),
        .bad_transition_count(bad_transition_count)
    );

    task set_hall;
        input a;
        input b;
        input c;
        begin
            @(negedge clk);
            hall_a = a;
            hall_b = b;
            hall_c = c;
            // Two synchronizer stages, then registered decode; sample after NBA.
            repeat (3) @(posedge clk);
            #1;
        end
    endtask

    initial begin
        $display("Starting Hall decoder testbench");

        repeat (4) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        set_hall(1'b0, 1'b0, 1'b1);
        if (!hall_valid || sector != 3'd0) begin
            $display("ERROR: Hall 001 did not decode to sector 0");
            $fatal(1, "Testbench check failed");
        end

        set_hall(1'b1, 1'b0, 1'b1);
        if (!hall_valid || sector != 3'd1 || !direction_forward) begin
            $display("ERROR: Hall 101 did not decode as forward sector 1");
            $fatal(1, "Testbench check failed");
        end

        set_hall(1'b1, 1'b1, 1'b1);
        if (!illegal_state || hall_valid) begin
            $display("ERROR: illegal Hall state was not flagged");
            $fatal(1, "Testbench check failed");
        end

        $display("PASS: Hall decoder testbench completed");
        $finish;
    end

    initial begin
        #1000000;
        $fatal(1, "Testbench timed out after 1 ms");
    end

endmodule
