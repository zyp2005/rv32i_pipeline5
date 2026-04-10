`include "defines.v"

// IF模块 - 取指阶段
// 功能：组合NPC和PC寄存器，处理分支预测失败
module if_state #(
    parameter XLEN = 32,
    parameter INIT_ADDR = 32'h0
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        predict_failed,   // 分支预测失败信号
    input  wire [XLEN-1:0] real_next_pc, // 真实的下一条PC
    input  wire [XLEN-1:0] inst_irom,    // 从irom读取的指令
    input  wire        stall,            // 流水线停顿
    output wire [XLEN-1:0] pc,           // 输出给irom的地址
    output wire [XLEN-1:0] inst          // 输出指令给下一级流水线
);

    // ==========================================
    // 内部信号
    // ==========================================
    wire [XLEN-1:0] npc_out;      // NPC计算的next_pc
    wire [XLEN-1:0] pc_in;        // 实际输入到PC寄存器的值

    // ==========================================
    // NPC模块实例化
    // ==========================================
    npc npc_inst (
        .inst(inst_irom),
        .pc(pc),
        .next_pc(npc_out)
    );

    // ==========================================
    // PC输入选择
    // predict_failed = 1: 使用real_next_pc（预测失败修正）
    // predict_failed = 0: 使用NPC计算值
    // ==========================================
    assign pc_in = predict_failed ? real_next_pc : npc_out;

    // ==========================================
    // PC寄存器实例化
    // ==========================================
    pc_reg #(
        .INIT_ADDR(INIT_ADDR)
    ) pc_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .pc_in(pc_in),
        .stall(stall),
        .pc_out(pc)
    );

    // ==========================================
    // 输出指令
    // ==========================================
    assign inst = inst_irom;

endmodule
