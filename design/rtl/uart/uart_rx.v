// UART接收模块 — 8N1异步串行接收器
//
// 功能：串行输入检测 → 并行数据输出
// 时序：检测起始位下降沿 → 在每位中点采样 → 输出8位数据
// 状态机：三段式结构（状态寄存器 + 下一状态逻辑 + 输出寄存器）
// V1.3: 修复rx_overflow_o NBA竞争导致溢出检测永不触发; 新增rx_clear_i清除机制

module uart_rx (
  input  wire       clk_i,
  input  wire       rst_ni,

  input  wire       rx_en_i,          // 接收使能
  input  wire       baud_tick_i,      // 波特率采样脉冲
  input  wire       uart_rx_i,        // 串行输入
  input  wire       rx_clear_i,       // V1.3: 清除已读标志(来自regif STATUS读)

  output reg  [7:0] rx_data_o,        // 接收数据
  output reg        rx_valid_o,       // 接收数据有效脉冲
  output reg        rx_overflow_o,    // 接收溢出
  output reg        frame_err_o,      // 帧错误（停止位异常）
  output wire       start_det_o       // V1.1: 起始位检测
);

  // 状态定义
  localparam [1:0] S_IDLE  = 2'd0;
  localparam [1:0] S_START = 2'd1;
  localparam [1:0] S_DATA  = 2'd2;
  localparam [1:0] S_STOP  = 2'd3;

  // 状态寄存器
  reg [1:0] curr_state;
  reg [1:0] next_state;

  // 数据通路寄存器
  reg [2:0] bit_cnt;
  reg [7:0] shift_reg;
  reg       rx_pending_q;     // V1.3: 接收缓冲待读标志(替代NBA检查)

  // 同步寄存器（2级，避免亚稳态）
  reg rx_sync1, rx_sync2;
  reg rx_prev;
  wire rx_falling;

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
  assign start_det_o = rx_falling && rx_en_i && (curr_state == S_IDLE);

  // ========================================================================
  // Block 1: 状态转移时序逻辑
  // ========================================================================
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      curr_state <= S_IDLE;
    end else begin
      curr_state <= next_state;
    end
  end

  // ========================================================================
  // Block 2: 下一状态组合逻辑
  // ========================================================================
  always @(*) begin
    next_state = curr_state;

    case (curr_state)
      S_IDLE: begin
        if (rx_falling && rx_en_i) begin
          next_state = S_START;
        end
      end

      S_START: begin
        if (baud_tick_i) begin
          if (!rx_sync2) begin
            next_state = S_DATA;
          end else begin
            next_state = S_IDLE;  // 假起始位
          end
        end
      end

      S_DATA: begin
        if (baud_tick_i && bit_cnt == 3'd7) begin
          next_state = S_STOP;
        end
      end

      S_STOP: begin
        if (baud_tick_i) begin
          next_state = S_IDLE;
        end
      end

      default: next_state = S_IDLE;
    endcase
  end

  // ========================================================================
  // Block 3: 输出时序逻辑（寄存器输出，避免毛刺）
  // ========================================================================
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rx_data_o     <= 8'd0;
      rx_valid_o    <= 1'b0;
      rx_overflow_o <= 1'b0;
      frame_err_o   <= 1'b0;
      bit_cnt       <= 3'd0;
      shift_reg     <= 8'd0;
      rx_pending_q  <= 1'b0;
    end else begin
      // 默认值
      rx_valid_o <= 1'b0;

      // V1.3: rx_clear_i由regif在读STATUS时产生, 清除pending标志
      if (rx_clear_i) begin
        rx_pending_q <= 1'b0;
      end

      case (curr_state)
        S_IDLE: begin
          frame_err_o <= 1'b0;
          if (rx_falling && rx_en_i) begin
            bit_cnt <= 3'd0;
          end
        end

        S_START: begin
          if (baud_tick_i && !rx_sync2) begin
            // 起始位确认，准备接收
          end
        end

        S_DATA: begin
          if (baud_tick_i) begin
            shift_reg <= {rx_sync2, shift_reg[7:1]};
            bit_cnt   <= bit_cnt + 3'd1;
          end
        end

        S_STOP: begin
          if (baud_tick_i) begin
            if (rx_sync2) begin
              rx_data_o  <= shift_reg;
              rx_valid_o <= 1'b1;
              // V1.3: 使用rx_pending_q替代NBA竞争检查
              if (rx_pending_q) begin
                rx_overflow_o <= 1'b1;
              end
              rx_pending_q <= 1'b1;
            end else begin
              frame_err_o <= 1'b1;
            end
          end
        end

        default: begin
          rx_valid_o    <= 1'b0;
          rx_overflow_o <= 1'b0;
          frame_err_o   <= 1'b0;
        end
      endcase
    end
  end

endmodule
