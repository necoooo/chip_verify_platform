// UART顶层模块 — 集成AHB寄存器接口、发送器、接收器和波特率发生器
// V1.2: TX/RX独立波特率计数器, RX同步起始位, 支持回环和agent驱动

module uart_top (
  input  wire       clk_i,
  input  wire       rst_ni,
  input  wire       hsel_i,
  input  wire [31:0] haddr_i,
  input  wire       hwrite_i,
  input  wire [1:0] htrans_i,
  input  wire [31:0] hwdata_i,
  output wire [31:0] hrdata_o,
  output wire       hready_o,
  output wire [1:0] hresp_o,
  output wire       uart_tx_o,
  input  wire       uart_rx_i,
  output wire       tx_int_o,
  output wire       rx_int_o
);

  wire        tx_en, rx_en;
  wire [15:0] baud_div;
  wire [7:0]  tx_data, rx_data;
  wire        tx_start, rx_valid, rx_overflow, frame_err;
  wire        tx_busy, tx_done;
  wire        tx_baud_tick, rx_baud_tick;
  wire        rx_start_det;

  // ========================================================================
  // TX波特率计数器 (自由运行)
  // ========================================================================
  reg [15:0] tx_baud_cnt_d, tx_baud_cnt_q;
  assign tx_baud_tick = (tx_baud_cnt_q == 16'd0);

  always @(*) begin
    if (tx_baud_tick || (!tx_en && !rx_en))
      tx_baud_cnt_d = baud_div;
    else
      tx_baud_cnt_d = tx_baud_cnt_q - 16'd1;
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) tx_baud_cnt_q <= 16'd0;
    else         tx_baud_cnt_q <= tx_baud_cnt_d;
  end

  // ========================================================================
  // RX波特率计数器 (独立, 起始位同步)
  // ========================================================================
  reg [15:0] rx_baud_cnt_d, rx_baud_cnt_q;
  assign rx_baud_tick = (rx_baud_cnt_q == 16'd0);

  always @(*) begin
    if (rx_start_det)
      rx_baud_cnt_d = (baud_div + 1) >> 1;  // 半bit → 起始位中点
    else if (rx_baud_tick)
      rx_baud_cnt_d = baud_div;
    else
      rx_baud_cnt_d = rx_baud_cnt_q - 16'd1;
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) rx_baud_cnt_q <= 16'd0;
    else         rx_baud_cnt_q <= rx_baud_cnt_d;
  end

  // ========================================================================
  // 子模块
  // ========================================================================
  uart_regif u_regif (
    .clk_i, .rst_ni, .hsel_i, .haddr_i, .hwrite_i, .htrans_i,
    .hwdata_i, .hrdata_o, .hready_o, .hresp_o,
    .tx_en_o(tx_en), .rx_en_o(rx_en), .baud_div_o(baud_div),
    .tx_data_o(tx_data), .tx_start_o(tx_start),
    .rx_data_i(rx_data), .rx_valid_i(rx_valid),
    .rx_overflow_i(rx_overflow), .frame_err_i(frame_err),
    .tx_busy_i(tx_busy), .tx_done_i(tx_done)
  );

  uart_tx u_tx (
    .clk_i, .rst_ni,
    .tx_en_i(tx_en), .baud_tick_i(tx_baud_tick),
    .tx_data_i(tx_data), .tx_start_i(tx_start),
    .uart_tx_o(uart_tx_o), .tx_busy_o(tx_busy), .tx_done_o(tx_done)
  );

  uart_rx u_rx (
    .clk_i, .rst_ni,
    .rx_en_i(rx_en), .baud_tick_i(rx_baud_tick),
    .uart_rx_i(uart_rx_i), .rx_data_o(rx_data),
    .rx_valid_o(rx_valid), .rx_overflow_o(rx_overflow),
    .frame_err_o(frame_err), .start_det_o(rx_start_det)
  );

  assign tx_int_o = tx_done;
  assign rx_int_o = rx_valid;

endmodule
