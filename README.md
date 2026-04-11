# RISC-V RV32I 5级流水线 CPU

一个完整的 RISC-V RV32I 基础整数指令集处理器实现，采用经典的 5 级流水线架构。

## 特性

- **5级流水线**: IF → ID → EX → MEM → WB
- **完整 RV32I 支持**: 支持全部 38 个基础整数指令测试用例
- **分支预测**: 实现 BTFNT (Backward Taken, Forward Not Taken) 静态预测
- **数据冒险处理**: 
  - 数据前递 (Forwarding) 减少流水线停顿
  - Load-use 冒险检测与流水线停顿
- **测试覆盖**: 算术运算、分支跳转、Load/Store、数据冒险等

## 目录结构

```
├── rtl/           # RTL 硬件设计代码
│   ├── cpu.v          # CPU 顶层模块
│   ├── defines.v      # 指令集宏定义
│   ├── if_state.v     # IF 取指阶段
│   ├── id.v           # ID 译码阶段
│   ├── ex.v           # EX 执行阶段
│   ├── mem.v          # MEM 访存阶段
│   ├── wb.v           # WB 写回阶段
│   ├── hazard_*.v     # 冒险检测模块
│   └── ...
├── tb/            # 测试平台
│   ├── tb_cpu.v       # 批量测试平台 (38个测试用例)
│   ├── tb_cpu_lw.v    # LW指令调试平台
│   └── tb_cpu_simple.v # 单测试调试平台
├── tests/         # 测试程序
│   └── isa/rv32mi/    # RISC-V测试用例 (hex格式)
├── sim/           # 仿真输出目录
├── temp/          # 测试结果目录
├── Makefile       # 编译脚本
└── README.md      # 本文件
```

## 快速开始

### 环境要求

- [Icarus Verilog](http://iverilog.icarus.com/) (>= 10.0)
- GNU Make

### 编译运行

```bash
# 编译所有 testbench
make

# 运行批量测试 (38个测试用例)
make run_full

# 运行单测试调试 (默认 add 测试)
make run_simple

# 运行 LW 指令专项测试
make run_lw

# 清理仿真文件
make clean

# 清理测试结果
make clean_temp
```

### 测试结果

运行 `make run_full` 后，查看 `temp/` 目录下的输出文件：

```
========================================
  Test Summary
========================================
Total Tests:  38
  PASSED:     38
  FAILED:     0
  TIMEOUT:    0
----------------------------------------
*** ALL TESTS PASSED ***
========================================
```

## 支持的指令

### 算术逻辑指令
- `add`, `addi`, `sub`
- `and`, `andi`, `or`, `ori`, `xor`, `xori`
- `sll`, `slli`, `srl`, `srli`, `sra`, `srai`
- `slt`, `slti`, `sltu`, `sltiu`

### 分支指令
- `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`

### 跳转指令
- `jal`, `jalr`

### 访存指令
- `lw`, `lh`, `lhu`, `lb`, `lbu`
- `sw`, `sh`, `sb`

### 其他
- `lui`, `auipc`

## 架构细节

### 流水线阶段

1. **IF (取指)**: 从指令存储器取指，PC更新，分支预测
2. **ID (译码)**: 指令译码，寄存器读取，立即数生成
3. **EX (执行)**: ALU运算，分支判断，地址计算
4. **MEM (访存)**: 数据存储器读写
5. **WB (写回)**: 结果写回寄存器堆

### 分支预测

采用 **BTFNT** (Backward Taken, Forward Not Taken) 静态预测策略：
- 向后跳转 (偏移为负): 预测跳转
- 向前跳转 (偏移为正): 预测不跳转

### 数据冒险处理

- **EX→EX 前递**: ALU结果直接前递到下一指令
- **MEM→EX 前递**: Load结果前递
- **Load-use 停顿**: 检测到 Load→ALU 数据依赖时插入气泡

## 开发历史

### 已修复问题

1. **分支预测失败修正**: EX阶段根据实际跳转结果修正 PC
2. **数据内存加载**: 修复 Icarus Verilog 兼容性，`$readmemh` 需在复位释放后执行
3. **Testbench 复位逻辑**: 修正 stall 和 flush 信号处理

## 许可证

MIT License

## 致谢

- 测试用例基于 RISC-V 官方测试框架
