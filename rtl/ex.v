`include "defines.v"

// =============================================================================
// EX 模块 - 执行阶段
// =============================================================================
// 功能：组合 alu_control、alu、branch 模块，处理数据转发和分支预测
// =============================================================================

module ex #(
    parameter XLEN = 32
)(
    // 来自 ID_EX 寄存器
    input wire [XLEN-1:0] pc,
    input wire [XLEN-1:0] rs1,
    input wire [XLEN-1:0] rs2,
    input wire [4:0]      rs1_addr,
    input wire [4:0]      rs2_addr,
    input wire [XLEN-1:0] imm,
    input wire [4:0]      rd_addr,
    input wire [1:0]      ALUop,
    input wire            rs2_or_imm,
    input wire            reg_wen_wb,
    input wire            wen_mem,
    input wire            ren_mem,
    input wire            is_jalr,
    input wire            is_lui,
    input wire            is_jal,
    input wire            is_auipc,
    input wire [2:0]      funct3,
    input wire [6:0]      funct7,
    input wire            is_predict_jump,
    input wire [1:0]      mem_width_mem,
    input wire            is_u_load_mem,

    // Forward 控制
    input wire [1:0]      forward_a,
    input wire [1:0]      forward_b,


    // 来自 MEM 和 WB 的数据 (用于 forward)
    input wire [XLEN-1:0] mem_rd,
    input wire [XLEN-1:0] wb_rd,

    // 输出
    output wire           flush,
    output wire           predict_failed,
    output wire [XLEN-1:0] real_rs2,
    output wire [XLEN-1:0] alu_real_result,
    output wire [XLEN-1:0] real_next_pc,

    // 控制信号输出 (传递到后续阶段)
    output wire [4:0]      rs1_addr_out,
    output wire [4:0]      rs2_addr_out,
    output wire [4:0]      rd_addr_out,
    output wire            reg_wen_wb_out,
    output wire            wen_mem_out,
    output wire            ren_mem_out,
    output wire [1:0]      mem_width_mem_out,
    output wire            is_u_load_mem_out
);

    wire [XLEN-1:0] rs1_selected;
    wire [XLEN-1:0] rs2_selected;
    wire [XLEN-1:0] alu_input_a;
    wire [XLEN-1:0] alu_input_b;
    wire [XLEN-1:0] alu_result;
    wire            alu_zero;
    wire [3:0]      ALU_control;
    wire            branch_flush;
    wire            branch_predict_failed;

    // forward_a 选择 rs1
    assign rs1_selected = (forward_a == `FWD_MEM) ? mem_rd :
                          (forward_a == `FWD_WB)  ? wb_rd :
                                                    rs1;

    // forward_b 选择 rs2
    assign rs2_selected = (forward_b == `FWD_MEM) ? mem_rd :
                          (forward_b == `FWD_WB)  ? wb_rd :
                                                    rs2;

    // ALU 输入 a：real_rs1 或 pc (is_jal/is_jalr/is_auipc)
    assign alu_input_a = (is_jal || is_jalr || is_auipc) ? pc : rs1_selected;

    // ALU 输入 b：real_rs2 或 imm 或 4
    wire [XLEN-1:0] b_rs2_or_imm;
    assign b_rs2_or_imm = rs2_or_imm ? imm : rs2_selected;
    assign alu_input_b = (is_jal || is_jalr) ? 32'd4 : b_rs2_or_imm;

    // real_rs2 输出
    assign real_rs2 = rs2_selected;

    // real_next_pc: BTFNT 预测失败时的 PC 修正
    // 当 predict_failed=1 时，实际结果与预测相反：
    //   - is_predict_jump=1（预测跳转），实际不跳 → PC+4
    //   - is_predict_jump=0（预测不跳），实际跳转 → PC+imm
    assign real_next_pc = is_jalr ? (rs1_selected + imm) :
                          (ALUop == `ALUOP_BRANCH) ? (is_predict_jump ? (pc + 32'd4) : (pc + imm)) :
                          (pc + imm);  // JAL 总是跳转

    // 控制信号直接传递到输出
    assign rs1_addr_out = rs1_addr;
    assign rs2_addr_out = rs2_addr;
    assign rd_addr_out = rd_addr;
    assign reg_wen_wb_out = reg_wen_wb;
    assign wen_mem_out = wen_mem;
    assign ren_mem_out = ren_mem;
    assign mem_width_mem_out = mem_width_mem;
    assign is_u_load_mem_out = is_u_load_mem;

    // ALU 控制模块
    alu_control alu_control_inst (
        .ALUop(ALUop),
        .imm(imm),
        .funct7(funct7),
        .funct3(funct3),
        .ALU_control(ALU_control)
    );

    // ALU 模块
    alu alu_inst (
        .a(alu_input_a),
        .b(alu_input_b),
        .ALU_control(ALU_control),
        .result(alu_result),
        .zero(alu_zero)
    );

    // ALU 输出选择：alu_result 或 imm (is_lui)
    assign alu_real_result = is_lui ? imm : alu_result;

    // Branch 模块
    branch branch_inst (
        .ALUop(ALUop),
        .is_predict_jump(is_predict_jump),
        .funct3(funct3),
        .alu_result(alu_result),
        .zero(alu_zero),
        .flush(branch_flush),
        .predict_failed(branch_predict_failed)
    );

    // flush 和 predict_failed 选择：is_jalr 强制跳转
    assign flush = is_jalr ? 1'b1 : branch_flush;
    assign predict_failed = is_jalr ? 1'b1 : branch_predict_failed;

endmodule
