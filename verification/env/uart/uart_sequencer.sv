//--------------------------------------------------------------
// UART Sequencer (uart_sequencer)
//
// 功能: UVM sequencer，管理uart_sequence_item的调度
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class uart_sequencer extends uvm_sequencer #(uart_sequence_item);
  `uvm_component_utils(uart_sequencer)

  function new(string name = "uart_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass : uart_sequencer
