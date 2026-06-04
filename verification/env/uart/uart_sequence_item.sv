//--------------------------------------------------------------
// UART Sequence Item (uart_sequence_item)
//
// 功能: 定义UART物理层传输事务的数据结构
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class uart_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(uart_sequence_item)

  // 数据字段
  rand bit [7:0]  data;          // 8位数据
  rand bit        parity_en;     // 校验使能（预留）
  rand bit [1:0]  parity_sel;    // 校验选择（预留）

  // 方向
  rand bit        is_tx;         // 1=发送, 0=接收

  // 接收状态
  bit             frame_err;     // 帧错误
  bit             overflow;      // 溢出

  // 波特率（从UART_BAUD寄存器计算）
  int             baud_div = 433;

  constraint c_data_default { data inside {[0:255]}; }

  function new(string name = "uart_sequence_item");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("UART %s: data=0x%02h ('%c')",
                     is_tx ? "TX" : "RX", data, data);
  endfunction

endclass : uart_sequence_item
