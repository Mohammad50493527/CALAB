module RegisterFile (
    input  wire        clk,
    input  wire        rst,
    input  wire        WriteEnable,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] WriteData,
    output wire [31:0] ReadData1,
    output wire [31:0] ReadData2
);
    localparam [4:0] ZERO_REG = 5'd0;   // x0 is hardwired to zero

    reg [31:0] regs [0:31];
    integer    k;

    // -- Read ports: combinational, x0 bypasses the array --
    assign ReadData1 = (rs1 == ZERO_REG) ? 32'd0 : regs[rs1];
    assign ReadData2 = (rs2 == ZERO_REG) ? 32'd0 : regs[rs2];

    // -- Write enable is gated so that x0 can never be overwritten --
    wire write_ok = WriteEnable & (rd != ZERO_REG);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (k = 0; k < 32; k = k + 1)
                regs[k] <= 32'd0;
        end
        else if (write_ok) begin
            regs[rd] <= WriteData;
        end
    end

endmodule