`timescale 1ns/1ps
module RF_ALU_FSM_tb;
    reg         clk, rst;
    wire [2:0]  state;
    wire [4:0]  rs1, rs2, rd;
    wire [31:0] WriteData;
    wire        WriteEnable;
    wire [3:0]  ALUControl;
    wire [31:0] ALUResult;
    wire        Zero;
    wire [3:0]  op_idx;

    RF_ALU_FSM dut (
        .clk(clk), .rst(rst), .state(state),
        .rs1(rs1), .rs2(rs2), .rd(rd),
        .WriteData(WriteData), .WriteEnable(WriteEnable),
        .ALUControl(ALUControl), .ALUResult(ALUResult), .Zero(Zero),
        .op_idx(op_idx)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    localparam [2:0] WRITE_REGISTERS = 3'd6;

    // -- Golden values for ops 0..6 (A = x1 = 0x10101010, B = x2 = 0x01010101) --
    function [31:0] golden(input [3:0] n);
        case (n)
            4'd0:    golden = 32'h11111111; // ADD
            4'd1:    golden = 32'h0F0F0F0F; // SUB
            4'd2:    golden = 32'h00000000; // AND
            4'd3:    golden = 32'h11111111; // OR
            4'd4:    golden = 32'h11111111; // XOR
            4'd5:    golden = 32'h20202020; // SLL
            default: golden = 32'h08080808; // SRL
        endcase
    endfunction

    function [127:0] op_label(input [3:0] n);
        case (n)
            4'd0:    op_label = "ADD";
            4'd1:    op_label = "SUB";
            4'd2:    op_label = "AND";
            4'd3:    op_label = "OR";
            4'd4:    op_label = "XOR";
            4'd5:    op_label = "SLL";
            4'd6:    op_label = "SRL";
            4'd7:    op_label = "BEQ x1,x2";
            default: op_label = "BEQ x1,x1";
        endcase
    endfunction

    reg [2:0] last_state;
    reg [3:0] op_n;
    integer   n_pass, n_fail, cyc;

    task check(input ok, input [511:0] label);
        begin
            if (ok) begin n_pass = n_pass + 1; $display("PASS %0s", label); end
            else    begin n_fail = n_fail + 1; $display("FAIL %0s", label); end
        end
    endtask

    initial begin
        $dumpfile("rf_alu_fsm_tb.vcd");
        $dumpvars(0, RF_ALU_FSM_tb);

        rst = 1; n_pass = 0; n_fail = 0; op_n = 0; last_state = 0;
        @(negedge clk);
        rst = 0;

        // One full run = 4 init cycles + 9 ops x 3 cycles = 31 rising edges
        for (cyc = 0; cyc < 31; cyc = cyc + 1) begin
            @(posedge clk);
            #1;
            // The WRITE_REGISTERS decision is visible on the cycle right after it
            if (last_state == WRITE_REGISTERS && state != WRITE_REGISTERS && op_n < 9) begin
                if (op_n < 7) begin
                    if (WriteEnable === 1'b1 && WriteData === golden(op_n)) begin
                        n_pass = n_pass + 1;
                        $display("PASS %-10s rd=x%0d WriteData=%h", op_label(op_n), rd, WriteData);
                    end
                    else begin
                        n_fail = n_fail + 1;
                        $display("FAIL %-10s rd=x%0d WriteData=%h (expected %h)",
                                 op_label(op_n), rd, WriteData, golden(op_n));
                    end
                end
                else if (op_n == 7) begin
                    // x1 != x2 -> Zero = 0 -> flag must NOT be written
                    if (Zero === 1'b0 && WriteEnable === 1'b0) begin
                        n_pass = n_pass + 1;
                        $display("PASS %-10s Zero=0, flag x11 not written", op_label(op_n));
                    end
                    else begin
                        n_fail = n_fail + 1;
                        $display("FAIL %-10s Zero=%b WriteEnable=%b", op_label(op_n), Zero, WriteEnable);
                    end
                end
                else begin
                    // x1 == x1 -> Zero = 1 -> flag x12 = 1 must be written
                    if (Zero === 1'b1 && WriteEnable === 1'b1 && rd === 5'd12 && WriteData === 32'd1) begin
                        n_pass = n_pass + 1;
                        $display("PASS %-10s Zero=1, flag x12 written = 1", op_label(op_n));
                    end
                    else begin
                        n_fail = n_fail + 1;
                        $display("FAIL %-10s Zero=%b WriteEnable=%b rd=x%0d WriteData=%h",
                                 op_label(op_n), Zero, WriteEnable, rd, WriteData);
                    end
                end
                op_n = op_n + 1;
            end
            last_state = state;
        end

        // Let the last write land, then read the stored values back from the register file
        repeat (2) @(posedge clk);
        #1;
        check(dut.u_rf.regs[1] === 32'h10101010 && dut.u_rf.regs[2] === 32'h01010101 &&
              dut.u_rf.regs[3] === 32'h00000005, "init constants stored in x1,x2,x3");
        for (cyc = 0; cyc < 7; cyc = cyc + 1) begin
            if (dut.u_rf.regs[4 + cyc] === golden(cyc[3:0])) begin
                n_pass = n_pass + 1;
                $display("PASS stored %-4s x%0d=%h", op_label(cyc[3:0]), 4 + cyc, dut.u_rf.regs[4 + cyc]);
            end
            else begin
                n_fail = n_fail + 1;
                $display("FAIL stored %-4s x%0d=%h (expected %h)",
                         op_label(cyc[3:0]), 4 + cyc, dut.u_rf.regs[4 + cyc], golden(cyc[3:0]));
            end
        end
        check(dut.u_rf.regs[11] === 32'd0, "x11 flag still 0 (BEQ not equal, no write)");
        check(dut.u_rf.regs[12] === 32'd1, "x12 flag = 1 (BEQ equal, written)");

        $display("--------------------------------------------------");
        $display("RF+ALU+FSM integration: %0d PASS, %0d FAIL (of 19)", n_pass, n_fail);

        #10 $finish;
    end
endmodule