`include "defines.v"

// =============================================================================
// Shift Left 模块 - 左移器
// =============================================================================
// 功能：根据 shift_control 将数据左移，用于 Store 指令的数据对齐
//
// 移位控制：
//   - shift=0:  不移动，输出 data[31:0]
//   - shift=8:  左移 8 位，输出 {data[23:0], 8'b0}
//   - shift=16: 左移 16 位，输出 {data[15:0], 16'b0}
//   - shift=24: 左移 24 位，输出 {data[7:0], 24'b0}
// =============================================================================

module shift_left #(
    parameter XLEN = 32
)(
    input  wire [XLEN-1:0] data,         // 输入数据 (rs2)
    input  wire [4:0]      shift_control,// 移位控制 (0, 8, 16, 24)
    output reg  [XLEN-1:0] shifted_data  // 移位后输出
);

    always @(*) begin
        case (shift_control)
            5'd24: shifted_data = {data[7:0],   24'h000000};  // 左移 24 位
            5'd16: shifted_data = {data[15:0],  16'h0000};    // 左移 16 位
            5'd8:  shifted_data = {data[23:0],  8'h00};       // 左移 8 位
            5'd0:  shifted_data = data;                       // 不移位
            default: shifted_data = data;
        endcase
    end

endmodule
