`include "defines.v"

// 寄存器地址生成模块
// 根据opcode判断是否需要rs1/rs2，不需要时输出0
module rsAddrGen #(
    parameter XLEN = 32
)(
    input  wire [XLEN-1:0] inst,
    output reg  [4:0]      rs1_addr,
    output reg  [4:0]      rs2_addr
);

    wire [6:0] opcode;
    assign opcode = inst[6:0];

    always @(*) begin
        case (opcode)
            `OP_IMM: begin
                // I-type算术：需要rs1，不需要rs2
                rs1_addr = inst[19:15];
                rs2_addr = 5'b0;
            end

            `OP_REG: begin
                // R-type：需要rs1和rs2
                rs1_addr = inst[19:15];
                rs2_addr = inst[24:20];
            end

            `OP_LOAD: begin
                // Load：需要rs1（基地址），不需要rs2
                rs1_addr = inst[19:15];
                rs2_addr = 5'b0;
            end

            `OP_STORE: begin
                // Store：需要rs1（基地址）和rs2（存储数据）
                rs1_addr = inst[19:15];
                rs2_addr = inst[24:20];
            end

            `OP_BRANCH: begin
                // 分支：需要rs1和rs2
                rs1_addr = inst[19:15];
                rs2_addr = inst[24:20];
            end

            `OP_JALR: begin
                // JALR：需要rs1（跳转基地址），不需要rs2
                rs1_addr = inst[19:15];
                rs2_addr = 5'b0;
            end

            default: begin
                // LUI, AUIPC, JAL等：不需要rs1和rs2
                rs1_addr = 5'b0;
                rs2_addr = 5'b0;
            end
        endcase
    end

endmodule
