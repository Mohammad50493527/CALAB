`timescale 1ns / 1ps

module top_fsm_system (
    input  wire        clk,
    input  wire        pbin,
    input  wire [15:0] physical_sw,
    output wire [15:0] physical_leds
);

    wire        rst_clean;
    wire [31:0] switch_data;    // value read from the switches
    wire [31:0] led_write_data; // value written to the LEDs
    wire        slow_clk;
    wire [15:0] count_val;
    wire        fsm_state;
    reg         slow_q = 1'b0;
    wire        tick;

    // Provided modules (unmodified)
    debouncer rst_db (.clk(clk), .pbin(pbin), .pbout(rst_clean));

    leds switch_reader (        // reads the physical switches
        .clk(clk), .rst(rst_clean),
        .btns(16'd0), .writeData(32'd0), .writeEnable(1'b0),
        .readEnable(1'b1), .memAddress(30'd0),
        .switches(physical_sw), .readData(switch_data)
    );

    switches led_writer (       // drives the physical LEDs
        .clk(clk), .rst(rst_clean),
        .writeData(led_write_data), .writeEnable(1'b1),
        .readEnable(1'b0), .memAddress(30'd0),
        .readData(), .leds(physical_leds)
    );

    clock_divider ticker (      // 100 MHz -> 1 Hz
        .clk_in(clk), .rst(rst_clean), .clk_out(slow_clk)
    );

    // Slow clock -> one-cycle tick in the 100 MHz domain
    always @(posedge clk) slow_q <= slow_clk;
    assign tick = slow_clk & ~slow_q;

    clock_decrement counter_fsm (
        .clk(clk), .rst(rst_clean), .tick(tick),
        .sw_in(switch_data[15:0]),
        .count(count_val), .state(fsm_state)
    );

    assign led_write_data = {16'd0, count_val};
endmodule