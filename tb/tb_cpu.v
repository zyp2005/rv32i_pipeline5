`timescale 1ns / 1ps

// =============================================================================
// CPU Testbench - 支持批量运行 rv32mi 测试集 (Verilog-2001 版本)
// =============================================================================

module tb_cpu;

    // ============================================================
    // 参数配置
    // ============================================================
    parameter CLK_PERIOD     = 10;           // 时钟周期 (ns)
    parameter SIM_TIMEOUT    = 100000;       // 单个测试超时 (ns)
    parameter RESET_CYCLES   = 5;            // 复位持续周期数
    parameter CPU_RESET_ADDR = 32'h0000_1000; // CPU 复位地址
    parameter MAX_INST_COUNT = 10000;        // 单个测试最大指令数

    // 调试级别控制
    parameter DEBUG_LEVEL    = 1;            // 0: 关闭，1: 基本信息，2: 详细跟踪

    // 测试文件路径前缀
    parameter TEST_PATH      = "tests/isa/rv32mi/";

    // 测试总数
    parameter TEST_COUNT     = 38;

    // ============================================================
    // 测试列表 (使用宏定义)
    // ============================================================
    // 测试名称列表，每个名称最多16个字符
    reg [8*16-1:0] test_list [0:TEST_COUNT-1];

    initial begin
        test_list[0]  = "add";
        test_list[1]  = "addi";
        test_list[2]  = "sub";
        test_list[3]  = "and";
        test_list[4]  = "andi";
        test_list[5]  = "or";
        test_list[6]  = "ori";
        test_list[7]  = "xor";
        test_list[8]  = "xori";
        test_list[9]  = "sll";
        test_list[10] = "slli";
        test_list[11] = "srl";
        test_list[12] = "srli";
        test_list[13] = "sra";
        test_list[14] = "srai";
        test_list[15] = "slt";
        test_list[16] = "slti";
        test_list[17] = "sltu";
        test_list[18] = "sltiu";
        test_list[19] = "beq";
        test_list[20] = "bne";
        test_list[21] = "blt";
        test_list[22] = "bge";
        test_list[23] = "bltu";
        test_list[24] = "bgeu";
        test_list[25] = "jal";
        test_list[26] = "jalr";
        test_list[27] = "lui";
        test_list[28] = "auipc";
        test_list[29] = "lw";
        test_list[30] = "lh";
        test_list[31] = "lhu";
        test_list[32] = "lb";
        test_list[33] = "lbu";
        test_list[34] = "sw";
        test_list[35] = "sh";
        test_list[36] = "sb";
        test_list[37] = "bypass";
    end

    // ============================================================
    // 测试管理变量
    // ============================================================
    integer test_index;
    reg [8*16-1:0] current_test;
    integer test_passed_cnt;
    integer test_failed_cnt;
    integer test_timeout_cnt;

    // 单个测试状态
    reg test_completed;
    reg test_passed;
    reg test_timeout;
    integer inst_count;

    // ============================================================
    // 信号声明
    // ============================================================
    reg clk;
    reg rst_n;

    // IROM 接口
    wire [31:0] irom_rdata;
    wire [31:0] irom_addr;

    // DROM 接口
    wire [31:0] dout;
    wire [31:0] addr_byte;
    wire [31:0] wdata;
    wire [3:0]  we;

    // ============================================================
    // CPU 实例
    // ============================================================
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

    // ============================================================
    // 存储器实例
    // ============================================================
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

    // ============================================================
    // 寄存器监控
    // ============================================================
    wire [31:0] x [0:31];

    // 直接例化32个 assign 来访问寄存器
    assign x[0]  = cpu_inst.id_state_inst.regfile_inst.regs[0];
    assign x[1]  = cpu_inst.id_state_inst.regfile_inst.regs[1];
    assign x[2]  = cpu_inst.id_state_inst.regfile_inst.regs[2];
    assign x[3]  = cpu_inst.id_state_inst.regfile_inst.regs[3];
    assign x[4]  = cpu_inst.id_state_inst.regfile_inst.regs[4];
    assign x[5]  = cpu_inst.id_state_inst.regfile_inst.regs[5];
    assign x[6]  = cpu_inst.id_state_inst.regfile_inst.regs[6];
    assign x[7]  = cpu_inst.id_state_inst.regfile_inst.regs[7];
    assign x[8]  = cpu_inst.id_state_inst.regfile_inst.regs[8];
    assign x[9]  = cpu_inst.id_state_inst.regfile_inst.regs[9];
    assign x[10] = cpu_inst.id_state_inst.regfile_inst.regs[10];
    assign x[11] = cpu_inst.id_state_inst.regfile_inst.regs[11];
    assign x[12] = cpu_inst.id_state_inst.regfile_inst.regs[12];
    assign x[13] = cpu_inst.id_state_inst.regfile_inst.regs[13];
    assign x[14] = cpu_inst.id_state_inst.regfile_inst.regs[14];
    assign x[15] = cpu_inst.id_state_inst.regfile_inst.regs[15];
    assign x[16] = cpu_inst.id_state_inst.regfile_inst.regs[16];
    assign x[17] = cpu_inst.id_state_inst.regfile_inst.regs[17];
    assign x[18] = cpu_inst.id_state_inst.regfile_inst.regs[18];
    assign x[19] = cpu_inst.id_state_inst.regfile_inst.regs[19];
    assign x[20] = cpu_inst.id_state_inst.regfile_inst.regs[20];
    assign x[21] = cpu_inst.id_state_inst.regfile_inst.regs[21];
    assign x[22] = cpu_inst.id_state_inst.regfile_inst.regs[22];
    assign x[23] = cpu_inst.id_state_inst.regfile_inst.regs[23];
    assign x[24] = cpu_inst.id_state_inst.regfile_inst.regs[24];
    assign x[25] = cpu_inst.id_state_inst.regfile_inst.regs[25];
    assign x[26] = cpu_inst.id_state_inst.regfile_inst.regs[26];
    assign x[27] = cpu_inst.id_state_inst.regfile_inst.regs[27];
    assign x[28] = cpu_inst.id_state_inst.regfile_inst.regs[28];
    assign x[29] = cpu_inst.id_state_inst.regfile_inst.regs[29];
    assign x[30] = cpu_inst.id_state_inst.regfile_inst.regs[30];
    assign x[31] = cpu_inst.id_state_inst.regfile_inst.regs[31];

    // fp (x8) 别名用于测试完成检测
    wire [31:0] fp = x[8];
    wire [31:0] gp = x[3];

    // ============================================================
    // 时钟生成
    // ============================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // ============================================================
    // 主测试流程
    // ============================================================
    initial begin
        init_test_statistics();
        print_header();

        for (test_index = 0; test_index < TEST_COUNT; test_index = test_index + 1) begin
            current_test = test_list[test_index];
            run_single_test(test_index);
            #(CLK_PERIOD * 10);
        end

        print_summary();
        $finish;
    end

    // ============================================================
    // 仿真监控逻辑
    // ============================================================

    // 指令执行跟踪与计数
    always @(posedge clk) begin
        if (rst_n && !test_completed && !test_timeout) begin
            inst_count <= inst_count + 1;

            if (DEBUG_LEVEL >= 2) begin
                $display("  [%0t] Cycle #%0d: PC=0x%08h, Inst=0x%08h",
                         $time, inst_count, irom_addr, irom_rdata);
            end else if (DEBUG_LEVEL >= 1 && inst_count % 100 == 0) begin
                $display("  [INFO] %0d instructions executed...", inst_count);
            end

            if (inst_count >= MAX_INST_COUNT) begin
                test_timeout <= 1;
                $display("\n[ERROR] Test '%s' exceeded max instruction count (%0d)",
                         current_test, MAX_INST_COUNT);
            end
        end
    end

    // 测试完成检测 (fp = 1)
    always @(posedge clk) begin
        if (rst_n && !test_completed && !test_timeout) begin
            if (fp == 1) begin
                test_completed <= 1;
                test_passed <= (gp != 0);
                $display("\n[INFO] Test completed: fp=%0d, gp=%0d", fp, gp);
            end
        end
    end

    // 超时检测 (使用周期计数)
    reg [31:0] timeout_cnt;
    always @(posedge clk) begin
        if (!rst_n) begin
            timeout_cnt <= 0;
        end else if (!test_completed && !test_timeout) begin
            if (timeout_cnt >= (SIM_TIMEOUT / CLK_PERIOD)) begin
                test_timeout <= 1;
                $display("\n[ERROR] Test timed out after %0t", $time);
            end else begin
                timeout_cnt <= timeout_cnt + 1;
            end
        end
    end

    // ============================================================
    // Task 定义区
    // ============================================================

    task init_test_statistics;
        begin
            test_passed_cnt  = 0;
            test_failed_cnt  = 0;
            test_timeout_cnt = 0;
            test_index       = 0;
        end
    endtask

    task print_header;
        begin
            $display("\n========================================");
            $display("  RISC-V RV32I CPU Testbench");
            $display("========================================");
            $display("Configuration:");
            $display("  Total Tests:       %0d", TEST_COUNT);
            $display("  CPU Reset Address: 0x%08h", CPU_RESET_ADDR);
            $display("  Max Instructions:  %0d per test", MAX_INST_COUNT);
            $display("  Debug Level:       %0d", DEBUG_LEVEL);
            $display("  Test Path:         %s", TEST_PATH);
            $display("========================================\n");
        end
    endtask

    task run_single_test;
        input integer idx;
        begin
            $display("\n----------------------------------------");
            $display("Test #%0d: %s", idx + 1, test_list[idx]);
            $display("----------------------------------------");

            init_single_test_state();
            apply_reset();          // 先释放复位
            load_test_files(idx);   // 再加载数据（必须在复位后，Icarus兼容性）
            wait_test_completion();
            check_and_record_result(idx);
        end
    endtask

    task init_single_test_state;
        begin
            test_completed = 0;
            test_passed    = 0;
            test_timeout   = 0;
            inst_count     = 0;
            timeout_cnt    = 0;
        end
    endtask

    task load_test_files;
        input integer idx;
        begin
            // 拼接文件名: TEST_PATH + test_name + "_text.hex"
            case (idx)
                0:  begin u_irom.load_hex_file("tests/isa/rv32mi/add_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/add_data.hex"); end
                1:  begin u_irom.load_hex_file("tests/isa/rv32mi/addi_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/addi_data.hex"); end
                2:  begin u_irom.load_hex_file("tests/isa/rv32mi/sub_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/sub_data.hex"); end
                3:  begin u_irom.load_hex_file("tests/isa/rv32mi/and_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/and_data.hex"); end
                4:  begin u_irom.load_hex_file("tests/isa/rv32mi/andi_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/andi_data.hex"); end
                5:  begin u_irom.load_hex_file("tests/isa/rv32mi/or_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/or_data.hex"); end
                6:  begin u_irom.load_hex_file("tests/isa/rv32mi/ori_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/ori_data.hex"); end
                7:  begin u_irom.load_hex_file("tests/isa/rv32mi/xor_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/xor_data.hex"); end
                8:  begin u_irom.load_hex_file("tests/isa/rv32mi/xori_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/xori_data.hex"); end
                9:  begin u_irom.load_hex_file("tests/isa/rv32mi/sll_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/sll_data.hex"); end
                10: begin u_irom.load_hex_file("tests/isa/rv32mi/slli_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/slli_data.hex"); end
                11: begin u_irom.load_hex_file("tests/isa/rv32mi/srl_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/srl_data.hex"); end
                12: begin u_irom.load_hex_file("tests/isa/rv32mi/srli_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/srli_data.hex"); end
                13: begin u_irom.load_hex_file("tests/isa/rv32mi/sra_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/sra_data.hex"); end
                14: begin u_irom.load_hex_file("tests/isa/rv32mi/srai_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/srai_data.hex"); end
                15: begin u_irom.load_hex_file("tests/isa/rv32mi/slt_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/slt_data.hex"); end
                16: begin u_irom.load_hex_file("tests/isa/rv32mi/slti_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/slti_data.hex"); end
                17: begin u_irom.load_hex_file("tests/isa/rv32mi/sltu_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/sltu_data.hex"); end
                18: begin u_irom.load_hex_file("tests/isa/rv32mi/sltiu_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/sltiu_data.hex"); end
                19: begin u_irom.load_hex_file("tests/isa/rv32mi/beq_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/beq_data.hex"); end
                20: begin u_irom.load_hex_file("tests/isa/rv32mi/bne_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/bne_data.hex"); end
                21: begin u_irom.load_hex_file("tests/isa/rv32mi/blt_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/blt_data.hex"); end
                22: begin u_irom.load_hex_file("tests/isa/rv32mi/bge_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/bge_data.hex"); end
                23: begin u_irom.load_hex_file("tests/isa/rv32mi/bltu_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/bltu_data.hex"); end
                24: begin u_irom.load_hex_file("tests/isa/rv32mi/bgeu_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/bgeu_data.hex"); end
                25: begin u_irom.load_hex_file("tests/isa/rv32mi/jal_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/jal_data.hex"); end
                26: begin u_irom.load_hex_file("tests/isa/rv32mi/jalr_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/jalr_data.hex"); end
                27: begin u_irom.load_hex_file("tests/isa/rv32mi/lui_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/lui_data.hex"); end
                28: begin u_irom.load_hex_file("tests/isa/rv32mi/auipc_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/auipc_data.hex"); end
                29: begin u_irom.load_hex_file("tests/isa/rv32mi/lw_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/lw_data.hex"); end
                30: begin u_irom.load_hex_file("tests/isa/rv32mi/lh_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/lh_data.hex"); end
                31: begin u_irom.load_hex_file("tests/isa/rv32mi/lhu_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/lhu_data.hex"); end
                32: begin u_irom.load_hex_file("tests/isa/rv32mi/lb_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/lb_data.hex"); end
                33: begin u_irom.load_hex_file("tests/isa/rv32mi/lbu_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/lbu_data.hex"); end
                34: begin u_irom.load_hex_file("tests/isa/rv32mi/sw_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/sw_data.hex"); end
                35: begin u_irom.load_hex_file("tests/isa/rv32mi/sh_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/sh_data.hex"); end
                36: begin u_irom.load_hex_file("tests/isa/rv32mi/sb_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/sb_data.hex"); end
                37: begin u_irom.load_hex_file("tests/isa/rv32mi/bypass_text.hex");
                        u_drom.load_hex_file("tests/isa/rv32mi/bypass_data.hex"); end
                default: begin
                    $display("[ERROR] Unknown test index: %0d", idx);
                end
            endcase
        end
    endtask

    task apply_reset;
        begin
            rst_n = 0;
            repeat(RESET_CYCLES) @(posedge clk);
            @(negedge clk);
            rst_n = 1;
            $display("[INFO] Reset released, starting execution...");
            @(posedge clk);
        end
    endtask

    task wait_test_completion;
        begin
            // 等待测试完成或超时
            while (!test_completed && !test_timeout) begin
                @(posedge clk);
            end
        end
    endtask

    task check_and_record_result;
        input integer idx;
        begin
            if (test_timeout) begin
                test_timeout_cnt = test_timeout_cnt + 1;
                $display("[RESULT] TIMEOUT");
                $display("  Test:     %s", test_list[idx]);
                $display("  Reason:   Exceeded max instructions or time limit");
            end else if (test_completed) begin
                if (test_passed) begin
                    test_passed_cnt = test_passed_cnt + 1;
                    $display("[RESULT] PASSED");
                    $display("  TESTNUM:  %0d (gp/x3)", gp);
                    $display("  Instructions: %0d", inst_count);
                end else begin
                    test_failed_cnt = test_failed_cnt + 1;
                    $display("[RESULT] FAILED");
                    $display("  TESTNUM:  %0d (gp/x3, expected non-zero)", gp);
                    $display("  Instructions: %0d", inst_count);
                end
            end else begin
                test_failed_cnt = test_failed_cnt + 1;
                $display("[RESULT] FAILED");
                $display("  Test:     %s", test_list[idx]);
                $display("  Reason:   Test did not complete (fp != 1)");
            end
        end
    endtask

    task print_summary;
        begin
            $display("\n========================================");
            $display("  Test Summary");
            $display("========================================");
            $display("Total Tests:  %0d", TEST_COUNT);
            $display("  PASSED:     %0d", test_passed_cnt);
            $display("  FAILED:     %0d", test_failed_cnt);
            $display("  TIMEOUT:    %0d", test_timeout_cnt);
            $display("----------------------------------------");

            if (test_failed_cnt == 0 && test_timeout_cnt == 0) begin
                $display("*** ALL TESTS PASSED ***");
            end else begin
                $display("*** SOME TESTS FAILED ***");
                $display("  Success Rate: %0.1f%%",
                         test_passed_cnt * 100.0 / TEST_COUNT);
            end

            $display("========================================\n");
        end
    endtask

    task dump_registers;
        begin
            $display("\n========================================");
            $display("All Registers:");
            $display("========================================");
            $display("x0  (zero) = 0x%08h    x1  (ra)   = 0x%08h", x[0],  x[1]);
            $display("x2  (sp)   = 0x%08h    x3  (gp)   = 0x%08h", x[2],  x[3]);
            $display("x4  (tp)   = 0x%08h    x5  (t0)   = 0x%08h", x[4],  x[5]);
            $display("x6  (t1)   = 0x%08h    x7  (t2)   = 0x%08h", x[6],  x[7]);
            $display("x8  (s0/fp)= 0x%08h    x9  (s1)   = 0x%08h", x[8],  x[9]);
            $display("x10 (a0)   = 0x%08h    x11 (a1)   = 0x%08h", x[10], x[11]);
            $display("x12 (a2)   = 0x%08h    x13 (a3)   = 0x%08h", x[12], x[13]);
            $display("x14 (a4)   = 0x%08h    x15 (a5)   = 0x%08h", x[14], x[15]);
            $display("x16 (a6)   = 0x%08h    x17 (a7)   = 0x%08h", x[16], x[17]);
            $display("x18 (s2)   = 0x%08h    x19 (s3)   = 0x%08h", x[18], x[19]);
            $display("x20 (s4)   = 0x%08h    x21 (s5)   = 0x%08h", x[20], x[21]);
            $display("x22 (s6)   = 0x%08h    x23 (s7)   = 0x%08h", x[22], x[23]);
            $display("x24 (s8)   = 0x%08h    x25 (s9)   = 0x%08h", x[24], x[25]);
            $display("x26 (s10)  = 0x%08h    x27 (s11)  = 0x%08h", x[26], x[27]);
            $display("x28 (t3)   = 0x%08h    x29 (t4)   = 0x%08h", x[28], x[29]);
            $display("x30 (t5)   = 0x%08h    x31 (t6)   = 0x%08h", x[30], x[31]);
            $display("========================================");
        end
    endtask

endmodule
