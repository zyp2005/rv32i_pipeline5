`include "defines.v"

// ALU 模块 - 算术逻辑单元
// 支持：add, sub, xor, or, and, sll, srl, sra, slt, sltu
module alu #(
    parameter XLEN = 32
)(
    input  wire [XLEN-1:0] a,
    input  wire [XLEN-1:0] b,
    input  wire [3:0]      ALU_control,
    output reg  [XLEN-1:0] result,
    output wire            zero
);

    reg [XLEN-1:0] alu_result;

    always @(*) begin
        case (ALU_control)
            `ALU_ADD:  alu_result = a + b;
            `ALU_SUB:  alu_result = a - b;
            `ALU_AND:  alu_result = a & b;
            `ALU_OR:   alu_result = a | b;
            `ALU_XOR:  alu_result = a ^ b;
            `ALU_SLL:  alu_result = a << b[4:0];
            `ALU_SRL:  alu_result = a >> b[4:0];
            `ALU_SRA:  alu_result = $signed(a) >>> b[4:0];
            `ALU_SLT:  alu_result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
            `ALU_SLTU: alu_result = (a < b) ? 32'b1 : 32'b0;
            default:   alu_result = 32'b0;
        endcase
    end

    assign result = alu_result;
    assign zero = (alu_result == 32'b0);

endmodule
