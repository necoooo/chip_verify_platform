// SYS_TC顶层模块 — 集成AHB寄存器接口与32位向下计数核心
//
// 功能：可配置定时周期，自动重载，可屏蔽中断，默认1ms @ 50MHz

module sys_tc_top (
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
  output wire       tc_int_o
);

  // 内部信号
  wire        en;
  wire        ie;
  wire [31:0] reload;
  wire [31:0] count;
  wire        int_flag;
  wire        int_flag_clr;

  // 中断标志（写1清零）
  reg int_flag_latched, int_flag_latched_d;

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      int_flag_latched <= 1'b0;
    end else begin
      if (int_flag) begin
        int_flag_latched <= 1'b1;
      end else if (int_flag_clr) begin
        int_flag_latched <= 1'b0;
      end
    end
  end

  // 寄存器接口
  sys_tc_regif u_regif (
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
    .en_o     (en),
    .ie_o     (ie),
    .reload_o (reload),
    .count_i  (count),
    .int_flag_clr_o(int_flag_clr),
    .int_flag_i    (int_flag_latched)
  );

  // 计数核心
  sys_tc_counter u_counter (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .en_i   (en),
    .ie_i   (ie),
    .reload_i(reload),
    .count_o (count),
    .tc_int_o(tc_int_o),
    .int_flag_o(int_flag)
  );

endmodule
