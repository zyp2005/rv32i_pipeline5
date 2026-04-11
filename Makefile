# RISC-V RV32I 5级流水线CPU仿真Makefile

# 配置
IVERILOG := iverilog
VVP := vvp
GTKWAVE := gtkwave

# 目录
RTL_DIR := rtl
TB_DIR := tb
SIM_DIR := sim
TESTS_DIR := tests/isa/rv32mi

# 创建sim目录
$(shell mkdir -p $(SIM_DIR))

# RTL源文件列表
RTL_SRCS := $(RTL_DIR)/defines.v \
            $(RTL_DIR)/regfile.v \
            $(RTL_DIR)/alu.v \
            $(RTL_DIR)/alu_control.v \
            $(RTL_DIR)/branch.v \
            $(RTL_DIR)/control.v \
            $(RTL_DIR)/data_extend.v \
            $(RTL_DIR)/drom_control.v \
            $(RTL_DIR)/drom.v \
            $(RTL_DIR)/ex_mem.v \
            $(RTL_DIR)/ex.v \
            $(RTL_DIR)/hazard_forward.v \
            $(RTL_DIR)/hazard_stall.v \
            $(RTL_DIR)/id_ex.v \
            $(RTL_DIR)/id.v \
            $(RTL_DIR)/if_id.v \
            $(RTL_DIR)/if_state.v \
            $(RTL_DIR)/immgen.v \
            $(RTL_DIR)/irom.v \
            $(RTL_DIR)/mem.v \
            $(RTL_DIR)/mem_wb.v \
            $(RTL_DIR)/npc.v \
            $(RTL_DIR)/pc_reg.v \
            $(RTL_DIR)/rsAddrGen.v \
            $(RTL_DIR)/shift_left.v \
            $(RTL_DIR)/wb.v \
            $(RTL_DIR)/cpu.v

# Testbench
TB_SIMPLE := $(TB_DIR)/tb_cpu_simple.v
TB_FULL := $(TB_DIR)/tb_cpu.v

# 编译输出
VVP_SIMPLE := $(SIM_DIR)/tb_cpu_simple.vvp
VVP_FULL := $(SIM_DIR)/tb_cpu.vvp

# Iverilog编译选项
IVERILOG_FLAGS := -g2012 -I $(RTL_DIR)

# 默认目标
.PHONY: all clean run_simple run_full wave list_tests

all: $(VVP_SIMPLE) $(VVP_FULL)

# 编译simple testbench
$(VVP_SIMPLE): $(RTL_SRCS) $(TB_SIMPLE)
	@echo "=== 编译 tb_cpu_simple ==="
	$(IVERILOG) $(IVERILOG_FLAGS) -o $@ $(RTL_SRCS) $(TB_SIMPLE)
	@echo "编译完成: $@"

# 编译full testbench
$(VVP_FULL): $(RTL_SRCS) $(TB_FULL)
	@echo "=== 编译 tb_cpu ==="
	$(IVERILOG) $(IVERILOG_FLAGS) -o $@ $(RTL_SRCS) $(TB_FULL)
	@echo "编译完成: $@"

# 运行simple仿真（默认运行add测试）
run_simple: $(VVP_SIMPLE)
	@echo "=== 运行 tb_cpu_simple 仿真 ==="
	@mkdir -p temp
	@OUTFILE=$$(ls temp/temp*.txt 2>/dev/null | sort -V | tail -1 | sed 's/temp\/temp//;s/\.txt//' || echo -1); \
	NEXT=$$(($$OUTFILE + 1)); \
	$(VVP) $(VVP_SIMPLE) > temp/temp$$NEXT.txt 2>&1; \
	echo "仿真输出已保存到: temp/temp$$NEXT.txt"

# 运行full仿真
run_full: $(VVP_FULL)
	@echo "=== 运行 tb_cpu 仿真 ==="
	@mkdir -p temp
	@OUTFILE=$$(ls temp/temp*.txt 2>/dev/null | sort -V | tail -1 | sed 's/temp\/temp//;s/\.txt//' || echo -1); \
	NEXT=$$(($$OUTFILE + 1)); \
	$(VVP) $(VVP_FULL) > temp/temp$$NEXT.txt 2>&1; \
	echo "仿真输出已保存到: temp/temp$$NEXT.txt"

# 列出可用测试
list_tests:
	@echo "=== 可用测试程序 ==="
	@ls $(TESTS_DIR)/*_text.hex | sed 's|$(TESTS_DIR)/||g' | sed 's|_text.hex||g'

# 清理仿真文件
clean:
	@echo "=== 清理仿真文件 ==="
	rm -rf $(SIM_DIR)/*.vvp $(SIM_DIR)/*.vcd
	@echo "清理完成"

# 清理临时输出文件
clean_temp:
	@echo "=== 清理临时输出文件 ==="
	rm -rf temp/
	@echo "临时文件清理完成"

# 帮助
help:
	@echo "RISC-V RV32I CPU 仿真 Makefile"
	@echo ""
	@echo "可用目标:"
	@echo "  make              - 编译所有testbench"
	@echo "  make run_simple   - 编译并运行tb_cpu_simple仿真"
	@echo "  make run_full     - 编译并运行tb_cpu仿真"
	@echo "  make list_tests   - 列出可用的测试程序"
	@echo "  make clean        - 清理仿真文件(vvp/vcd)"
	@echo "  make clean_temp   - 清理临时输出文件(temp/*.txt)"
	@echo "  make help         - 显示此帮助"
