`include "defines.v"

// =============================================================================
// Hazard Forward 检测模块
// =============================================================================
// 功能：检测数据转发条件，在 EX 阶段选择正确的数据源
//
// P/C/D 理论框架：
// -----------------------------------------------------------------------------
// | 维度 | 含义              | 流水线对应        | 关键取值            |
// |------|-------------------|-------------------|---------------------|
// | P    | Production(产生)  | Load=MEM, ALU=EX  | mem_ren_mem 标志 P=MEM|
// | C    | Consumption(消费) | ALU=EX, Store=MEM | ex_wen_mem 标志 C=MEM|
// | D    | Distance(距离)    | D=0=前指令，D=1=前前指令 | 寄存器地址匹配判断 |
// -----------------------------------------------------------------------------
//
// Forward 条件：P<=C 或 D>=1
//   - P<=C：数据产生时间早于或等于消费时间，数据已可用
//   - D>=1：指令间隔>=1，数据已写入寄存器或正在写入
//
// 数据源选择优先级：D=0 (MEM 阶段) > D=1 (WB 阶段) > 寄存器堆
//   - forward=2'b10: 从 MEM 阶段转发 (前一条指令的 ALU/Load 结果)
//   - forward=2'b01: 从 WB 阶段转发 (前前条指令的写回数据)
//   - forward=2'b00: 从寄存器堆读取 (无冒险或数据已写回)
//
// 特殊旁路 (mem_bypass)：
//   - 场景：Load -> Store (Load 的数据直接传给 Store 写入内存)
//   - 条件：P=MEM, C=MEM, D=0
//   - 时机：Load 在 MEM 结束，Store 在 MEM 阶段使用数据
//
// 端口说明：
//   - ex_* : 当前指令 (Consumer)，在 EX 阶段执行
//   - mem_*: 前一条指令 (Producer, D=0)，在 MEM 阶段
//   - wb_* : 前前条指令 (Producer, D=1)，在 WB 阶段
// =============================================================================

module hazard_forward (
    // 当前指令 (Consumer) 的源寄存器地址
    input wire [4:0] ex_rs1_addr,   // rs1 地址
    input wire [4:0] ex_rs2_addr,   // rs2 地址
    input wire       ex_wen_mem,    // C=MEM 标志，1=Store(rs2 在 MEM 使用)

    // 前一条指令 (Producer, D=0 来源)
    input wire [4:0] mem_rd_addr,   // 目的寄存器地址，用于 D=0 检测
    input wire       mem_reg_wen_wb,// 写回使能，确认会产生数据
    input wire       mem_ren_mem,   // P=MEM 标志，1=Load(数据在 MEM 结束可用)

    // 前前条指令 (Producer, D=1 来源)
    input wire [4:0] wb_rd_addr,    // 目的寄存器地址，用于 D=1 检测
    input wire       wb_reg_wen_wb, // 写回使能

    // Forward 控制输出
    output wire [1:0] forward_a,    // rs1 数据源选择：00=RF, 10=MEM, 01=WB
    output wire [1:0] forward_b,    // rs2 数据源选择：00=RF, 10=MEM, 01=WB
    output wire       mem_bypass    // Load->Store 旁路，1=从 MEM 输出直接旁路
);

    // P/C 解码
    wire p_mem = mem_ren_mem;       // P=MEM：前一条是 Load，数据在 MEM 结束可用
    wire c_mem = ex_wen_mem;        // C=MEM：当前是 Store，rs2 在 MEM 阶段使用

    // D=0 检测：前一条指令 (MEM 阶段) 的目的寄存器与当前指令源匹配
    // 优先级最高，因为 MEM 阶段的数据比 WB 阶段更新
    wire d0_rs1 = mem_reg_wen_wb && (mem_rd_addr == ex_rs1_addr) && (mem_rd_addr != 5'b0);
    wire d0_rs2 = mem_reg_wen_wb && (mem_rd_addr == ex_rs2_addr) && (mem_rd_addr != 5'b0);

    // D=1 检测：前前条指令 (WB 阶段) 的目的寄存器与当前指令源匹配
    // 只在 D=0 不匹配时考虑，避免冲突
    wire d1_rs1 = wb_reg_wen_wb && (wb_rd_addr == ex_rs1_addr) && (wb_rd_addr != 5'b0) && !d0_rs1;
    wire d1_rs2 = wb_reg_wen_wb && (wb_rd_addr == ex_rs2_addr) && (wb_rd_addr != 5'b0) && !d0_rs2;

    // Forward A 控制 (rs1 数据源选择)
    // rs1 总是在 EX 阶段使用 (C=EX)，所以 P<=C 恒成立 (ALU 的 P=EX <= C=EX)
    // 只需要根据 D 选择数据源
    assign forward_a = d0_rs1 ? `FWD_MEM : (d1_rs1 ? `FWD_WB : `FWD_RF);

    // Forward B 控制 (rs2 数据源选择)
    // rs2 的使用阶段取决于指令类型：
    //   - C=EX (ALU/Branch)：rs2 在 EX 使用
    //   - C=MEM (Store)：rs2 在 MEM 使用
    // 无论 C=EX 还是 C=MEM，转发逻辑相同：优先 D=0，其次 D=1
    assign forward_b = d0_rs2 ? `FWD_MEM : (d1_rs2 ? `FWD_WB : `FWD_RF);

    // Load->Store 特殊旁路
    // 条件：
    //   - c_mem=1：当前是 Store，rs2 在 MEM 使用
    //   - d0_rs2=1：前一条指令的目的寄存器匹配 rs2 (D=0)
    //   - p_mem=1：前一条是 Load，数据在 MEM 结束可用
    // 时机：Load 在 MEM 阶段完成，Store 进入 MEM 阶段，数据直接旁路
    assign mem_bypass = c_mem && d0_rs2 && p_mem;

endmodule
