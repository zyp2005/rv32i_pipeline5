`ifndef DEFINES_V
`define DEFINES_V

// ==========================================
// 1. 核心操作码 (7 位) - 严格用 OP_ 开头
// ==========================================
`define OP_IMM    7'b0010011  // I-Type 算术
`define OP_LOAD   7'b0000011  // Load
`define OP_STORE  7'b0100011  // Store
`define OP_REG    7'b0110011  // R-Type
`define OP_BRANCH 7'b1100011  // B-Type
`define OP_JAL    7'b1101111  // J-Type
`define OP_JALR   7'b1100111  // I-Type 跳转
`define OP_LUI    7'b0110111
`define OP_AUIPC  7'b0010111
`define OP_SYSTEM 7'b1110011  // ECALL/EBREAK

// ==========================================
// 2. 功能码 (3 位) - 严格用 FUNCT3_ 开头
// ==========================================
`define FUNCT3_ADDAUB  3'b000
`define FUNCT3_SLL     3'b001
`define FUNCT3_SLT     3'b010
`define FUNCT3_SLTU    3'b011
`define FUNCT3_XOR     3'b100
`define FUNCT3_SR      3'b101
`define FUNCT3_OR      3'b110
`define FUNCT3_AND     3'b111

`define FUNCT3_LB   3'b000
`define FUNCT3_LH   3'b001
`define FUNCT3_LW   3'b010
`define FUNCT3_LBU  3'b100
`define FUNCT3_LHU  3'b101
`define FUNCT3_SB   3'b000
`define FUNCT3_SH   3'b001
`define FUNCT3_SW   3'b010

`define FUNCT3_BEQ  3'b000
`define FUNCT3_BNE  3'b001
`define FUNCT3_BLT  3'b100
`define FUNCT3_BGE  3'b101
`define FUNCT3_BLTU 3'b110
`define FUNCT3_BGEU 3'b111

// ==========================================
// 3. 扩展功能码 (7 位) - 严格用 FUNCT7_ 开头
// ==========================================
`define FUNCT7_ADD  7'b0000000
`define FUNCT7_SUB  7'b0100000
`define FUNCT7_SRL  7'b0000000
`define FUNCT7_SRA  7'b0100000

// ==========================================
// 4. 完整指令机器码 (32 位)
// ==========================================
`define INST_NOP    32'h00000013

// ==========================================
// 5. ALU 操作码 (2 位) - 流水线控制
// ==========================================
`define ALUOP_ARITH   2'b00  // 算术指令
`define ALUOP_BRANCH  2'b01  // 分支指令
`define ALUOP_MEM     2'b10  // load/store
`define ALUOP_JUMP    2'b11  // jal/jalr/lui/auipc

// ==========================================
// 6. ALU 控制码 (4 位) - 具体 ALU 操作
// ==========================================
`define ALU_ADD   4'b0000
`define ALU_SUB   4'b0001
`define ALU_AND   4'b0010
`define ALU_OR    4'b0011
`define ALU_XOR   4'b0100
`define ALU_SLL   4'b0101
`define ALU_SRL   4'b0110
`define ALU_SRA   4'b0111
`define ALU_SLT   4'b1000
`define ALU_SLTU  4'b1001

// ==========================================
// 7. Forward 控制码 (2 位) - 数据源选择
// ==========================================
`define FWD_RF    2'b00  // 从寄存器堆读取 (无转发)
`define FWD_MEM   2'b10  // 从 MEM 阶段转发 (前一条指令结果)
`define FWD_WB    2'b01  // 从 WB 阶段转发 (前前条指令结果)

// ==========================================
// 8. 内存访问宽度 (2 位)
// ==========================================
`define MEM_BYTE  2'b00  // 字节访问 (LB, LBU, SB)
`define MEM_HALF  2'b01  // 半字访问 (LH, LHU, SH)
`define MEM_WORD  2'b10  // 字访问 (LW, SW)

`endif // defines.v
