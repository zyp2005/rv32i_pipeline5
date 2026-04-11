`timescale 1ns / 1ps

module tb_drom;

    reg clk;
    reg rst_n;
    reg [31:0] addr;
    reg [31:0] wdata;
    reg [3:0] we;
    wire [31:0] rdata;

    drom #(
        .XLEN(32),
        .RAM_DEPTH(4096),
        .BASE_ADDR(0)
    ) u_drom (
        .addr(addr),
        .wdata(wdata),
        .we(we),
        .clk(clk),
        .rst_n(rst_n),
        .rdata(rdata)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 0;
        we = 4'b0000;
        addr = 0;
        wdata = 0;

        repeat(4) @(posedge clk)
        rst_n = 1;

        $display("=== DROM Test ===");
        
        // 加载数据文件
        u_drom.load_hex_file("tests/isa/rv32mi/lw_data.hex");
        
        // 等待加载完成
        #10;
        
        $display("\n=== 测试读取 ===");
        
        // 测试地址 0x00
        addr = 32'h00000000;
        #1;
        $display("Read addr=0x%08h -> rdata=0x%08h", addr, rdata);
        
        // 测试地址 0x04
        addr = 32'h00000004;
        #1;
        $display("Read addr=0x%08h -> rdata=0x%08h", addr, rdata);
        
        // 测试地址 0x10 (关键地址)
        addr = 32'h00000010;
        #1;
        $display("Read addr=0x%08h -> rdata=0x%08h", addr, rdata);
        $display("  ram[16]=0x%02h, ram[17]=0x%02h, ram[18]=0x%02h, ram[19]=0x%02h",
                 u_drom.ram[16], u_drom.ram[17], u_drom.ram[18], u_drom.ram[19]);
        
        // 测试地址 0x14
        addr = 32'h00000014;
        #1;
        $display("Read addr=0x%08h -> rdata=0x%08h", addr, rdata);
        
        // 打印原始字节数据
        $display("\n=== 原始字节数据 (前32字节) ===");
        $display("ram[0x00]=0x%02h, ram[0x01]=0x%02h, ram[0x02]=0x%02h, ram[0x03]=0x%02h", 
                 u_drom.ram[0], u_drom.ram[1], u_drom.ram[2], u_drom.ram[3]);
        $display("ram[0x10]=0x%02h, ram[0x11]=0x%02h, ram[0x12]=0x%02h, ram[0x13]=0x%02h", 
                 u_drom.ram[16], u_drom.ram[17], u_drom.ram[18], u_drom.ram[19]);
        
        $display("\n=== 测试完成 ===");
        $finish;
    end

endmodule
