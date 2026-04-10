`include "defines.v"

// ALU 控制模块
// 根据 ALUop、funct3、funct7 生成具体的 ALU 控制信号
module alu_control (
    input  wire [1:0]  ALUop,
    input  wire [31:0] imm,
    input  wire [6:0]  funct7,
    input  wire [2:0]  funct3,
    output reg  [3:0]  ALU_control
);

    always @(*) begin
        case (ALUop)
            `ALUOP_ARITH: begin
                case (funct3)
                    `FUNCT3_ADDAUB: begin
                        if (funct7 == `FUNCT7_SUB)
                            ALU_control = `ALU_SUB;
                        else
                            ALU_control = `ALU_ADD;
                    end
                    `FUNCT3_SLL:  ALU_control = `ALU_SLL;
                    `FUNCT3_SLT:  ALU_control = `ALU_SLT;
                    `FUNCT3_SLTU: ALU_control = `ALU_SLTU;
                    `FUNCT3_XOR:  ALU_control = `ALU_XOR;
                    `FUNCT3_SR: begin
                        // 对于立即数移位 (I-type), 检查 imm[11:5]
                        // 对于寄存器移位 (R-type), 检查 funct7
                        if (imm[11:5] == `FUNCT7_SRA || funct7 == `FUNCT7_SRA)
                            ALU_control = `ALU_SRA;
                        else
                            ALU_control = `ALU_SRL;
                    end
                    `FUNCT3_OR:   ALU_control = `ALU_OR;
                    `FUNCT3_AND:  ALU_control = `ALU_AND;
                    default:      ALU_control = `ALU_ADD;
                endcase
            end
            `ALUOP_BRANCH: begin
                case (funct3)
                    `FUNCT3_BEQ, `FUNCT3_BNE: ALU_control = `ALU_SUB;
                    `FUNCT3_BLT, `FUNCT3_BGE: ALU_control = `ALU_SLT;
                    `FUNCT3_BLTU, `FUNCT3_BGEU: ALU_control = `ALU_SLTU;
                    default: ALU_control = `ALU_SUB;
                endcase
            end
            `ALUOP_MEM: begin
                ALU_control = `ALU_ADD;
            end
            `ALUOP_JUMP: begin
                ALU_control = `ALU_ADD;
            end
            default: begin
                ALU_control = `ALU_ADD;
            end
        endcase
    end

endmodule
