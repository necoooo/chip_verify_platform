// UART寄存器接口 — AHB从机总线接口与寄存器组
//
// 寄存器映射：
//   0x00: UART_CTRL   — 控制寄存器
//   0x04: UART_BAUD   — 波特率分频器
//   0x08: UART_STATUS — 状态寄存器
//   0x0C: UART_TXD    — 发送数据寄存器
//   0x10: UART_RXD    — 接收数据寄存器

module uart_regif (
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

  // 控制输出
  output wire       tx_en_o,
  output wire       rx_en_o,
  output wire [15:0] baud_div_o,

  // 发送接口
  output wire [7:0] tx_data_o,
  output wire       tx_start_o,

  // 接收接口
  input  wire [7:0] rx_data_i,
  input  wire       rx_valid_i,
  input  wire       rx_overflow_i,
  input  wire       frame_err_i,

  // 发送状态
  input  wire       tx_busy_i,
  input  wire       tx_done_i
);

  // 寄存器
  reg       tx_en_d, tx_en_q;
  reg       rx_en_d, rx_en_q;
  reg [15:0] baud_div_d, baud_div_q;
  reg [7:0] tx_data_d, tx_data_q;
  reg       tx_start_d, tx_start_q;

  // 状态清除（读后自动清零）
  reg tx_done_clr, rx_valid_clr, rx_overflow_clr, frame_err_clr;
  reg tx_done_s, rx_valid_s, rx_overflow_s, frame_err_s;

  // 握手信号
  wire ahb_active;
  assign ahb_active = hsel_i && (htrans_i == 2'b10);
  assign hresp_o = 2'b00;
  assign hready_o = 1'b1;

  // 输出
  assign tx_en_o      = tx_en_q;
  assign rx_en_o      = rx_en_q;
  assign baud_div_o   = baud_div_q;
  assign tx_data_o    = tx_data_q;
  assign tx_start_o   = tx_start_q;

  // 状态位锁存（set由硬件，clear由读操作）
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      tx_done_s     <= 1'b0;
      rx_valid_s    <= 1'b0;
      rx_overflow_s <= 1'b0;
      frame_err_s   <= 1'b0;
    end else begin
      if (tx_done_i) begin
        tx_done_s <= 1'b1;
      end else if (tx_done_clr) begin
        tx_done_s <= 1'b0;
      end
      if (rx_valid_i) begin
        rx_valid_s <= 1'b1;
      end else if (rx_valid_clr) begin
        rx_valid_s <= 1'b0;
      end
      if (rx_overflow_i) begin
        rx_overflow_s <= 1'b1;
      end else if (rx_overflow_clr) begin
        rx_overflow_s <= 1'b0;
      end
      if (frame_err_i) begin
        frame_err_s <= 1'b1;
      end else if (frame_err_clr) begin
        frame_err_s <= 1'b0;
      end
    end
  end

  // AHB读写处理
  always @(*) begin
    tx_en_d       = tx_en_q;
    rx_en_d       = rx_en_q;
    baud_div_d    = baud_div_q;
    tx_data_d     = tx_data_q;
    tx_start_d    = 1'b0;
    tx_done_clr   = 1'b0;
    rx_valid_clr  = 1'b0;
    rx_overflow_clr = 1'b0;
    frame_err_clr = 1'b0;

    if (hwrite_i) begin
      case (haddr_i[3:0])
        4'h0: begin
          tx_en_d = hwdata_i[0];
          rx_en_d = hwdata_i[1];
        end
        4'h4: baud_div_d = hwdata_i[15:0];
        4'hC: begin
          tx_data_d  = hwdata_i[7:0];
          tx_start_d = 1'b1;
        end
        default: ;
      endcase
    end else begin
      // 读STATUS时自动清除
      if (haddr_i[3:0] == 4'h8) begin
        tx_done_clr    = 1'b1;
        rx_valid_clr   = 1'b1;
        rx_overflow_clr = 1'b1;
        frame_err_clr  = 1'b1;
      end
    end
  end

  // 寄存器更新
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      tx_en_q    <= 1'b1;
      rx_en_q    <= 1'b1;
      baud_div_q <= 16'd433;   // 115200 @ 50MHz
      tx_data_q  <= 8'd0;
      tx_start_q <= 1'b0;
    end else begin
      tx_en_q    <= tx_en_d;
      rx_en_q    <= rx_en_d;
      baud_div_q <= baud_div_d;
      tx_data_q  <= tx_data_d;
      tx_start_q <= tx_start_d;
    end
  end

  // 读数据多路复用
  assign hrdata_o = (haddr_i[3:0] == 4'h0)  ? {27'h0, 3'b0, rx_en_q, tx_en_q} :
                    (haddr_i[3:0] == 4'h4)  ? {16'h0, baud_div_q} :
                    (haddr_i[3:0] == 4'h8)  ? {27'h0, frame_err_s, rx_overflow_s,
                                              rx_valid_s, tx_done_s, tx_busy_i} :
                    (haddr_i[3:0] == 4'hC)  ? {24'h0, tx_data_q} :
                    (haddr_i[3:0] == 4'h10) ? {24'h0, rx_data_i} :
                    32'h0;

endmodule
