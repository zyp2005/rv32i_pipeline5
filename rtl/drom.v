`include "defines.v"

// =============================================================================
// DROM 模块 - 数据存储器
// =============================================================================
// 功能：存储数据，支持同步写入和异步读取
//
// 地址映射：
//   - CPU 使用字节地址 (byte address)
//   - 内部存储使用字节地址 (byte address)
//   - 基址：BASE_ADDR (默认 0x00001000)
//
// 写使能 we[3:0]：
//   - Load 指令：we = 4'b0000 (不写入)
//   - Store 指令：we 的每一位对应一个 byte 的写使能
//     - we[0] 控制 byte0 (最低字节)
//     - we[1] 控制 byte1
//     - we[2] 控制 byte2
//     - we[3] 控制 byte3 (最高字节)
//
// 小端模式：低地址存储低字节
// =============================================================================

module drom #(
    parameter XLEN = 32,
    parameter RAM_DEPTH = 4096,   // 4KB 数据空间（字节为单位）
    parameter BASE_ADDR = 32'h0000_1000  // 地址基址，可自定义
)(
    input  wire [XLEN-1:0] addr,      // CPU 字节地址
    input  wire [XLEN-1:0] wdata,     // 写入数据
    input  wire [3:0]      we,        // 写使能，每位控制一个 byte
    input  wire            clk,       // 时钟（同步写入用）
    input  wire            rst_n,     // 同步复位
    output reg  [XLEN-1:0] rdata      // 读出数据（异步读取）
);

    // 存储基本单位为字节
    reg [7:0] ram [0:RAM_DEPTH-1];

    // 字节地址映射（从 0 开始）
    wire [XLEN-1:0] byte_addr;
    assign byte_addr = addr - BASE_ADDR;

    // ==========================================
    // 异步读取 - 从 4 个字节组合成 32 位数据
    // ==========================================
    always @(*) begin
        if (addr >= BASE_ADDR && byte_addr < RAM_DEPTH && byte_addr[1:0] == 2'b00) begin
            // 字对齐读取，小端模式
            rdata = {ram[byte_addr+3], ram[byte_addr+2], ram[byte_addr+1], ram[byte_addr]};
        end else if (addr >= BASE_ADDR && byte_addr < RAM_DEPTH) begin
            // 非对齐读取，根据地址偏移读取
            rdata = {ram[byte_addr+3], ram[byte_addr+2], ram[byte_addr+1], ram[byte_addr]};
        end else begin
            rdata = 32'h0;  // 地址越界返回 0
        end
    end

    // ==========================================
    // 同步写入 - 根据 we 信号写入对应的 byte
    // ==========================================
    always @(posedge clk) begin
        if (!rst_n) begin
            // 复位时清空所有内存
            integer i;
            for (i = 0; i < RAM_DEPTH; i = i + 1) begin
                ram[i] <= 8'h00;
            end
        end else if (we != 4'b0000 && addr >= BASE_ADDR && byte_addr < RAM_DEPTH) begin
            // 根据 we 信号写入对应的 byte
            if (we[0]) ram[byte_addr]     <= wdata[7:0];
            if (we[1]) ram[byte_addr+1]   <= wdata[15:8];
            if (we[2]) ram[byte_addr+2]   <= wdata[23:16];
            if (we[3]) ram[byte_addr+3]   <= wdata[31:24];
        end
    end

    // ==========================================
    // Task: 动态加载数据文件
    // ==========================================
    task load_hex_file;
        input [255*8-1:0] filename;  // 文件名（最大 255 字符）
        integer i;
        begin
            // 清空 RAM
            for (i = 0; i < RAM_DEPTH; i = i + 1) begin
                ram[i] = 8'h00;
            end
            // 加载新文件
            $readmemh(filename, ram);
            $display("[DROM] Loaded %s, depth=%0d bytes (base=0x%08h)", filename, RAM_DEPTH, BASE_ADDR);
        end
    endtask

    // ==========================================
    // Task: 清空数据存储器
    // ==========================================
    task clear_ram;
        integer i;
        begin
            for (i = 0; i < RAM_DEPTH; i = i + 1) begin
                ram[i] = 8'h00;
            end
            $display("[DROM] Cleared, filled with zeros");
        end
    endtask

endmodule
