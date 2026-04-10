`include "defines.v"

// CPU 顶层模块 - 5 级流水线 RV32I 处理器
module cpu #(
    parameter XLEN = 32,
    parameter INIT_ADDR = 32'h0
)(
    input  wire        clk,
    input  wire        rst_n,

    // 与 irom 接口
    output wire [XLEN-1:0] pc_out,
    input  wire [XLEN-1:0] inst_in,

    // 与 drom 接口
    output wire [3:0]      we,
    output wire [XLEN-1:0] addr_byte,
    output wire [XLEN-1:0] wdata,
    input  wire [XLEN-1:0] dout
);

    // ==========================================
    // IF 阶段信号
    // ==========================================
    wire [XLEN-1:0] if_pc;
    wire [XLEN-1:0] if_inst;

    // ==========================================
    // IF 分支控制信号
    // ==========================================
    wire            if_predict_failed;
    wire [XLEN-1:0] if_real_next_pc;
    wire            if_stall;

    // ==========================================
    // IF_ID 流水线寄存器信号
    // ==========================================
    wire [XLEN-1:0] id_inst;
    wire [XLEN-1:0] id_pc;

    // ==========================================
    // ID 阶段信号
    // ==========================================
    wire [XLEN-1:0] id_rs1;
    wire [XLEN-1:0] id_rs2;
    wire [4:0]      id_rs1_addr;
    wire [4:0]      id_rs2_addr;
    wire [XLEN-1:0] id_imm;
    wire [4:0]      id_rd_addr;
    wire            id_rs2_or_imm_ex;
    wire            id_reg_wen_wb;
    wire            id_wen_mem;
    wire            id_ren_mem;
    wire            id_is_jalr_ex;
    wire            id_is_lui_ex;
    wire [1:0]      id_ALUop_ex;
    wire            id_is_jal_ex;
    wire            id_is_auipc_ex;
    wire [6:0]      id_funct7;
    wire [2:0]      id_funct3;
    wire            id_is_predict_jump;
    wire [1:0]      id_mem_width_mem;
    wire            id_is_u_load_mem;
    wire [XLEN-1:0] id_pc_out;

    // ==========================================
    // ID_EX 流水线寄存器信号
    // ==========================================
    wire [XLEN-1:0] ex_pc;
    wire [XLEN-1:0] ex_rs1;
    wire [XLEN-1:0] ex_rs2;
    wire [4:0]      ex_rs1_addr;
    wire [4:0]      ex_rs2_addr;
    wire [XLEN-1:0] ex_imm;
    wire [4:0]      ex_rd_addr;
    wire            ex_rs2_or_imm;
    wire            ex_reg_wen_wb;
    wire            ex_wen_mem;
    wire            ex_ren_mem;
    wire            ex_is_jalr;
    wire            ex_is_lui;
    wire            ex_is_jal;
    wire            ex_is_auipc;
    wire [1:0]      ex_ALUop_ex;
    wire [6:0]      ex_funct7;
    wire [2:0]      ex_funct3;
    wire            ex_is_predict_jump;
    wire [1:0]      ex_mem_width_mem;
    wire            ex_is_u_load_mem;

    // ==========================================
    // EX 阶段信号
    // ==========================================
    wire            ex_flush;
    wire            ex_predict_failed;
    wire [XLEN-1:0] ex_real_rs2;
    wire [XLEN-1:0] ex_alu_real_result;
    wire [XLEN-1:0] ex_real_next_pc;
    wire [4:0]      ex_rs1_addr_out;
    wire [4:0]      ex_rs2_addr_out;
    wire [4:0]      ex_rd_addr_out;
    wire            ex_reg_wen_wb_out;
    wire            ex_wen_mem_out;
    wire            ex_ren_mem_out;
    wire [1:0]      ex_mem_width_mem_out;
    wire            ex_is_u_load_mem_out;

    // ==========================================
    // EX_MEM 流水线寄存器信号
    // ==========================================
    wire [4:0]      mem_rd_addr;
    wire            mem_reg_wen_wb;
    wire            mem_wen_mem;
    wire            mem_ren_mem;
    wire [1:0]      mem_mem_width_mem;
    wire            mem_is_u_load_mem;
    wire [XLEN-1:0] mem_rs2;
    wire [XLEN-1:0] mem_alu_result;

    // ==========================================
    // MEM 阶段信号
    // ==========================================
    wire [3:0]      mem_we;
    wire [XLEN-1:0] mem_addr_byte;
    wire [XLEN-1:0] mem_wdata;
    wire [4:0]      mem_rd_addr_out;
    wire [XLEN-1:0] mem_rd;
    wire            mem_reg_wen_wb_out;
    wire            mem_wen_mem_out;
    wire            mem_ren_mem_out;

    // ==========================================
    // MEM_WB 流水线寄存器信号
    // ==========================================
    wire [XLEN-1:0] wb_rd;
    wire [4:0]      wb_rd_addr;
    wire            wb_reg_wen_wb;

    // ==========================================
    // Forward 和 Hazard 信号
    // ==========================================
    wire            stall;
    wire [1:0]      forward_a;
    wire [1:0]      forward_b;
    wire            mem_bypass;

    // ==========================================
    // WB 阶段反馈信号
    // ==========================================
    wire [XLEN-1:0] wb_rd_data;
    wire            wb_reg_wen;

    // ==========================================
    // IF 模块
    // ==========================================
    if_state #(
        .INIT_ADDR(INIT_ADDR)
    ) if_state_inst (
        .clk(clk),
        .rst_n(rst_n),
        .predict_failed(if_predict_failed),
        .real_next_pc(if_real_next_pc),
        .inst_irom(inst_in),
        .stall(if_stall),
        .pc(if_pc),
        .inst(if_inst)
    );

    // ==========================================
    // IF_ID 流水线寄存器
    // ==========================================
    if_id if_id_inst (
        .clk(clk),
        .rst_n(rst_n),
        .stall(if_stall),
        .flush(ex_flush),
        .inst_in(if_inst),
        .pc_in(if_pc),
        .inst_out(id_inst),
        .pc_out(id_pc)
    );

    // ==========================================
    // ID 模块
    // ==========================================
    id id_state_inst (
        .clk(clk),
        .rst_n(rst_n),
        .inst(id_inst),
        .pc(id_pc),
        .wb_rd(wb_rd_data),
        .wb_rd_addr(wb_rd_addr),
        .wb_reg_wen(wb_reg_wen),
        .rs1(id_rs1),
        .rs2(id_rs2),
        .rs1_addr(id_rs1_addr),
        .rs2_addr(id_rs2_addr),
        .imm(id_imm),
        .rd_addr(id_rd_addr),
        .rs2_or_imm_ex(id_rs2_or_imm_ex),
        .reg_wen_wb(id_reg_wen_wb),
        .wen_mem(id_wen_mem),
        .ren_mem(id_ren_mem),
        .is_jalr_ex(id_is_jalr_ex),
        .is_lui_ex(id_is_lui_ex),
        .ALUop_ex(id_ALUop_ex),
        .is_jal_ex(id_is_jal_ex),
        .is_auipc_ex(id_is_auipc_ex),
        .funct7(id_funct7),
        .funct3(id_funct3),
        .is_predict_jump(id_is_predict_jump),
        .pc_out(id_pc_out),
        .mem_width_mem(id_mem_width_mem),
        .is_u_load_mem(id_is_u_load_mem)
    );

    // ==========================================
    // ID_EX 流水线寄存器
    // ==========================================
    id_ex id_ex_inst (
        .clk(clk),
        .rst_n(rst_n),
        .stall(if_stall),
        .flush(ex_flush),
        .pc(id_pc_out),
        .rs1(id_rs1),
        .rs2(id_rs2),
        .rs1_addr(id_rs1_addr),
        .rs2_addr(id_rs2_addr),
        .imm(id_imm),
        .rd_addr(id_rd_addr),
        .rs2_or_imm_ex(id_rs2_or_imm_ex),
        .reg_wen_wb(id_reg_wen_wb),
        .wen_mem(id_wen_mem),
        .ren_mem(id_ren_mem),
        .is_jalr_ex(id_is_jalr_ex),
        .is_lui_ex(id_is_lui_ex),
        .ALUop_ex(id_ALUop_ex),
        .is_jal_ex(id_is_jal_ex),
        .is_auipc_ex(id_is_auipc_ex),
        .funct7(id_funct7),
        .funct3(id_funct3),
        .is_predict_jump(id_is_predict_jump),
        .mem_width_mem(id_mem_width_mem),
        .is_u_load_mem(id_is_u_load_mem),
        .pc_out(ex_pc),
        .rs1_out(ex_rs1),
        .rs2_out(ex_rs2),
        .rs1_addr_out(ex_rs1_addr),
        .rs2_addr_out(ex_rs2_addr),
        .imm_out(ex_imm),
        .rd_addr_out(ex_rd_addr),
        .rs2_or_imm_ex_out(ex_rs2_or_imm),
        .reg_wen_wb_out(ex_reg_wen_wb),
        .wen_mem_out(ex_wen_mem),
        .ren_mem_out(ex_ren_mem),
        .is_jalr_ex_out(ex_is_jalr),
        .is_lui_ex_out(ex_is_lui),
        .ALUop_ex_out(ex_ALUop_ex),
        .is_jal_ex_out(ex_is_jal),
        .is_auipc_ex_out(ex_is_auipc),
        .funct7_out(ex_funct7),
        .funct3_out(ex_funct3),
        .is_predict_jump_out(ex_is_predict_jump),
        .mem_width_mem_out(ex_mem_width_mem),
        .is_u_load_mem_out(ex_is_u_load_mem)
    );

    // ==========================================
    // EX 模块
    // ==========================================
    ex ex_inst (
        .pc(ex_pc),
        .rs1(ex_rs1),
        .rs2(ex_rs2),
        .rs1_addr(ex_rs1_addr),
        .rs2_addr(ex_rs2_addr),
        .imm(ex_imm),
        .rd_addr(ex_rd_addr),
        .ALUop(ex_ALUop_ex),
        .rs2_or_imm(ex_rs2_or_imm),
        .reg_wen_wb(ex_reg_wen_wb),
        .wen_mem(ex_wen_mem),
        .ren_mem(ex_ren_mem),
        .is_jalr(ex_is_jalr),
        .is_lui(ex_is_lui),
        .is_jal(ex_is_jal),
        .is_auipc(ex_is_auipc),
        .funct3(ex_funct3),
        .funct7(ex_funct7),
        .is_predict_jump(ex_is_predict_jump),
        .mem_width_mem(ex_mem_width_mem),
        .is_u_load_mem(ex_is_u_load_mem),
        .forward_a(forward_a),
        .forward_b(forward_b),
        .mem_rd(mem_rd),
        .wb_rd(wb_rd_data),
        .flush(ex_flush),
        .predict_failed(ex_predict_failed),
        .real_rs2(ex_real_rs2),
        .alu_real_result(ex_alu_real_result),
        .real_next_pc(ex_real_next_pc),
        .rs1_addr_out(ex_rs1_addr_out),
        .rs2_addr_out(ex_rs2_addr_out),
        .rd_addr_out(ex_rd_addr_out),
        .reg_wen_wb_out(ex_reg_wen_wb_out),
        .wen_mem_out(ex_wen_mem_out),
        .ren_mem_out(ex_ren_mem_out),
        .mem_width_mem_out(ex_mem_width_mem_out),
        .is_u_load_mem_out(ex_is_u_load_mem_out)
    );

    // ==========================================
    // EX_MEM 流水线寄存器
    // ==========================================
    ex_mem ex_mem_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rd_addr(ex_rd_addr_out),
        .reg_wen_wb(ex_reg_wen_wb_out),
        .wen_mem(ex_wen_mem_out),
        .ren_mem(ex_ren_mem_out),
        .mem_width_mem(ex_mem_width_mem_out),
        .is_u_load_mem(ex_is_u_load_mem_out),
        .rs2(ex_real_rs2),
        .alu_result(ex_alu_real_result),
        .rd_addr_out(mem_rd_addr),
        .reg_wen_wb_out(mem_reg_wen_wb),
        .wen_mem_out(mem_wen_mem),
        .ren_mem_out(mem_ren_mem),
        .mem_width_mem_out(mem_mem_width_mem),
        .is_u_load_mem_out(mem_is_u_load_mem),
        .rs2_out(mem_rs2),
        .alu_result_out(mem_alu_result)
    );

    // ==========================================
    // MEM 模块
    // ==========================================
    mem mem_inst (
        .rd_addr(mem_rd_addr),
        .reg_wen_wb(mem_reg_wen_wb),
        .wen_mem(mem_wen_mem),
        .ren_mem(mem_ren_mem),
        .mem_width(mem_mem_width_mem),
        .is_u_load_mem(mem_is_u_load_mem),
        .rs2(mem_rs2),
        .alu_result(mem_alu_result),
        .rd_wb(mem_rd),
        .mem_bypass(mem_bypass),
        .dout(dout),
        .we(mem_we),
        .addr_byte(mem_addr_byte),
        .wdata(mem_wdata),
        .rd_addr_out(mem_rd_addr_out),
        .rd(mem_rd),
        .reg_wen_wb_out(mem_reg_wen_wb_out),
        .wen_mem_out(mem_wen_mem_out),
        .ren_mem_out(mem_ren_mem_out)
    );

    // ==========================================
    // MEM_WB 流水线寄存器
    // ==========================================
    mem_wb mem_wb_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rd(mem_rd),
        .rd_addr(mem_rd_addr_out),
        .reg_wen_wb(mem_reg_wen_wb_out),
        .rd_out(wb_rd),
        .rd_addr_out(wb_rd_addr),
        .reg_wen_wb_out(wb_reg_wen_wb)
    );

    // ==========================================
    // WB 模块
    // ==========================================
    wb wb_inst (
        .rd(wb_rd),
        .rd_addr(wb_rd_addr),
        .reg_wen_wb(wb_reg_wen_wb),
        .wb_rd(wb_rd_data),
        .wb_rd_addr(),
        .wb_reg_wen(wb_reg_wen)
    );

    // ==========================================
    // Hazard 检测模块
    // ==========================================
    hazard_stall hazard_stall_inst (
        .id_rs1_addr(id_rs1_addr),
        .id_rs2_addr(id_rs2_addr),
        .id_wen_mem(id_wen_mem),
        .ex_rd_addr(ex_rd_addr_out),
        .ex_ren_mem(ex_ren_mem),
        .ex_reg_wen_wb(ex_reg_wen_wb_out),
        .stall(stall)
    );

    hazard_forward hazard_forward_inst (
        .ex_rs1_addr(ex_rs1_addr_out),
        .ex_rs2_addr(ex_rs2_addr_out),
        .ex_wen_mem(ex_wen_mem_out),
        .mem_rd_addr(mem_rd_addr_out),
        .mem_reg_wen_wb(mem_reg_wen_wb_out),
        .mem_ren_mem(mem_ren_mem_out),
        .wb_rd_addr(wb_rd_addr),
        .wb_reg_wen_wb(wb_reg_wen_wb),
        .forward_a(forward_a),
        .forward_b(forward_b),
        .mem_bypass(mem_bypass)
    );

    // ==========================================
    // stall 和 predict_failed 选择
    // ==========================================
    assign if_stall = stall;
    assign if_real_next_pc = ex_real_next_pc;
    assign if_predict_failed = ex_predict_failed;

    // ==========================================
    // DROM 接口输出
    // ==========================================
    assign we = mem_we;
    assign addr_byte = mem_addr_byte;
    assign wdata = mem_wdata;

    // ==========================================
    // PC 输出到 irom
    // ==========================================
    assign pc_out = if_pc;

endmodule
