`include "defines.v"

// NPC 模块 - Next PC 计算
// 根据指令类型计算下一条指令地址
module npc (
    input  wire [31:0] inst,
    input  wire [31:0] pc,
    output wire [31:0] next_pc
);

    wire [6:0] opcode;
    wire [31:0] imm_jal;
    wire [31:0] imm_branch;

    assign opcode = inst[6:0];

    // JAL 立即数解析 (J-type)
    assign imm_jal = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

    // B 型立即数解析 (B-type)
    assign imm_branch = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};

    reg [31:0] next_pc_reg;

    always @(*) begin
        case (opcode)
            `OP_JAL: begin
                // JAL: pc + imm
                next_pc_reg = pc + imm_jal;
            end

            `OP_JALR: begin
                // JALR: pc + 4
                next_pc_reg = pc + 32'd4;
            end

            `OP_BRANCH: begin
                // B 型分支：静态 BTFNT 预测
                // inst[31]=1 (负偏移): 预测跳转 (backward)
                // inst[31]=0 (正偏移): 预测不跳转 (forward)
                if (inst[31] == 1'b1) begin
                    next_pc_reg = pc + imm_branch;
                end else begin
                    next_pc_reg = pc + 32'd4;
                end
            end

            default: begin
                // 非分支指令：pc + 4
                next_pc_reg = pc + 32'd4;
            end
        endcase
    end

    assign next_pc = next_pc_reg;

endmodule
