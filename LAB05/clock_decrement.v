`timescale 1ns / 1ps

module clock_decrement (
    input  wire        clk,   // 100 MHz system clock
    input  wire        rst,   // synchronous reset (debounced button)
    input  wire        tick,  // 1-cycle pulse at the slow (1 Hz) rate
    input  wire [15:0] sw_in, // switch value
    output reg  [15:0] count, // latched value / current count -> LEDs
    output reg         state  // 0 = WAIT_INPUT, 1 = COUNTDOWN
);

    localparam WAIT_INPUT = 1'b0,
               COUNTDOWN  = 1'b1;

    always @(posedge clk) begin
        if (rst) begin
            state <= WAIT_INPUT;
            count <= 16'd0;
        end else begin
            case (state)
                WAIT_INPUT: begin
                    if (sw_in != 16'd0) begin
                        count <= sw_in;      // latch switches, show on LEDs
                        state <= COUNTDOWN;
                    end else begin
                        count <= 16'd0;
                    end
                end

                COUNTDOWN: begin             // switches ignored here
                    if (tick) begin
                        if (count == 16'd1) begin
                            count <= 16'd0;
                            state <= WAIT_INPUT; // auto-return at zero
                        end else begin
                            count <= count - 16'd1;
                        end
                    end
                end
            endcase
        end
    end
endmodule