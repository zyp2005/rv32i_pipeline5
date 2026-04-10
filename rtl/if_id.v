`include "defines.v"

// IF_ID流水线寄存器
// 功能：在IF和ID阶段之间传递指令和PC
// stall = 1: 保持当前值不变
// flush = 1: 清空寄存器（输出NOP指令）
module if_id #(
    parameter XLEN = 32
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,
    input  wire        flush,
    input  wire [XLEN-1:0] inst_in,
    input  wire [XLEN-1:0] pc_in,
    output reg  [XLEN-1:0] inst_out,
    output reg  [XLEN-1:0] pc_out
);

    always @(posedge clk) begin
        if (!rst_n) begin
            inst_out <= `INST_NOP;
            pc_out <= 32'h0;
        end else if (flush) begin
            inst_out <= `INST_NOP;
            pc_out <= 32'h0;
        end else if (stall) begin
            inst_out <= inst_out;
            pc_out <= pc_out;
        end else begin
            inst_out <= inst_in;
            pc_out <= pc_in;
        end
    end

endmodule
