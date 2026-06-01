// UART接收模块 — 8N1异步串行接收器
//
// 功能：串行输入检测 → 并行数据输出
// 时序：检测起始位下降沿 → 在每位中点采样 → 输出8位数据

module uart_rx (
  input  wire       clk_i,
  input  wire       rst_ni,

  input  wire       rx_en_i,          // 接收使能
  input  wire       baud_tick_i,      // 波特率采样脉冲
  input  wire       uart_rx_i,        // 串行输入

  output wire [7:0] rx_data_o,        // 接收数据
  output wire       rx_valid_o,       // 接收数据有效脉冲
  output wire       rx_overflow_o,    // 接收溢出
  output wire       frame_err_o       // 帧错误（停止位异常）
);

  // 状态编码
  localparam [1:0] RxIdle  = 2'd0;
  localparam [1:0] RxStart = 2'd1;
  localparam [1:0] RxData  = 2'd2;
  localparam [1:0] RxStop  = 2'd3;

  reg [1:0] rx_state_d, rx_state_q;
  reg [2:0] rx_bit_cnt_d, rx_bit_cnt_q;
  reg [7:0] rx_shift_d, rx_shift_q;
  reg [7:0] rx_data_d, rx_data_q;
  reg       rx_valid_d, rx_valid_q;
  reg       rx_overflow_d, rx_overflow_q;
  reg       frame_err_d, frame_err_q;

  // 同步寄存器（2级，避免亚稳态）
  reg rx_sync1, rx_sync2;
  reg rx_prev;
  wire  rx_falling;

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rx_sync1 <= 1'b1;
      rx_sync2 <= 1'b1;
      rx_prev  <= 1'b1;
    end else begin
      rx_sync1 <= uart_rx_i;
      rx_sync2 <= rx_sync1;
      rx_prev  <= rx_sync2;
    end
  end

  assign rx_falling = rx_prev && !rx_sync2;

  // 输出
  assign rx_data_o     = rx_data_q;
  assign rx_valid_o    = rx_valid_q;
  assign rx_overflow_o = rx_overflow_q;
  assign frame_err_o   = frame_err_q;

  // 下一状态逻辑
  always @(*) begin
    rx_state_d    = rx_state_q;
    rx_bit_cnt_d  = rx_bit_cnt_q;
    rx_shift_d    = rx_shift_q;
    rx_data_d     = rx_data_q;
    rx_valid_d    = 1'b0;
    rx_overflow_d = rx_overflow_q;
    frame_err_d   = frame_err_q;

    case (rx_state_q)
      RxIdle: begin
        frame_err_d = 1'b0;
        if (rx_falling && rx_en_i) begin
          rx_state_d   = RxStart;
          rx_bit_cnt_d = 3'd0;
        end
      end

      RxStart: begin
        if (baud_tick_i) begin
          if (!rx_sync2) begin
            rx_state_d = RxData;
          end else begin
            rx_state_d = RxIdle;  // 假起始位
          end
        end
      end

      RxData: begin
        if (baud_tick_i) begin
          rx_shift_d   = {rx_sync2, rx_shift_q[7:1]};
          rx_bit_cnt_d = rx_bit_cnt_q + 3'd1;
          if (rx_bit_cnt_q == 3'd7) begin
            rx_state_d = RxStop;
          end
        end
      end

      RxStop: begin
        if (baud_tick_i) begin
          if (rx_sync2) begin
            rx_data_d  = rx_shift_q;
            rx_valid_d = 1'b1;
            if (rx_valid_q) begin
              rx_overflow_d = 1'b1;
            end
          end else begin
            frame_err_d = 1'b1;
          end
          rx_state_d = RxIdle;
        end
      end

      default: rx_state_d = RxIdle;
    endcase
  end

  // 寄存器
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rx_state_q    <= RxIdle;
      rx_bit_cnt_q  <= 3'd0;
      rx_shift_q    <= 8'd0;
      rx_data_q     <= 8'd0;
      rx_valid_q    <= 1'b0;
      rx_overflow_q <= 1'b0;
      frame_err_q   <= 1'b0;
    end else begin
      rx_state_q    <= rx_state_d;
      rx_bit_cnt_q  <= rx_bit_cnt_d;
      rx_shift_q    <= rx_shift_d;
      rx_data_q     <= rx_data_d;
      rx_valid_q    <= rx_valid_d;
      rx_overflow_q <= rx_overflow_d;
      frame_err_q   <= frame_err_d;
    end
  end

endmodule
