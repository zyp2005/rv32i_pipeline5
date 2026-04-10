`include "defines.v"

// ID 模块 - 指令解码阶段
module id #(
    parameter XLEN = 32
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [XLEN-1:0] inst,
    input  wire [XLEN-1:0] pc,
    input  wire [XLEN-1:0] wb_rd,
    input  wire [4:0]      wb_rd_addr,
    input  wire        wb_reg_wen,

    output wire [XLEN-1:0] rs1,
    output wire [XLEN-1:0] rs2,
    output wire [4:0]      rs1_addr,
    output wire [4:0]      rs2_addr,
    output wire [XLEN-1:0] imm,
    output wire [4:0]      rd_addr,

    output wire        rs2_or_imm_ex,
    output wire        reg_wen_wb,
    output wire        wen_mem,
    output wire        ren_mem,
    output wire        is_jalr_ex,
    output wire        is_lui_ex,
    output wire [1:0]  ALUop_ex,
    output wire        is_jal_ex,
    output wire        is_auipc_ex,

    output wire [6:0]  funct7,
    output wire [2:0]  funct3,
    output wire        is_predict_jump,
    output wire [XLEN-1:0] pc_out,

    // Load/Store 内存访问控制
    output reg  [1:0]  mem_width_mem,     // 00=byte, 01=half, 10=word
    output reg         is_u_load_mem      // 无符号 Load (LBU, LHU)
);

    wire [6:0] opcode;
    assign opcode = inst[6:0];
    assign funct7 = inst[31:25];
    assign funct3 = inst[14:12];
    assign rd_addr = inst[11:7];

    control control_inst (
        .opcode(opcode),
        .rs2_or_imm_ex(rs2_or_imm_ex),
        .reg_wen_wb(reg_wen_wb),
        .wen_mem(wen_mem),
        .ren_mem(ren_mem),
        .is_jalr_ex(is_jalr_ex),
        .is_lui_ex(is_lui_ex),
        .ALUop_ex(ALUop_ex),
        .is_jal_ex(is_jal_ex),
        .is_auipc_ex(is_auipc_ex)
    );

    rsAddrGen rsAddrGen_inst (
        .inst(inst),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr)
    );

    immgen immgen_inst (
        .inst(inst),
        .imm(imm)
    );

    regfile regfile_inst (
        .clk(clk),
        .rst_n(rst_n),
        .reg_wen(wb_reg_wen),
        .rd(wb_rd),
        .rd_addr(wb_rd_addr),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rs1(rs1),
        .rs2(rs2)
    );

    wire is_branch;
    assign is_branch = (opcode == `OP_BRANCH);
    assign is_predict_jump = is_branch && inst[31];

    assign pc_out = pc;

    // mem_width 和 is_u_load 解析
    always @(*) begin
        // 默认值
        mem_width_mem = 2'b00;
        is_u_load_mem = 1'b0;

        if (opcode == `OP_LOAD) begin
            // Load 指令
            case (funct3)
                `FUNCT3_LB:  begin
                    mem_width_mem = `MEM_BYTE;
                    is_u_load_mem = 1'b0;
                end
                `FUNCT3_LH: begin
                    mem_width_mem = `MEM_HALF;
                    is_u_load_mem = 1'b0;
                end
                `FUNCT3_LW: begin
                    mem_width_mem = `MEM_WORD;
                    is_u_load_mem = 1'b0;
                end
                `FUNCT3_LBU: begin
                    mem_width_mem = `MEM_BYTE;
                    is_u_load_mem = 1'b1;
                end
                `FUNCT3_LHU: begin
                    mem_width_mem = `MEM_HALF;
                    is_u_load_mem = 1'b1;
                end
                default: begin
                    mem_width_mem = 2'b00;
                    is_u_load_mem = 1'b0;
                end
            endcase
        end else if (opcode == `OP_STORE) begin
            // Store 指令
            case (funct3)
                `FUNCT3_SB: mem_width_mem = `MEM_BYTE;
                `FUNCT3_SH: mem_width_mem = `MEM_HALF;
                `FUNCT3_SW: mem_width_mem = `MEM_WORD;
                default: mem_width_mem = 2'b00;
            endcase
        end
    end

endmodule
