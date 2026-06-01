// DSP顶层模块 — 集成AHB寄存器接口与8位加减法运算核心
//
// 功能：AHB配置操作数与启动，单周期运算，完成中断

module dsp_top (
  input  wire       clk_i,
  input  wire       rst_ni,

  // AHB从机接口
  input  wire       hsel_i,
  input  wire [31:0] haddr_i,
  input  wire       hwrite_i,
  input  wire [1:0] htrans_i,
  input  wire [31:0] hwdata_i,
  output wire [31:0] hrdata_o,
  output wire       hready_o,
  output wire [1:0] hresp_o,

  // 中断
  output wire       done_int_o
);

  // 内部信号
  wire [7:0] opa;
  wire [7:0] opb;
  wire       op_sel;
  wire       start;
  wire [8:0] result;
  wire       busy;
  wire       done;

  // 寄存器接口
  dsp_regif u_regif (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .hsel_i   (hsel_i),
    .haddr_i  (haddr_i),
    .hwrite_i (hwrite_i),
    .htrans_i (htrans_i),
    .hwdata_i (hwdata_i),
    .hrdata_o (hrdata_o),
    .hready_o (hready_o),
    .hresp_o  (hresp_o),
    .opa_o    (opa),
    .opb_o    (opb),
    .op_sel_o (op_sel),
    .start_o  (start),
    .result_i (result),
    .busy_i   (busy),
    .done_i   (done)
  );

  // 运算核心
  dsp_core u_core (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .opa_i   (opa),
    .opb_i   (opb),
    .op_sel_i(op_sel),
    .start_i (start),
    .result_o(result),
    .busy_o  (busy),
    .done_o  (done)
  );

  assign done_int_o = done;

endmodule
