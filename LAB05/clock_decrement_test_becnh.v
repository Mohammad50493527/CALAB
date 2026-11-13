`timescale 1ns / 1ps

module clock_decrement_tb;
    reg         clk = 0, rst = 1, tick = 0;
    reg  [15:0] sw_in = 0;
    wire [15:0] count;
    wire        state;

    clock_decrement dut (.clk(clk), .rst(rst), .tick(tick),
                         .sw_in(sw_in), .count(count), .state(state));

    always #5 clk = ~clk;

    // tick pulse every 10 clock cycles (stands in for the 1 Hz tick)
    integer n = 0;
    always @(posedge clk) begin
        n    <= (n == 9) ? 0 : n + 1;
        tick <= (n == 9);
    end

    initial begin
        // 1. Reset, then zero input: must stay in WAIT_INPUT
        #22 rst = 0;
        #100;

        // 2. Load 5; then change switches mid-count (must be ignored)
        sw_in = 16'd5;   #20;
        sw_in = 16'd0;   #30;
        sw_in = 16'd9;   #20;
        sw_in = 16'd0;
        #800;            // counts 5..0, returns to WAIT_INPUT

        // 3. Load a different value (8)
        sw_in = 16'd8;   #20;
        sw_in = 16'd0;
        #1000;

        // 4. Reset in the middle of a countdown
        sw_in = 16'd12;  #20;
        sw_in = 16'd0;   #300;
        rst = 1;         #30;
        rst = 0;
        #200;            // count must be 0, state WAIT_INPUT

        $finish;
    end
endmodule