`include "defines.v"

// =============================================================================
// Hazard Stall 检测模块
// =============================================================================
// 功能：检测 Load-use 数据冒险，在 ID 阶段产生 stall 信号
//
// P/C/D 理论框架：
// -----------------------------------------------------------------------------
// | 维度 | 含义              | 流水线对应        | 关键取值            |
// |------|-------------------|-------------------|---------------------|
// | P    | Production(产生)  | Load=MEM, ALU=EX  | ex_ren_mem 标志 P=MEM|
// | C    | Consumption(消费) | ALU=EX, Store=MEM | id_wen_mem 标志 C=MEM|
// | D    | Distance(距离)    | D=0=前指令，D=1=前前指令 | 寄存器地址匹配判断 |
// -----------------------------------------------------------------------------
//
// Stall 条件：P=MEM > C=EX 且 D=0
//   - 前一条是 Load (P=MEM)，数据在 MEM 结束才可用
//   - 当前指令需要该数据在 EX 阶段使用 (C=EX)
//   - 两条指令相邻 (D=0)
//
// 特殊情况处理：
//   - Store 的 rs2 在 MEM 阶段使用 (C=MEM)，与 Load 的 P=MEM 持平，不需要 stall
//   - 数据通过 forward 模块从 MEM 输出直接旁路到 Store 的输入
//
// 端口说明：
//   - id_* : 当前指令 (Consumer)，在 ID 阶段解码
//   - ex_* : 前一条指令 (Producer)，在 EX 阶段执行
// =============================================================================

module hazard_stall (
    // 当前指令 (Consumer) 的源寄存器地址
    input wire [4:0] id_rs1_addr,   // rs1 地址，C=EX (在 EX 阶段使用)
    input wire [4:0] id_rs2_addr,   // rs2 地址，C 取决于 id_wen_mem
    input wire       id_wen_mem,    // C=MEM 标志，1=Store(rs2 在 MEM 使用)

    // 前一条指令 (Producer, D=0 来源)
    input wire [4:0] ex_rd_addr,    // 目的寄存器地址，用于 D 检测
    input wire       ex_ren_mem,    // P=MEM 标志，1=Load(数据在 MEM 结束可用)
    input wire       ex_reg_wen_wb, // 写回使能，确认会产生数据

    // Stall 输出
    output wire      stall          // P>C 且 D=0 时置位，冻结 PC 和 ID 阶段
);

    // D=0 检测：前指令目的寄存器与当前指令源寄存器匹配
    // ex_rd_addr != 0 排除 x0 寄存器 (x0 始终为 0，不需要 forward)
    wire d0_rs1 = (ex_rd_addr == id_rs1_addr) && ex_reg_wen_wb && (ex_rd_addr != 5'b0);

    // rs2 的 stall 判断：
    // - 当前是 Store (id_wen_mem=1)：rs2 在 MEM 使用 (C=MEM)，P=C 不需要 stall
    // - 当前不是 Store：rs2 在 EX 使用 (C=EX)，P> C 需要 stall
    wire d0_rs2 = (ex_rd_addr == id_rs2_addr) && ex_reg_wen_wb && (ex_rd_addr != 5'b0) && !id_wen_mem;

    // Stall 条件：P=MEM (ex_ren_mem) 且 (D=0 for rs1 或 D=0 for rs2)
    assign stall = ex_ren_mem && (d0_rs1 || d0_rs2);

endmodule
