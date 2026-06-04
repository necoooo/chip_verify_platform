// UART RX Sequence (uart_rx_seq) V1.0
// 功能: uart_driver发送一个字节到DUT RX引脚
class uart_rx_seq extends uvm_sequence #(uart_sequence_item);
  `uvm_object_utils(uart_rx_seq)
  bit [7:0] data = 8'hAA;
  function new(string name = "uart_rx_seq"); super.new(name); endfunction
  task body();
    req = uart_sequence_item::type_id::create("req");
    req.is_tx = 1'b1;
    req.data  = data;
    start_item(req);
    finish_item(req);
  endtask
endclass
