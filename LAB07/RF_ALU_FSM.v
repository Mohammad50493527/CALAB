module RF_ALU_FSM (
    input  wire        clk,
    input  wire        rst,
    output reg  [2:0]  state,
    output reg  [4:0]  rs1,
    output reg  [4:0]  rs2,
    output reg  [4:0]  rd,
    output reg  [31:0] WriteData,
    output reg         WriteEnable,
    output reg  [3:0]  ALUControl,
    output wire [31:0] ALUResult,
    output wire        Zero,
    output reg  [3:0]  op_idx
);
    // -- State encoding --
    localparam [2:0] IDLE            = 3'd0,
                     INIT_X1         = 3'd1,
                     INIT_X2         = 3'd2,
                     INIT_X3         = 3'd3,
                     READ_REGISTERS  = 3'd4,
                     ALU_OPERATION   = 3'd5,
                     WRITE_REGISTERS = 3'd6;

    // -- Initial register contents --
    localparam [31:0] X1_INIT = 32'h10101010,
                      X2_INIT = 32'h01010101,
                      X3_INIT = 32'h00000005;

    // -- ALUControl codes: EDIT THESE to match the encoding in your ALU_top --
    localparam [3:0] ALU_ADD = 4'd0,
                     ALU_SUB = 4'd1,
                     ALU_AND = 4'd2,
                     ALU_OR  = 4'd3,
                     ALU_XOR = 4'd4,
                     ALU_SLL = 4'd5,
                     ALU_SRL = 4'd6;

    // op_idx 0..6 = ADD, SUB, AND, OR, XOR, SLL, SRL -> results to x4..x10
    // op_idx 7    = BEQ x1,x2 (not equal) -> flag x11 written only if Zero
    // op_idx 8    = BEQ x1,x1 (equal)     -> flag x12 written only if Zero
    localparam [3:0] BEQ_NE  = 4'd7,
                     BEQ_EQ  = 4'd8,
                     LAST_OP = 4'd8;

    wire is_beq  = (op_idx == BEQ_NE) || (op_idx == BEQ_EQ);
    wire last_op = (op_idx == LAST_OP);

    // BEQ is done with SUB: Zero = 1 when the two operands are equal
    function [3:0] alu_code_of(input [3:0] idx);
        case (idx)
            4'd0:    alu_code_of = ALU_ADD;
            4'd1:    alu_code_of = ALU_SUB;
            4'd2:    alu_code_of = ALU_AND;
            4'd3:    alu_code_of = ALU_OR;
            4'd4:    alu_code_of = ALU_XOR;
            4'd5:    alu_code_of = ALU_SLL;
            4'd6:    alu_code_of = ALU_SRL;
            default: alu_code_of = ALU_SUB;   // BEQ checks
        endcase
    endfunction

    function [4:0] dest_of(input [3:0] idx);
        dest_of = 5'd4 + {1'b0, idx};         // x4..x12
    endfunction

    // -- Register file and ALU --
    wire [31:0] ReadData1, ReadData2;

    RegisterFile u_rf (
        .clk(clk), .rst(rst), .WriteEnable(WriteEnable),
        .rs1(rs1), .rs2(rs2), .rd(rd), .WriteData(WriteData),
        .ReadData1(ReadData1), .ReadData2(ReadData2)
    );

    ALU_top u_alu (
        .A(ReadData1), .B(ReadData2),
        .ALUControl(ALUControl),
        .ALUResult(ALUResult), .Zero(Zero)
    );

    // -- FSM --
    always @(posedge clk) begin
        if (rst) begin
            state       <= IDLE;
            rs1         <= 5'd0;
            rs2         <= 5'd0;
            rd          <= 5'd0;
            WriteData   <= 32'd0;
            WriteEnable <= 1'b0;
            ALUControl  <= 4'd0;
            op_idx      <= 4'd0;
        end
        else begin
            case (state)
                IDLE: begin
                    WriteEnable <= 1'b0;
                    state       <= INIT_X1;
                end

                INIT_X1: begin
                    rd          <= 5'd1;
                    WriteData   <= X1_INIT;
                    WriteEnable <= 1'b1;
                    state       <= INIT_X2;
                end

                INIT_X2: begin
                    rd          <= 5'd2;
                    WriteData   <= X2_INIT;
                    WriteEnable <= 1'b1;
                    state       <= INIT_X3;
                end

                INIT_X3: begin
                    rd          <= 5'd3;
                    WriteData   <= X3_INIT;
                    WriteEnable <= 1'b1;
                    op_idx      <= 4'd0;
                    state       <= READ_REGISTERS;
                end

                READ_REGISTERS: begin
                    WriteEnable <= 1'b0;
                    rs1         <= 5'd1;                                    // operand A = x1
                    rs2         <= (op_idx == BEQ_EQ) ? 5'd1 : 5'd2;        // operand B = x2 (x1 for the equal check)
                    state       <= ALU_OPERATION;
                end

                ALU_OPERATION: begin
                    ALUControl  <= alu_code_of(op_idx); // result settles combinationally
                    state       <= WRITE_REGISTERS;
                end

                WRITE_REGISTERS: begin
                    rd          <= dest_of(op_idx);
                    if (is_beq) begin
                        WriteData   <= 32'd1;           // flag value
                        WriteEnable <= Zero;            // conditional write: only if operands equal
                    end
                    else begin
                        WriteData   <= ALUResult;
                        WriteEnable <= 1'b1;
                    end
                    if (last_op) begin
                        op_idx      <= 4'd0;
                        state       <= IDLE;            // all operations done
                    end
                    else begin
                        op_idx      <= op_idx + 4'd1;
                        state       <= READ_REGISTERS;  // next operation
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule