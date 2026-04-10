`include "defines.v"

// =============================================================================
// DROM Control 模块 - 数据存储器控制
// =============================================================================
// 功能：根据 wen_mem、mem_width 和 offset 生成 we（写使能）和 shift_control（移位控制）
//
// SB (mem_width=00):
//   - offset=00: we=0001, shift=0   (写入 byte0)
//   - offset=01: we=0010, shift=8   (写入 byte1)
//   - offset=10: we=0100, shift=16  (写入 byte2)
//   - offset=11: we=1000, shift=24  (写入 byte3)
//
// SH (mem_width=01):
//   - offset=00/01: we=0011, shift=0    (写入低 16 位)
//   - offset=10/11: we=1100, shift=16   (写入高 16 位)
//
// SW (mem_width=10):
//   - we=1111, shift=0  (写入全部 32 位)
//
// Load 指令 (wen_mem=0): we=0000, shift=0
// =============================================================================

module drom_control (
    input  wire        wen_mem,        // 内存写使能
    input  wire [1:0]  mem_width,      // 内存访问宽度
    input  wire [1:0]  offset,         // 字节偏移 (alu_result[1:0])
    output reg  [3:0]  we,             // 写使能，每位控制一个 byte
    output reg  [4:0]  shift_control   // 移位控制 (0, 8, 16, 24)
);

    always @(*) begin
        if (!wen_mem) begin
            // Load 指令：不写入
            we = 4'b0000;
            shift_control = 5'd0;
        end else begin
            // Store 指令：根据 mem_width 和 offset 生成 we 和 shift
            case (mem_width)
                `MEM_BYTE: begin
                    // SB: 写入单个 byte
                    case (offset)
                        2'b00: begin
                            we = 4'b0001;  // 写入 byte0
                            shift_control = 5'd0;
                        end
                        2'b01: begin
                            we = 4'b0010;  // 写入 byte1
                            shift_control = 5'd8;
                        end
                        2'b10: begin
                            we = 4'b0100;  // 写入 byte2
                            shift_control = 5'd16;
                        end
                        2'b11: begin
                            we = 4'b1000;  // 写入 byte3
                            shift_control = 5'd24;
                        end
                        default: begin
                            we = 4'b0000;
                            shift_control = 5'd0;
                        end
                    endcase
                end

                `MEM_HALF: begin
                    // SH: 写入 16 位半字
                    if (offset[1] == 1'b0) begin
                        // offset=00/01: 写入低 16 位
                        we = 4'b0011;
                        shift_control = 5'd0;
                    end else begin
                        // offset=10/11: 写入高 16 位
                        we = 4'b1100;
                        shift_control = 5'd16;
                    end
                end

                `MEM_WORD: begin
                    // SW: 写入全部 32 位
                    we = 4'b1111;
                    shift_control = 5'd0;
                end

                default: begin
                    we = 4'b0000;
                    shift_control = 5'd0;
                end
            endcase
        end
    end

endmodule
