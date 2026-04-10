`include "defines.v"

// 立即数生成模块
// 根据opcode解析不同类型的立即数，统一采用符号扩展
module immgen #(
    parameter XLEN = 32
)(
    input  wire [XLEN-1:0] inst,
    output reg  [XLEN-1:0] imm
);

    wire [6:0] opcode;
    assign opcode = inst[6:0];

    // I-type立即数 (OP_IMM, LOAD, JALR)
    wire [XLEN-1:0] imm_i;
    assign imm_i = {{21{inst[31]}}, inst[30:20]};

    // S-type立即数 (STORE)
    wire [XLEN-1:0] imm_s;
    assign imm_s = {{21{inst[31]}}, inst[30:25], inst[11:7]};

    // B-type立即数 (BRANCH)
    wire [XLEN-1:0] imm_b;
    assign imm_b = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};

    // U-type立即数 (LUI, AUIPC)
    wire [XLEN-1:0] imm_u;
    assign imm_u = {inst[31:12], 12'b0};

    // J-type立即数 (JAL)
    wire [XLEN-1:0] imm_j;
    assign imm_j = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

    // 使用case选择立即数类型
    always @(*) begin
        case (opcode)
            `OP_IMM, `OP_LOAD, `OP_JALR: imm = imm_i;
            `OP_STORE:                   imm = imm_s;
            `OP_BRANCH:                  imm = imm_b;
            `OP_LUI, `OP_AUIPC:          imm = imm_u;
            `OP_JAL:                     imm = imm_j;
            default:                     imm = 32'h0;
        endcase
    end

endmodule
