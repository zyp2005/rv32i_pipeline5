`include "defines.v"

// =============================================================================
// EX_MEM 流水线寄存器
// =============================================================================
// 功能：在 EX 和 MEM 阶段之间传递数据和控制信号
// =============================================================================

module ex_mem #(
    parameter XLEN = 32
)(
    input  wire        clk,
    input  wire        rst_n,

    // EX 阶段输入
    input wire [4:0]      rd_addr,
    input wire            reg_wen_wb,
    input wire            wen_mem,
    input wire            ren_mem,
    input wire [1:0]      mem_width_mem,
    input wire            is_u_load_mem,

    input wire [XLEN-1:0] rs2,
    input wire [XLEN-1:0] alu_result,

    // MEM 阶段输出
    output reg  [4:0]      rd_addr_out,
    output reg             reg_wen_wb_out,
    output reg             wen_mem_out,
    output reg             ren_mem_out,
    output reg  [1:0]      mem_width_mem_out,
    output reg             is_u_load_mem_out,

    output reg  [XLEN-1:0] rs2_out,
    output reg  [XLEN-1:0] alu_result_out
);

    always @(posedge clk) begin
        if (!rst_n) begin
            rd_addr_out         <= 5'h0;
            reg_wen_wb_out      <= 1'b0;
            wen_mem_out         <= 1'b0;
            ren_mem_out         <= 1'b0;
            mem_width_mem_out   <= 2'b0;
            is_u_load_mem_out   <= 1'b0;
            rs2_out             <= 32'h0;
            alu_result_out      <= 32'h0;
        end else begin
            rd_addr_out         <= rd_addr;
            reg_wen_wb_out      <= reg_wen_wb;
            wen_mem_out         <= wen_mem;
            ren_mem_out         <= ren_mem;
            mem_width_mem_out   <= mem_width_mem;
            is_u_load_mem_out   <= is_u_load_mem;
            rs2_out             <= rs2;
            alu_result_out      <= alu_result;
        end
    end

endmodule
