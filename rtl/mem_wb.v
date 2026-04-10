`include "defines.v"

// MEM_WB 流水线寄存器
// 功能：在 MEM 和 WB 阶段之间传递数据和控制信号
module mem_wb #(
    parameter XLEN = 32
)(
    input  wire        clk,
    input  wire        rst_n,

    // MEM 阶段输入
    input wire [XLEN-1:0] rd,
    input wire [4:0]      rd_addr,
    input wire            reg_wen_wb,

    // WB 阶段输出
    output reg  [XLEN-1:0] rd_out,
    output reg  [4:0]      rd_addr_out,
    output reg             reg_wen_wb_out
);

    always @(posedge clk) begin
        if (!rst_n) begin
            rd_out          <= 32'h0;
            rd_addr_out     <= 5'h0;
            reg_wen_wb_out  <= 1'b0;
        end else begin
            rd_out          <= rd;
            rd_addr_out     <= rd_addr;
            reg_wen_wb_out  <= reg_wen_wb;
        end
    end

endmodule
