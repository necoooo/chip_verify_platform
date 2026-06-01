// UART顶层模块 — 集成AHB寄存器接口、发送器、接收器和波特率发生器
//
// 功能：全双工异步串行通信，115200bps/8N1，AHB可配波特率

module uart_top (
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

  // UART物理引脚
  output wire       uart_tx_o,
  input  wire       uart_rx_i,

  // 中断输出
  output wire       tx_int_o,
  output wire       rx_int_o
);

  // 内部连接
  wire        tx_en;
  wire        rx_en;
  wire [15:0] baud_div;
  wire [7:0]  tx_data;
  wire        tx_start;
  wire [7:0]  rx_data;
  wire        rx_valid;
  wire        rx_overflow;
  wire        frame_err;
  wire        tx_busy;
  wire        tx_done;
  wire        baud_tick;

  // 波特率发生器
  logic [15:0] baud_cnt_d, baud_cnt_q;

  assign baud_tick = (baud_cnt_q == 16'd0);

  always_comb begin
    if (baud_tick || (!tx_en && !rx_en)) begin
      baud_cnt_d = baud_div;
    end else begin
      baud_cnt_d = baud_cnt_q - 16'd1;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      baud_cnt_q <= 16'd0;
    end else begin
      baud_cnt_q <= baud_cnt_d;
    end
  end

  // 寄存器接口
  uart_regif u_regif (
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
    .tx_en_o    (tx_en),
    .rx_en_o    (rx_en),
    .baud_div_o (baud_div),
    .tx_data_o  (tx_data),
    .tx_start_o (tx_start),
    .rx_data_i    (rx_data),
    .rx_valid_i   (rx_valid),
    .rx_overflow_i(rx_overflow),
    .frame_err_i  (frame_err),
    .tx_busy_i    (tx_busy),
    .tx_done_i    (tx_done)
  );

  // 发送器
  uart_tx u_tx (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .tx_en_i      (tx_en),
    .baud_tick_i  (baud_tick),
    .tx_data_i    (tx_data),
    .tx_start_i   (tx_start),
    .uart_tx_o    (uart_tx_o),
    .tx_busy_o    (tx_busy),
    .tx_done_o    (tx_done)
  );

  // 接收器
  uart_rx u_rx (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .rx_en_i      (rx_en),
    .baud_tick_i  (baud_tick),
    .uart_rx_i    (uart_rx_i),
    .rx_data_o    (rx_data),
    .rx_valid_o   (rx_valid),
    .rx_overflow_o(rx_overflow),
    .frame_err_o  (frame_err)
  );

  assign tx_int_o = tx_done;
  assign rx_int_o = rx_valid;

endmodule
