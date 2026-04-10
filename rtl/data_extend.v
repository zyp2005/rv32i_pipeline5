`include "defines.v"

// =============================================================================
// Data Extend 模块 - 数据扩展
// =============================================================================
// 功能：根据 mem_width 和 byte_offset 对 Load 数据进行符号/零扩展
//
// 扩展规则：
//   LB (mem_width=00): 根据 offset 选择 byte，符号/零扩展到 32 位
//     - offset=00: dout[7:0]   → 扩展到 [31:0]
//     - offset=01: dout[15:8]  → 扩展到 [31:0]
//     - offset=10: dout[23:16] → 扩展到 [31:0]
//     - offset=11: dout[31:24] → 扩展到 [31:0]
//
//   LH (mem_width=01): 根据 offset 选择 half，符号/零扩展到 32 位
//     - offset=00/01: dout[15:0]  → 扩展到 [31:0]
//     - offset=10/11: dout[31:16] → 扩展到 [31:0]
//
//   LW (mem_width=10): 直接输出 dout[31:0]
//
//   is_u_load=1: 零扩展
//   is_u_load=0: 符号扩展
// =============================================================================

module data_extend #(
    parameter XLEN = 32
)(
    input  wire [1:0]      mem_width,     // 内存访问宽度
    input  wire            is_u_load_mem, // 无符号 Load 标志
    input  wire [1:0]      byte_offset,   // 字节偏移 (alu_result[1:0])
    input  wire [XLEN-1:0] dout,          // DROM 输出
    output reg  [XLEN-1:0] extended_data  // 扩展后的数据
);

    reg [7:0]  selected_byte;
    reg [15:0] selected_half;

    // 根据 mem_width 和 byte_offset 选择数据
    always @(*) begin
        case (mem_width)
            `MEM_BYTE: begin
                // LB: 根据 offset 选择 byte
                case (byte_offset)
                    2'b00: selected_byte = dout[7:0];
                    2'b01: selected_byte = dout[15:8];
                    2'b10: selected_byte = dout[23:16];
                    2'b11: selected_byte = dout[31:24];
                    default: selected_byte = 8'h0;
                endcase

                // 符号扩展或零扩展
                if (is_u_load_mem)
                    extended_data = {24'h00, selected_byte};  // LBU: 零扩展
                else
                    extended_data = {{24{selected_byte[7]}}, selected_byte};  // LB: 符号扩展
            end

            `MEM_HALF: begin
                // LH: 根据 offset 选择 half
                if (byte_offset[1] == 1'b0) begin
                    // offset=00/01: 选择低 16 位
                    selected_half = dout[15:0];
                end else begin
                    // offset=10/11: 选择高 16 位
                    selected_half = dout[31:16];
                end

                // 符号扩展或零扩展
                if (is_u_load_mem)
                    extended_data = {16'h0000, selected_half};  // LHU: 零扩展
                else
                    extended_data = {{16{selected_half[15]}}, selected_half};  // LH: 符号扩展
            end

            `MEM_WORD: begin
                // LW: 直接输出 32 位
                extended_data = dout;
            end

            default: begin
                extended_data = 32'h0;
            end
        endcase
    end

endmodule
