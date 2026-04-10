`include "defines.v"

// PC寄存器模块
// 功能：保存当前PC值，支持同步复位和流水线停顿
// 参数：INIT_ADDR - PC初始地址，默认为0
module pc_reg #(
    parameter INIT_ADDR = 32'h0
) (
    input  wire        clk,
    input  wire        rst_n,      // 同步复位，低电平有效
    input  wire [31:0] pc_in,
    input  wire        stall,      // 高电平时保持PC不变
    output reg  [31:0] pc_out
);

    always @(posedge clk) begin
        if (!rst_n) begin
            pc_out <= INIT_ADDR;
        end else if (stall) begin
            pc_out <= pc_out;
        end else begin
            pc_out <= pc_in;
        end
    end

endmodule // pc_reg
