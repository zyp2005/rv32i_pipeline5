`timescale 1ns / 1ps
`include "defines.v"

// =============================================================================
// CPU Testbench - 专门用于调试 LW 指令
// =============================================================================

module tb_cpu_lw;

    parameter CLK_PERIOD = 10;
    parameter RESET_CYCLES = 5;
    parameter CPU_RESET_ADDR = 32'h0000_1000;
    parameter DATA_ADDR = 32'h0000_0000;

    reg clk;
    reg rst_n;

    wire [31:0] irom_rdata;
    wire [31:0] irom_addr;

    wire [31:0] dout;
    wire [31:0] addr_byte;
    wire [31:0] wdata;
    wire [3:0] we;

    // CPU 实例
    cpu #(
        .XLEN(32),
        .INIT_ADDR(CPU_RESET_ADDR)
    ) cpu_inst (
        .clk(clk),
        .rst_n(rst_n),
        .pc_out(irom_addr),
        .inst_in(irom_rdata),
        .we(we),
        .addr_byte(addr_byte),
        .wdata(wdata),
        .dout(dout)
    );

    irom #(
        .XLEN(32),
        .WORD_DEPTH(1024),
        .BASE_ADDR(CPU_RESET_ADDR)
    ) u_irom (
        .addr(irom_addr),
        .rdata(irom_rdata)
    );

    drom #(
        .XLEN(32),
        .RAM_DEPTH(4096),
        .BASE_ADDR(0)
    ) u_drom (
        .addr(addr_byte),
        .wdata(wdata),
        .we(we),
        .clk(clk),
        .rst_n(rst_n),
        .rdata(dout)
    );

    // 时钟生成
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        rst_n = 1;
    end

    // 任务：打印所有寄存器
    task print_regs;
        begin
            $display("x00-07: %08h %08h %08h %08h %08h %08h %08h %08h",
                     cpu_inst.id_state_inst.regfile_inst.regs[0],
                     cpu_inst.id_state_inst.regfile_inst.regs[1],
                     cpu_inst.id_state_inst.regfile_inst.regs[2],
                     cpu_inst.id_state_inst.regfile_inst.regs[3],
                     cpu_inst.id_state_inst.regfile_inst.regs[4],
                     cpu_inst.id_state_inst.regfile_inst.regs[5],
                     cpu_inst.id_state_inst.regfile_inst.regs[6],
                     cpu_inst.id_state_inst.regfile_inst.regs[7]);
            $display("x08-15: %08h %08h %08h %08h %08h %08h %08h %08h",
                     cpu_inst.id_state_inst.regfile_inst.regs[8],
                     cpu_inst.id_state_inst.regfile_inst.regs[9],
                     cpu_inst.id_state_inst.regfile_inst.regs[10],
                     cpu_inst.id_state_inst.regfile_inst.regs[11],
                     cpu_inst.id_state_inst.regfile_inst.regs[12],
                     cpu_inst.id_state_inst.regfile_inst.regs[13],
                     cpu_inst.id_state_inst.regfile_inst.regs[14],
                     cpu_inst.id_state_inst.regfile_inst.regs[15]);
            $display("x16-23: %08h %08h %08h %08h %08h %08h %08h %08h",
                     cpu_inst.id_state_inst.regfile_inst.regs[16],
                     cpu_inst.id_state_inst.regfile_inst.regs[17],
                     cpu_inst.id_state_inst.regfile_inst.regs[18],
                     cpu_inst.id_state_inst.regfile_inst.regs[19],
                     cpu_inst.id_state_inst.regfile_inst.regs[20],
                     cpu_inst.id_state_inst.regfile_inst.regs[21],
                     cpu_inst.id_state_inst.regfile_inst.regs[22],
                     cpu_inst.id_state_inst.regfile_inst.regs[23]);
            $display("x24-31: %08h %08h %08h %08h %08h %08h %08h %08h",
                     cpu_inst.id_state_inst.regfile_inst.regs[24],
                     cpu_inst.id_state_inst.regfile_inst.regs[25],
                     cpu_inst.id_state_inst.regfile_inst.regs[26],
                     cpu_inst.id_state_inst.regfile_inst.regs[27],
                     cpu_inst.id_state_inst.regfile_inst.regs[28],
                     cpu_inst.id_state_inst.regfile_inst.regs[29],
                     cpu_inst.id_state_inst.regfile_inst.regs[30],
                     cpu_inst.id_state_inst.regfile_inst.regs[31]);
        end
    endtask

    // 任务：打印访存相关信息
    task print_mem_info;
        begin
            $display("  MEM: addr=0x%08h, we=%04b, wdata=0x%08h, dout=0x%08h",
                     addr_byte, we, wdata, dout);
        end
    endtask

    // 任务：打印流水线关键信号
    task print_pipeline;
        begin
            // EX 阶段信号
            $display("  EX:  ALU_result=0x%08h, rs2=0x%08h",
                     cpu_inst.ex_alu_real_result,
                     cpu_inst.ex_real_rs2);
            // MEM 阶段信号
            $display("  MEM: addr=0x%08h, we=%04b, ren=%b, wdata=0x%08h, rdata=0x%08h",
                     addr_byte, we, cpu_inst.mem_ren_mem, wdata, dout);
            // WB 阶段信号
            $display("  WB:  rd_data=0x%08h, rd_addr=%02d, reg_wen=%b",
                     cpu_inst.wb_rd_data,
                     cpu_inst.wb_rd_addr,
                     cpu_inst.wb_reg_wen);
        end
    endtask

    initial begin
        integer i;

        $display("========================================");
        $display("  RISC-V RV32I CPU LW Test");
        $display("========================================");

        // 先释放复位，确保存储器处于可操作状态
        rst_n = 0;
        repeat(RESET_CYCLES) @(posedge clk);
        @(negedge clk);
        rst_n = 1;

        // 加载 lw 测试文件（必须在复位释放后）
        u_irom.load_hex_file("tests/isa/rv32mi/lw_text.hex");
        u_drom.load_hex_file("tests/isa/rv32mi/lw_data.hex");

        $display("\n=== 初始数据内存状态 ===");
        $display("  数据已加载: tests/isa/rv32mi/lw_data.hex");

        $display("\n=== 开始执行 ===");

        // 运行仿真并打印每一步
        for (i = 0; i < 500; i = i + 1) begin
            @(posedge clk);
            
            $display("\n----------------------------------------");
            $display("Cycle %3d: PC=0x%08h, Inst=0x%08h", i, irom_addr, irom_rdata);
            
            // 解码指令类型
            case (irom_rdata[6:0])
                `OP_LOAD:   $display("  [OP: LOAD]");
                `OP_STORE:  $display("  [OP: STORE]");
                `OP_BRANCH: $display("  [OP: BRANCH]");
                `OP_JAL:    $display("  [OP: JAL]");
                `OP_JALR:   $display("  [OP: JALR]");
                `OP_REG:    $display("  [OP: ALU_REG]");
                `OP_IMM:    $display("  [OP: ALU_IMM]");
                `OP_LUI:    $display("  [OP: LUI]");
                `OP_AUIPC:  $display("  [OP: AUIPC]");
                default:    $display("  [OP: UNKNOWN 0x%02h]", irom_rdata[6:0]);
            endcase

            print_regs();
            print_pipeline();

            // 特别关注 gp (x3) 和 fp (x8) 的值
            if (cpu_inst.id_state_inst.regfile_inst.regs[8] == 1) begin
                $display("\n>>> TEST COMPLETED: fp=1, gp=%0d <<<", 
                         cpu_inst.id_state_inst.regfile_inst.regs[3]);
            end
        end

        $display("\n========================================");
        $display("  仿真结束");
        $display("========================================");
        $display("最终结果: fp(x8)=%0d, gp(x3)=%0d",
                 cpu_inst.id_state_inst.regfile_inst.regs[8],
                 cpu_inst.id_state_inst.regfile_inst.regs[3]);
        
        if (cpu_inst.id_state_inst.regfile_inst.regs[3] != 0)
            $display("TEST PASSED!");
        else
            $display("TEST FAILED!");

        $finish;
    end

endmodule
