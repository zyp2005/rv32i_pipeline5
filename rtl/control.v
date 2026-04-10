`include "defines.v"

// 控制模块
// 根据 opcode 生成控制信号
module control #(
    parameter XLEN = 32
)(
    input  wire [6:0] opcode,
    // EX 阶段控制信号
    output reg        rs2_or_imm_ex,  // ALU 第二操作数选择：0=rs2, 1=imm
    output reg        is_jalr_ex,     // JALR 指令标志
    output reg        is_lui_ex,      // LUI 指令标志
    output reg [1:0]  ALUop_ex,       // ALU 操作码
    output reg        is_jal_ex,      // JAL 指令标志
    output reg        is_auipc_ex,    // AUIPC 指令标志
    // MEM 阶段控制信号
    output reg        wen_mem,        // 内存写使能
    output reg        ren_mem,        // 内存读使能
    // WB 阶段控制信号
    output reg        reg_wen_wb      // 寄存器写使能
);

    always @(*) begin
        // 默认值
        rs2_or_imm_ex = 1'b0;
        reg_wen_wb    = 1'b0;
        wen_mem       = 1'b0;
        ren_mem       = 1'b0;
        is_jalr_ex    = 1'b0;
        is_lui_ex     = 1'b0;
        ALUop_ex      = `ALUOP_ARITH;
        is_jal_ex     = 1'b0;
        is_auipc_ex   = 1'b0;

        case (opcode)
            `OP_IMM: begin
                // I 型算术指令：rd = rs1 op imm
                reg_wen_wb    = 1'b1;
                rs2_or_imm_ex = 1'b1;
                ALUop_ex      = `ALUOP_ARITH;
            end

            `OP_REG: begin
                // R 型指令：rd = rs1 op rs2
                reg_wen_wb    = 1'b1;
                rs2_or_imm_ex = 1'b0;
                ALUop_ex      = `ALUOP_ARITH;
            end

            `OP_BRANCH: begin
                // 分支指令：比较 rs1 和 rs2
                rs2_or_imm_ex = 1'b0;
                ALUop_ex      = `ALUOP_BRANCH;
            end

            `OP_LOAD: begin
                // Load 指令：rd = mem[rs1 + imm]
                reg_wen_wb    = 1'b1;
                ren_mem       = 1'b1;
                rs2_or_imm_ex = 1'b1;
                ALUop_ex      = `ALUOP_MEM;
            end

            `OP_STORE: begin
                // Store 指令：mem[rs1 + imm] = rs2
                wen_mem       = 1'b1;
                rs2_or_imm_ex = 1'b1;
                ALUop_ex      = `ALUOP_MEM;
            end

            `OP_JAL: begin
                // JAL 指令：ra = pc+4, pc = pc+imm
                reg_wen_wb    = 1'b1;
                ALUop_ex      = `ALUOP_JUMP;
                is_jal_ex     = 1'b1;
            end

            `OP_JALR: begin
                // JALR 指令：ra = pc+4, pc = rs1+imm
                reg_wen_wb    = 1'b1;
                is_jalr_ex    = 1'b1;
                rs2_or_imm_ex = 1'b1;
                ALUop_ex      = `ALUOP_JUMP;
            end

            `OP_LUI: begin
                // LUI 指令：rd = imm[31:12] << 12
                reg_wen_wb    = 1'b1;
                is_lui_ex     = 1'b1;
                ALUop_ex      = `ALUOP_JUMP;
            end

            `OP_AUIPC: begin
                // AUIPC 指令：rd = pc + imm[31:12] << 12
                reg_wen_wb    = 1'b1;
                rs2_or_imm_ex = 1'b1;
                ALUop_ex      = `ALUOP_JUMP;
                is_auipc_ex   = 1'b1;
            end

            default: begin
            end
        endcase
    end

endmodule
