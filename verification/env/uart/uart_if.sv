//--------------------------------------------------------------
// UART物理层接口 (uart_if)
//
// 功能: 定义UART物理引脚信号，供UART agent的driver/monitor使用
// 用途: 系统级验证时连接UART TX/RX引脚
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

interface uart_if;
  logic uart_tx;   // UART发送引脚
  logic uart_rx;   // UART接收引脚
  logic tx_int;    // 发送完成中断
  logic rx_int;    // 接收完成中断

  //--------------------------------------------------------------
  // Monitor侧时钟块
  //--------------------------------------------------------------
  clocking monitor_cb @(negedge uart_tx or posedge uart_tx);
    input uart_tx;
    input uart_rx;
  endclocking

endinterface : uart_if
