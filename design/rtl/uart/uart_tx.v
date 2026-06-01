// UART发送模块 — 8N1异步串行发送器
//
// 功能：并行数据 → 串行输出（LSB first）
// 时序：1起始位 + 8数据位 + 1停止位
// 状态机：三段式结构（状态寄存器 + 下一状态逻辑 + 输出寄存器）

module uart_tx (
  input  wire       clk_i,
  input  wire       rst_ni,

  input  wire       tx_en_i,          // 发送使能
  input  wire       baud_tick_i,      // 波特率采样脉冲
  input  wire [7:0] tx_data_i,        // 待发送数据
  input  wire       tx_start_i,       // 启动发送脉冲

  output reg        uart_tx_o,        // 串行输出
  output reg        tx_busy_o,        // 发送忙
  output reg        tx_done_o         // 发送完成脉冲
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
        if (tx_start_i && tx_en_i) begin
          next_state = S_START;
        end
      end

      S_START: begin
        if (baud_tick_i) begin
          next_state = S_DATA;
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
      uart_tx_o <= 1'b1;
      tx_busy_o <= 1'b0;
      tx_done_o <= 1'b0;
      bit_cnt   <= 3'd0;
      shift_reg <= 8'd0;
    end else begin
      // 默认值
      tx_done_o <= 1'b0;

      case (curr_state)
        S_IDLE: begin
          uart_tx_o <= 1'b1;
          tx_busy_o <= 1'b0;
          if (tx_start_i && tx_en_i) begin
            shift_reg <= tx_data_i;
            bit_cnt   <= 3'd0;
          end
        end

        S_START: begin
          tx_busy_o <= 1'b1;
          if (baud_tick_i) begin
            uart_tx_o <= 1'b0;
          end
        end

        S_DATA: begin
          if (baud_tick_i) begin
            uart_tx_o  <= shift_reg[0];
            shift_reg  <= {1'b0, shift_reg[7:1]};
            bit_cnt    <= bit_cnt + 3'd1;
          end
        end

        S_STOP: begin
          if (baud_tick_i) begin
            uart_tx_o <= 1'b1;
            tx_done_o <= 1'b1;
            tx_busy_o <= 1'b0;
          end
        end

        default: begin
          uart_tx_o <= 1'b1;
          tx_busy_o <= 1'b0;
        end
      endcase
    end
  end

endmodule
