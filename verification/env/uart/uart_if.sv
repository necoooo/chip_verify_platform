//--------------------------------------------------------------
// UART物理层接口 (uart_if) V1.2
// V1.2: 添加hclk用于driver/monitor时钟同步
//--------------------------------------------------------------

interface uart_if(input logic hclk);
  logic uart_tx;   // UART发送引脚 (DUT输出, monitor监控)
  logic uart_rx;   // UART接收引脚 (DUT输入, driver驱动)
  logic tx_int;    // 发送完成中断
  logic rx_int;    // 接收完成中断

endinterface : uart_if
