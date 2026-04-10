`include "defines.v"

// MEM 模块 - 内存访问阶段
// 功能：处理 Load/Store 指令的数据访问
module mem #(
    parameter XLEN = 32
)(
    // 来自 EX_MEM 寄存器
    input wire [4:0]      rd_addr,
    input wire            reg_wen_wb,
    input wire            wen_mem,
    input wire            ren_mem,
    input wire [1:0]      mem_width,
    input wire            is_u_load_mem,

    input wire [XLEN-1:0] rs2,
    input wire [XLEN-1:0] alu_result,

    // Forward 旁路 (Load→Store)
    input wire [XLEN-1:0] rd_wb,
    input wire            mem_bypass,

    // DROM 接口
    input wire [XLEN-1:0] dout,

    // 输出到 DROM
    output wire [3:0]      we,
    output wire [XLEN-1:0] addr_byte,
    output wire [XLEN-1:0] wdata,

    // 输出到 MEM_WB
    output wire [4:0]      rd_addr_out,
    output wire [XLEN-1:0] rd,
    output wire            reg_wen_wb_out,
    output wire            wen_mem_out,
    output wire            ren_mem_out
);

    wire [1:0]      offset;
    wire [4:0]      shift_control;
    wire [XLEN-1:0] rs2_selected;
    wire [XLEN-1:0] rs2_shifted;
    wire [XLEN-1:0] dout_extended;

    // offset 提取 (alu_result[1:0])
    assign offset = alu_result[1:0];

    // addr_byte: alu_result 低 2 位归零 (字对齐)
    assign addr_byte = {alu_result[XLEN-1:2], 2'b00};

    // mem_bypass 选择：rs2 或 rd_wb (Load→Store 旁路)
    assign rs2_selected = mem_bypass ? rd_wb : rs2;

    // drom_control: 生成 we 和 shift_control
    drom_control drom_control_inst (
        .wen_mem(wen_mem),
        .mem_width(mem_width),
        .offset(offset),
        .we(we),
        .shift_control(shift_control)
    );

    // shift_left: Store 数据左移对齐
    shift_left shift_left_inst (
        .data(rs2_selected),
        .shift_control(shift_control),
        .shifted_data(rs2_shifted)
    );

    // wdata 输出 (移位后的 rs2)
    assign wdata = rs2_shifted;

    // data_extend: Load 数据符号/零扩展
    data_extend data_extend_inst (
        .mem_width(mem_width),
        .is_u_load_mem(is_u_load_mem),
        .byte_offset(offset),
        .dout(dout),
        .extended_data(dout_extended)
    );

    // rd 选择：Load 指令输出扩展数据，Store 输出 alu_result
    assign rd = ren_mem ? dout_extended : alu_result;

    // 控制信号直接输出
    assign rd_addr_out = rd_addr;
    assign reg_wen_wb_out = reg_wen_wb;
    assign wen_mem_out = wen_mem;
    assign ren_mem_out = ren_mem;

endmodule
