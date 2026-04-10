`include "defines.v"

// 寄存器堆模块
// 32 个通用寄存器，异步读取，同步写入，x0 始终为 0
// 支持前递：当 rd_addr=rs_addr 时，直接输出 rd
module regfile #(
    parameter XLEN = 32
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        reg_wen,
    input  wire [XLEN-1:0] rd,
    input  wire [4:0]  rd_addr,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    output wire [XLEN-1:0] rs1,
    output wire [XLEN-1:0] rs2
);

    reg [XLEN-1:0] regs [0:31];

    // 同步写入，x0 不能写
    always @(posedge clk) begin
        if (!rst_n) begin
            regs[0]  <= 32'h0;
            regs[1]  <= 32'h0;
            regs[2]  <= 32'h0;
            regs[3]  <= 32'h0;
            regs[4]  <= 32'h0;
            regs[5]  <= 32'h0;
            regs[6]  <= 32'h0;
            regs[7]  <= 32'h0;
            regs[8]  <= 32'h0;
            regs[9]  <= 32'h0;
            regs[10] <= 32'h0;
            regs[11] <= 32'h0;
            regs[12] <= 32'h0;
            regs[13] <= 32'h0;
            regs[14] <= 32'h0;
            regs[15] <= 32'h0;
            regs[16] <= 32'h0;
            regs[17] <= 32'h0;
            regs[18] <= 32'h0;
            regs[19] <= 32'h0;
            regs[20] <= 32'h0;
            regs[21] <= 32'h0;
            regs[22] <= 32'h0;
            regs[23] <= 32'h0;
            regs[24] <= 32'h0;
            regs[25] <= 32'h0;
            regs[26] <= 32'h0;
            regs[27] <= 32'h0;
            regs[28] <= 32'h0;
            regs[29] <= 32'h0;
            regs[30] <= 32'h0;
            regs[31] <= 32'h0;
        end else if (reg_wen && rd_addr != 5'b0) begin
            regs[rd_addr] <= rd;
        end
    end

    // 异步读取，带前递逻辑
    wire [XLEN-1:0] rs1_reg;
    wire [XLEN-1:0] rs2_reg;

    assign rs1_reg = (rs1_addr == 5'b0) ? 32'h0 : regs[rs1_addr];
    assign rs2_reg = (rs2_addr == 5'b0) ? 32'h0 : regs[rs2_addr];

    // 前递：只有当 reg_wen=1 且 rd_addr 有效时才进行前递比较
    assign rs1 = (reg_wen && rd_addr != 5'b0 && rd_addr == rs1_addr) ? rd : rs1_reg;
    assign rs2 = (reg_wen && rd_addr != 5'b0 && rd_addr == rs2_addr) ? rd : rs2_reg;

endmodule
