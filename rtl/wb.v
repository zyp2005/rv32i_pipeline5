`include "defines.v"

// WB 模块 - 写回阶段
// 功能：将数据写回到寄存器堆
module wb #(
    parameter XLEN = 32
)(
    // 来自 MEM_WB 寄存器
    input wire [XLEN-1:0] rd,
    input wire [4:0]      rd_addr,
    input wire            reg_wen_wb,

    // 输出到 regfile
    output wire [XLEN-1:0] wb_rd,
    output wire [4:0]      wb_rd_addr,
    output wire            wb_reg_wen
);

    // 数据直通到寄存器堆
    assign wb_rd = rd;
    assign wb_rd_addr = rd_addr;
    assign wb_reg_wen = reg_wen_wb;

endmodule
