`timescale 1ns/1ps
module RegisterFile_tb;
    reg         clk, rst, WriteEnable;
    reg  [4:0]  rs1, rs2, rd;
    reg  [31:0] WriteData;
    wire [31:0] ReadData1, ReadData2;

    integer n_pass, n_fail;

    RegisterFile dut (
        .clk(clk), .rst(rst), .WriteEnable(WriteEnable),
        .rs1(rs1), .rs2(rs2), .rd(rd), .WriteData(WriteData),
        .ReadData1(ReadData1), .ReadData2(ReadData2)
    );

    // 10 ns clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -- Drive one write on the falling edge so it is captured on the next rising edge --
    task do_write(input [4:0] addr, input [31:0] data);
        begin
            @(negedge clk);
            rd = addr; WriteData = data; WriteEnable = 1'b1;
            @(posedge clk);
            @(negedge clk);
            WriteEnable = 1'b0;
        end
    endtask

    // -- Select two read addresses, wait for them to settle, then compare --
    task verify(input [4:0] a1, input [31:0] exp1,
                input [4:0] a2, input [31:0] exp2,
                input [127:0] label);
        begin
            rs1 = a1; rs2 = a2;
            #1;
            if ((ReadData1 === exp1) && (ReadData2 === exp2)) begin
                n_pass = n_pass + 1;
                $display("PASS %-20s RD1=%h RD2=%h", label, ReadData1, ReadData2);
            end
            else begin
                n_fail = n_fail + 1;
                $display("FAIL %-20s RD1=%h (exp %h) RD2=%h (exp %h)",
                         label, ReadData1, exp1, ReadData2, exp2);
            end
        end
    endtask

    initial begin
        $dumpfile("regfile_tb.vcd");
        $dumpvars(0, RegisterFile_tb);

        n_pass = 0; n_fail = 0;
        rst = 1; WriteEnable = 0; rs1 = 0; rs2 = 0; rd = 0; WriteData = 0;
        @(negedge clk);          // hold reset across one rising edge
        rst = 0;

        // Test 1: a written value reads back
        do_write(5, 32'hDEADBEEF);
        verify(5, 32'hDEADBEEF, 0, 32'd0, "write-then-read");

        // Test 2: writes to x0 are ignored
        do_write(0, 32'hFFFFFFFF);
        verify(0, 32'd0, 0, 32'd0, "x0-write-ignored");

        // Test 3: both read ports work at once
        do_write(6, 32'h11111111);
        verify(5, 32'hDEADBEEF, 6, 32'h11111111, "dual-read-ports");

        // Test 4: a second write replaces the first
        do_write(5, 32'hCAFEBABE);
        verify(5, 32'hCAFEBABE, 0, 32'd0, "overwrite");

        // Test 5: reset wipes every register
        rst = 1;
        @(negedge clk);
        rst = 0;
        verify(5, 32'd0, 6, 32'd0, "reset-clears-all");

        $display("RegisterFile: %0d PASS, %0d FAIL", n_pass, n_fail);
        #10 $finish;
    end
endmodule
