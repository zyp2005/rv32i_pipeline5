`include "defines.v"

// =============================================================================
// IROM 模块 - 指令存储器
// =============================================================================
// 功能：存储指令，支持异步读取和动态加载 hex 文件
//
// 地址映射：
//   - CPU 使用字节地址 (byte address)
//   - 内部存储使用字地址 (word address)
//   - 基址：BASE_ADDR (默认 0x00001000)
//
// 小端模式：低地址存储低字节
// =============================================================================

module irom #(
    parameter XLEN = 32,
    parameter WORD_DEPTH = 1024,   // 1024 字（4KB 指令空间）
    parameter BASE_ADDR = 32'h0000_1000  // 地址基址，可自定义
)(
    input  wire [XLEN-1:0] addr,      // CPU 字节地址
    output reg  [XLEN-1:0] rdata      // 读出指令（32 位）
);

    // 存储基本单位为字 (32 位)
    reg [XLEN-1:0] rom [0:WORD_DEPTH-1];

    // 字节地址转字地址
    wire [XLEN-1:0] byte_addr;
    wire [XLEN-1:0] word_addr;
    assign byte_addr = addr - BASE_ADDR;
    assign word_addr = byte_addr >> 2;  // 字地址 = 字节地址 / 4

    // ==========================================
    // 异步读取 - 直接读取 32 位指令
    // ==========================================
    always @(*) begin
        if (addr >= BASE_ADDR && word_addr < WORD_DEPTH) begin
            rdata = rom[word_addr];
        end else begin
            rdata = `INST_NOP; // 返回 nop 指令
        end
    end

    // ==========================================
    // Task: 动态加载指令文件
    // ==========================================
    task load_hex_file;
        input [255*8-1:0] filename;  // 文件名（最大 255 字符）
        integer i;
        begin
            // 清空 ROM
            for (i = 0; i < WORD_DEPTH; i = i + 1) begin
                rom[i] = `INST_NOP;
            end
            // 加载新文件
            $readmemh(filename, rom);
            $display("[IROM] Loaded %s, depth=%0d words (base=0x%08h)", filename, WORD_DEPTH, BASE_ADDR);
        end
    endtask

    // ==========================================
    // Task: 清空指令存储器
    // ==========================================
    task clear_rom;
        integer i;
        begin
            for (i = 0; i < WORD_DEPTH; i = i + 1) begin
                rom[i] = `INST_NOP;
            end
            $display("[IROM] Cleared, filled with NOP instructions");
        end
    endtask

endmodule
