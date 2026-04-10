`include "defines.v"

// Branch 模块 - 分支判断
// 根据 ALU 结果和 funct3 判断分支是否跳转
// 检测预测是否失败，生成 flush 和 predict_failed 信号
module branch (
    input  wire [1:0]  ALUop,
    input  wire        is_predict_jump,
    input  wire [2:0]  funct3,
    input  wire [31:0] alu_result,
    input  wire        zero,
    output reg         flush,
    output reg         predict_failed
);

    reg actual_jump;

    always @(*) begin
        if (ALUop == `ALUOP_BRANCH) begin
            case (funct3)
                `FUNCT3_BEQ:  actual_jump = zero;
                `FUNCT3_BNE:  actual_jump = ~zero;
                `FUNCT3_BLT:  actual_jump = alu_result[0];
                `FUNCT3_BGE:  actual_jump = ~alu_result[0];
                `FUNCT3_BLTU: actual_jump = alu_result[0];
                `FUNCT3_BGEU: actual_jump = ~alu_result[0];
                default:      actual_jump = 1'b0;
            endcase
        end else begin
            actual_jump = 1'b0;
        end
    end

    // 使用 XOR 判断预测失败
    // predict_failed = is_predict_jump XOR actual_jump
    assign predict_failed = (ALUop == `ALUOP_BRANCH) ? (is_predict_jump ^ actual_jump) : 1'b0;
    assign flush = predict_failed;

endmodule
