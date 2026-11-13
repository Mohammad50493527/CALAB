module top_rf_alu #(
    parameter TICK_MAX = 27'd99_999_999
) (
    input  wire        clk,
    input  wire        pbin,
    input  wire [15:0] physical_sw,
    output wire [15:0] physical_leds,
    output wire [6:0]  seg,
    output wire [3:0]  an
);

    // -- Reset button, debounced --
    wire rst_clean;
    debouncer rst_db (
        .clk   (clk),
        .pbin  (pbin),
        .pbout (rst_clean)
    );

    // -- Switch input / LED output peripherals --
    wire [31:0] switch_data;
    leds switch_reader (
        .clk(clk), .rst(rst_clean),
        .btns(16'd0), .writeData(32'd0), .writeEnable(1'b0),
        .readEnable(1'b1), .memAddress(30'd0),
        .switches(physical_sw), .readData(switch_data)
    );

    reg [31:0] led_write_data = 32'd0;
    switches led_writer (
        .clk(clk), .rst(rst_clean),
        .writeData(led_write_data), .writeEnable(1'b1),
        .readEnable(1'b0), .memAddress(30'd0),
        .readData(), .leds(physical_leds)
    );

    // -- Mode select and manual-control fields taken from the switches --
    wire        manual_mode = switch_data[10];   // 0 = AUTO, 1 = MANUAL
    wire        manual_we   = switch_data[9];
    wire [4:0]  manual_rd   = switch_data[8:4];
    wire [3:0]  manual_ctrl = switch_data[3:0];

    // -- Register file + ALU (one shared instance of each) --
    wire [4:0]  rs1, rs2, final_rd;
    wire [31:0] WriteData_final;
    wire        WriteEnable_final;
    wire [3:0]  ALUControl_final;
    wire [31:0] ReadData1, ReadData2, ALUResult;
    wire        Zero;

    RegisterFile u_rf (
        .clk(clk), .rst(rst_clean), .WriteEnable(WriteEnable_final),
        .rs1(rs1), .rs2(rs2), .rd(final_rd), .WriteData(WriteData_final),
        .ReadData1(ReadData1), .ReadData2(ReadData2)
    );

    ALU_top u_alu (
        .A(ReadData1), .B(ReadData2),
        .ALUControl(ALUControl_final),
        .ALUResult(ALUResult), .Zero(Zero)
    );

    // -- Slow step tick for the AUTO sequence --
    reg [26:0] tick_cnt = 27'd0;
    wire       tick     = (tick_cnt == TICK_MAX);

    always @(posedge clk or posedge rst_clean) begin
        if (rst_clean)
            tick_cnt <= 27'd0;
        else if (tick)
            tick_cnt <= 27'd0;
        else
            tick_cnt <= tick_cnt + 1'b1;
    end

    // -- AUTO-mode FSM (same sequence as RF_ALU_FSM, advanced once per tick) --
    localparam [2:0] IDLE            = 3'd0,
                     INIT_X1         = 3'd1,
                     INIT_X2         = 3'd2,
                     INIT_X3         = 3'd3,
                     READ_REGISTERS  = 3'd4,
                     ALU_OPERATION   = 3'd5,
                     WRITE_REGISTERS = 3'd6;

    localparam [31:0] X1_INIT = 32'h10101010,
                      X2_INIT = 32'h01010101,
                      X3_INIT = 32'h00000005;

    localparam [3:0] BEQ_NE  = 4'd7,   // BEQ x1,x2 : flag x11 written only if Zero
                     BEQ_EQ  = 4'd8,   // BEQ x1,x1 : flag x12 written only if Zero
                     LAST_OP = 4'd8;

    reg  [2:0]  auto_state;
    reg  [4:0]  auto_rd;
    reg  [31:0] auto_WriteData;
    reg         auto_WE;
    reg  [3:0]  auto_ALUControl;
    reg  [3:0]  op_idx;
    reg  [4:0]  auto_rs2;
    wire        is_beq = (op_idx == BEQ_NE) || (op_idx == BEQ_EQ);

    // -- ALUControl codes: EDIT THESE to match the encoding in your ALU_top --
    localparam [3:0] ALU_ADD = 4'd0,
                     ALU_SUB = 4'd1,
                     ALU_AND = 4'd2,
                     ALU_OR  = 4'd3,
                     ALU_XOR = 4'd4,
                     ALU_SLL = 4'd5,
                     ALU_SRL = 4'd6;

    // idx 0..7 = ADD, SUB, AND, OR, XOR, SLL, SRL, BEQ
    // BEQ has no ALU op of its own: it runs SUB and uses the Zero flag (x1 - x2 == 0).
    function [3:0] alu_code_of(input [3:0] idx);
        case (idx)
            4'd0:    alu_code_of = ALU_ADD;
            4'd1:    alu_code_of = ALU_SUB;
            4'd2:    alu_code_of = ALU_AND;
            4'd3:    alu_code_of = ALU_OR;
            4'd4:    alu_code_of = ALU_XOR;
            4'd5:    alu_code_of = ALU_SLL;
            4'd6:    alu_code_of = ALU_SRL;
            default: alu_code_of = ALU_SUB;   // BEQ checks use SUB + Zero
        endcase
    endfunction

    function [4:0] dest_of(input [3:0] idx);
        dest_of = 5'd4 + {1'b0, idx};         // x4..x12
    endfunction

    // AUTO mode always reads x1 and x2
    assign rs1 = 5'd1;
    assign rs2 = auto_rs2;

    always @(posedge clk or posedge rst_clean) begin
        if (rst_clean) begin
            auto_state      <= IDLE;
            auto_rd         <= 5'd0;
            auto_WriteData  <= 32'd0;
            auto_WE         <= 1'b0;
            auto_ALUControl <= 4'd0;
            op_idx          <= 4'd0;
            auto_rs2        <= 5'd2;
        end
        else if (tick) begin
            case (auto_state)
                IDLE: begin
                    auto_WE    <= 1'b0;
                    auto_state <= INIT_X1;
                end

                INIT_X1: begin
                    auto_rd        <= 5'd1;
                    auto_WriteData <= X1_INIT;
                    auto_WE        <= 1'b1;
                    auto_state     <= INIT_X2;
                end

                INIT_X2: begin
                    auto_rd        <= 5'd2;
                    auto_WriteData <= X2_INIT;
                    auto_WE        <= 1'b1;
                    auto_state     <= INIT_X3;
                end

