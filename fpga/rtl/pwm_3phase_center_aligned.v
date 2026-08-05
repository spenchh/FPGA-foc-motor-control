`timescale 1ns / 1ps

module pwm_3phase_center_aligned #(
    parameter COUNTER_WIDTH = 16
) (
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     enable,
    input  wire                     pwm_inhibit,
    input  wire [COUNTER_WIDTH-1:0] period,
    input  wire [COUNTER_WIDTH-1:0] nonoverlap_ticks,
    input  wire [COUNTER_WIDTH-1:0] duty_a,
    input  wire [COUNTER_WIDTH-1:0] duty_b,
    input  wire [COUNTER_WIDTH-1:0] duty_c,
    output reg                      pwm_hi_a,
    output reg                      pwm_lo_a,
    output reg                      pwm_hi_b,
    output reg                      pwm_lo_b,
    output reg                      pwm_hi_c,
    output reg                      pwm_lo_c,
    output reg                      pwm_peak_strobe,
    output reg                      cycle_strobe,
    output reg                      configuration_error
);

    reg [COUNTER_WIDTH-1:0] counter;
    reg                     count_up;
    reg [COUNTER_WIDTH-1:0] period_shadow;
    reg [COUNTER_WIDTH-1:0] nonoverlap_shadow;
    reg [COUNTER_WIDTH-1:0] duty_a_shadow;
    reg [COUNTER_WIDTH-1:0] duty_b_shadow;
    reg [COUNTER_WIDTH-1:0] duty_c_shadow;
    reg [COUNTER_WIDTH-1:0] period_active;
    reg [COUNTER_WIDTH-1:0] nonoverlap_active;
    reg [COUNTER_WIDTH-1:0] duty_a_active;
    reg [COUNTER_WIDTH-1:0] duty_b_active;
    reg [COUNTER_WIDTH-1:0] duty_c_active;

    wire [COUNTER_WIDTH:0] period_shadow_ext = {1'b0, period_shadow};
    wire [COUNTER_WIDTH:0] two_nonoverlap_shadow_ext = {1'b0, nonoverlap_shadow} << 1;
    wire shadow_config_valid = (period_shadow != {COUNTER_WIDTH{1'b0}}) &&
        (nonoverlap_shadow < period_shadow) &&
        (two_nonoverlap_shadow_ext < period_shadow_ext) &&
        (duty_a_shadow <= period_shadow) &&
        (duty_b_shadow <= period_shadow) &&
        (duty_c_shadow <= period_shadow);
    wire active = enable && !pwm_inhibit && !configuration_error;
    wire [COUNTER_WIDTH:0] counter_ext = {1'b0, counter};
    wire [COUNTER_WIDTH:0] nonoverlap_ext = {1'b0, nonoverlap_active};
    wire [COUNTER_WIDTH:0] duty_a_ext = {1'b0, duty_a_active};
    wire [COUNTER_WIDTH:0] duty_b_ext = {1'b0, duty_b_active};
    wire [COUNTER_WIDTH:0] duty_c_ext = {1'b0, duty_c_active};

    wire hi_a_next = active && ((counter_ext + nonoverlap_ext) < duty_a_ext);
    wire lo_a_next = active && (counter_ext > (duty_a_ext + nonoverlap_ext));
    wire hi_b_next = active && ((counter_ext + nonoverlap_ext) < duty_b_ext);
    wire lo_b_next = active && (counter_ext > (duty_b_ext + nonoverlap_ext));
    wire hi_c_next = active && ((counter_ext + nonoverlap_ext) < duty_c_ext);
    wire lo_c_next = active && (counter_ext > (duty_c_ext + nonoverlap_ext));

    always @(posedge clk) begin
        if (rst) begin
            counter        <= {COUNTER_WIDTH{1'b0}};
            count_up       <= 1'b1;
            pwm_hi_a       <= 1'b0;
            pwm_lo_a       <= 1'b0;
            pwm_hi_b       <= 1'b0;
            pwm_lo_b       <= 1'b0;
            pwm_hi_c       <= 1'b0;
            pwm_lo_c       <= 1'b0;
            pwm_peak_strobe <= 1'b0;
            cycle_strobe   <= 1'b0;
            period_shadow <= {COUNTER_WIDTH{1'b0}};
            nonoverlap_shadow <= {COUNTER_WIDTH{1'b0}};
            duty_a_shadow <= {COUNTER_WIDTH{1'b0}};
            duty_b_shadow <= {COUNTER_WIDTH{1'b0}};
            duty_c_shadow <= {COUNTER_WIDTH{1'b0}};
            period_active <= {COUNTER_WIDTH{1'b0}};
            nonoverlap_active <= {COUNTER_WIDTH{1'b0}};
            duty_a_active <= {COUNTER_WIDTH{1'b0}};
            duty_b_active <= {COUNTER_WIDTH{1'b0}};
            duty_c_active <= {COUNTER_WIDTH{1'b0}};
            configuration_error <= 1'b1;
        end else begin
            pwm_peak_strobe <= 1'b0;
            cycle_strobe    <= 1'b0;
            period_shadow <= period;
            nonoverlap_shadow <= nonoverlap_ticks;
            duty_a_shadow <= duty_a;
            duty_b_shadow <= duty_b;
            duty_c_shadow <= duty_c;

            if (period_active == {COUNTER_WIDTH{1'b0}}) begin
                counter  <= {COUNTER_WIDTH{1'b0}};
                count_up <= 1'b1;
                period_active <= period_shadow;
                nonoverlap_active <= nonoverlap_shadow;
                duty_a_active <= duty_a_shadow;
                duty_b_active <= duty_b_shadow;
                duty_c_active <= duty_c_shadow;
                configuration_error <= !shadow_config_valid;
            end else if (count_up) begin
                if (counter >= period_active) begin
                    count_up      <= 1'b0;
                    counter       <= counter - {{(COUNTER_WIDTH-1){1'b0}}, 1'b1};
                    pwm_peak_strobe <= 1'b1;
                end else begin
                    counter <= counter + {{(COUNTER_WIDTH-1){1'b0}}, 1'b1};
                end
            end else begin
                if (counter == {COUNTER_WIDTH{1'b0}}) begin
                    count_up     <= 1'b1;
                    counter      <= {{(COUNTER_WIDTH-1){1'b0}}, 1'b1};
                    cycle_strobe <= 1'b1;
                    period_active <= period_shadow;
                    nonoverlap_active <= nonoverlap_shadow;
                    duty_a_active <= duty_a_shadow;
                    duty_b_active <= duty_b_shadow;
                    duty_c_active <= duty_c_shadow;
                    configuration_error <= !shadow_config_valid;
                end else begin
                    counter <= counter - {{(COUNTER_WIDTH-1){1'b0}}, 1'b1};
                end
            end

            pwm_hi_a <= hi_a_next;
            pwm_lo_a <= lo_a_next;
            pwm_hi_b <= hi_b_next;
            pwm_lo_b <= lo_b_next;
            pwm_hi_c <= hi_c_next;
            pwm_lo_c <= lo_c_next;
        end
    end

endmodule
