`include "defines.v"

// ID_EX 流水线寄存器
// 功能：在 ID 和 EX 阶段之间传递数据和控制信号
// stall = 1: 保持当前值不变
// flush = 1: 清空为 NOP 状态
module id_ex #(
    parameter XLEN = 32
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,
    input  wire        flush,

    // ID 阶段输入
    input  wire [XLEN-1:0] pc,
    input  wire [XLEN-1:0] rs1,
    input  wire [XLEN-1:0] rs2,
    input  wire [4:0]      rs1_addr,
    input  wire [4:0]      rs2_addr,
    input  wire [XLEN-1:0] imm,
    input  wire [4:0]      rd_addr,

    // 控制信号输入
    input  wire        rs2_or_imm_ex,
    input  wire        reg_wen_wb,
    input  wire        wen_mem,
    input  wire        ren_mem,
    input  wire        is_jalr_ex,
    input  wire        is_lui_ex,
    input  wire [1:0]  ALUop_ex,
    input  wire        is_jal_ex,
    input  wire        is_auipc_ex,
    input  wire [6:0]  funct7,
    input  wire [2:0]  funct3,
    input  wire        is_predict_jump,
    input  wire [1:0]  mem_width_mem,
    input  wire        is_u_load_mem,

    // EX 阶段输出
    output reg  [XLEN-1:0] pc_out,
    output reg  [XLEN-1:0] rs1_out,
    output reg  [XLEN-1:0] rs2_out,
    output reg  [4:0]      rs1_addr_out,
    output reg  [4:0]      rs2_addr_out,
    output reg  [XLEN-1:0] imm_out,
    output reg  [4:0]      rd_addr_out,

    output reg         rs2_or_imm_ex_out,
    output reg         reg_wen_wb_out,
    output reg         wen_mem_out,
    output reg         ren_mem_out,
    output reg         is_jalr_ex_out,
    output reg         is_lui_ex_out,
    output reg  [1:0]  ALUop_ex_out,
    output reg         is_jal_ex_out,
    output reg         is_auipc_ex_out,
    output reg  [6:0]  funct7_out,
    output reg  [2:0]  funct3_out,
    output reg         is_predict_jump_out,
    output reg  [1:0]  mem_width_mem_out,
    output reg         is_u_load_mem_out
);

    always @(posedge clk) begin
        if (!rst_n) begin
            pc_out              <= 32'h0;
            rs1_out             <= 32'h0;
            rs2_out             <= 32'h0;
            rs1_addr_out        <= 5'h0;
            rs2_addr_out        <= 5'h0;
            imm_out             <= 32'h0;
            rd_addr_out         <= 5'h0;
            rs2_or_imm_ex_out   <= 1'b0;
            reg_wen_wb_out      <= 1'b0;
            wen_mem_out         <= 1'b0;
            ren_mem_out         <= 1'b0;
            is_jalr_ex_out      <= 1'b0;
            is_lui_ex_out       <= 1'b0;
            ALUop_ex_out        <= 2'b0;
            is_jal_ex_out       <= 1'b0;
            is_auipc_ex_out     <= 1'b0;
            funct7_out          <= 7'h0;
            funct3_out          <= 3'h0;
            is_predict_jump_out <= 1'b0;
            mem_width_mem_out   <= 2'b0;
            is_u_load_mem_out   <= 1'b0;
        end else if (flush) begin
            pc_out              <= 32'h0;
            rs1_out             <= 32'h0;
            rs2_out             <= 32'h0;
            rs1_addr_out        <= 5'h0;
            rs2_addr_out        <= 5'h0;
            imm_out             <= 32'h0;
            rd_addr_out         <= 5'h0;
            rs2_or_imm_ex_out   <= 1'b0;
            reg_wen_wb_out      <= 1'b0;
            wen_mem_out         <= 1'b0;
            ren_mem_out         <= 1'b0;
            is_jalr_ex_out      <= 1'b0;
            is_lui_ex_out       <= 1'b0;
            ALUop_ex_out        <= 2'b0;
            is_jal_ex_out       <= 1'b0;
            is_auipc_ex_out     <= 1'b0;
            funct7_out          <= 7'h0;
            funct3_out          <= 3'h0;
            is_predict_jump_out <= 1'b0;
            mem_width_mem_out   <= 2'b0;
            is_u_load_mem_out   <= 1'b0;
        end else if (stall) begin
            // stall: 保持当前值不变 --> 是清空
            pc_out              <= 32'h0;
            rs1_out             <= 32'h0;
            rs2_out             <= 32'h0;
            rs1_addr_out        <= 5'h0;
            rs2_addr_out        <= 5'h0;
            imm_out             <= 32'h0;
            rd_addr_out         <= 5'h0;
            rs2_or_imm_ex_out   <= 1'b0;
            reg_wen_wb_out      <= 1'b0;
            wen_mem_out         <= 1'b0;
            ren_mem_out         <= 1'b0;
            is_jalr_ex_out      <= 1'b0;
            is_lui_ex_out       <= 1'b0;
            ALUop_ex_out        <= 2'b0;
            is_jal_ex_out       <= 1'b0;
            is_auipc_ex_out     <= 1'b0;
            funct7_out          <= 7'h0;
            funct3_out          <= 3'h0;
            is_predict_jump_out <= 1'b0;
            mem_width_mem_out   <= 2'b0;
            is_u_load_mem_out   <= 1'b0;
        end else begin
            pc_out              <= pc;
            rs1_out             <= rs1;
            rs2_out             <= rs2;
            rs1_addr_out        <= rs1_addr;
            rs2_addr_out        <= rs2_addr;
            imm_out             <= imm;
            rd_addr_out         <= rd_addr;
            rs2_or_imm_ex_out   <= rs2_or_imm_ex;
            reg_wen_wb_out      <= reg_wen_wb;
            wen_mem_out         <= wen_mem;
            ren_mem_out         <= ren_mem;
            is_jalr_ex_out      <= is_jalr_ex;
            is_lui_ex_out       <= is_lui_ex;
            ALUop_ex_out        <= ALUop_ex;
            is_jal_ex_out       <= is_jal_ex;
            is_auipc_ex_out     <= is_auipc_ex;
            funct7_out          <= funct7;
            funct3_out          <= funct3;
            is_predict_jump_out <= is_predict_jump;
            mem_width_mem_out   <= mem_width_mem;
            is_u_load_mem_out   <= is_u_load_mem;
        end
    end

endmodule
