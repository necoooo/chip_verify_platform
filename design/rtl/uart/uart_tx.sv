// UART发送模块 — 8N1异步串行发送器
//
// 功能：并行数据 → 串行输出（LSB first）
// 时序：1起始位 + 8数据位 + 1停止位

module uart_tx (
  input  wire       clk_i,
  input  wire       rst_ni,

  input  wire       tx_en_i,          // 发送使能
  input  wire       baud_tick_i,      // 波特率采样脉冲
  input  wire [7:0] tx_data_i,        // 待发送数据
  input  wire       tx_start_i,       // 启动发送脉冲

  output wire       uart_tx_o,        // 串行输出
  output wire       tx_busy_o,        // 发送忙
  output wire       tx_done_o         // 发送完成脉冲
);

  // 状态编码
  typedef enum logic [1:0] {
    TxIdle,
    TxStart,
    TxData,
    TxStop
  } tx_state_e;

  tx_state_e tx_state_d, tx_state_q;
  logic [2:0] tx_bit_cnt_d, tx_bit_cnt_q;
  logic [7:0] tx_shift_d, tx_shift_q;
  logic       tx_busy_d, tx_busy_q;
  logic       tx_done_d, tx_done_q;
  logic       uart_tx_d, uart_tx_q;

  // 输出
  assign uart_tx_o  = uart_tx_q;
  assign tx_busy_o  = tx_busy_q;
  assign tx_done_o  = tx_done_q;

  // 下一状态逻辑
  always_comb begin
    tx_state_d   = tx_state_q;
    tx_bit_cnt_d = tx_bit_cnt_q;
    tx_shift_d   = tx_shift_q;
    tx_busy_d    = tx_busy_q;
    tx_done_d    = 1'b0;
    uart_tx_d    = uart_tx_q;

    unique case (tx_state_q)
      TxIdle: begin
        uart_tx_d = 1'b1;
        tx_busy_d = 1'b0;
        if (tx_start_i && tx_en_i) begin
          tx_shift_d   = tx_data_i;
          tx_bit_cnt_d = 3'd0;
          tx_state_d   = TxStart;
          tx_busy_d    = 1'b1;
        end
      end

      TxStart: begin
        if (baud_tick_i) begin
          uart_tx_d  = 1'b0;
          tx_state_d = TxData;
        end
      end

      TxData: begin
        if (baud_tick_i) begin
          uart_tx_d    = tx_shift_q[0];
          tx_shift_d   = {1'b0, tx_shift_q[7:1]};
          tx_bit_cnt_d = tx_bit_cnt_q + 3'd1;
          if (tx_bit_cnt_q == 3'd7) begin
            tx_state_d = TxStop;
          end
        end
      end

      TxStop: begin
        if (baud_tick_i) begin
          uart_tx_d  = 1'b1;
          tx_done_d  = 1'b1;
          tx_busy_d  = 1'b0;
          tx_state_d = TxIdle;
        end
      end

      default: tx_state_d = TxIdle;
    endcase
  end

  // 寄存器
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      tx_state_q   <= TxIdle;
      tx_bit_cnt_q <= 3'd0;
      tx_shift_q   <= 8'd0;
      tx_busy_q    <= 1'b0;
      tx_done_q    <= 1'b0;
      uart_tx_q    <= 1'b1;
    end else begin
      tx_state_q   <= tx_state_d;
      tx_bit_cnt_q <= tx_bit_cnt_d;
      tx_shift_q   <= tx_shift_d;
      tx_busy_q    <= tx_busy_d;
      tx_done_q    <= tx_done_d;
      uart_tx_q    <= uart_tx_d;
    end
  end

endmodule
