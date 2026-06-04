//--------------------------------------------------------------
// UART Agent (uart_agent) V1.2
// V1.2: 修复is_active类型, 完整sequencer/driver/monitor架构
//--------------------------------------------------------------

class uart_agent extends uvm_agent;
  `uvm_component_utils(uart_agent)

  uart_sequencer sequencer;
  uart_driver    driver;
  uart_monitor   monitor;

  function new(string name = "uart_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = uart_monitor::type_id::create("monitor", this);
    if (get_is_active()) begin
      sequencer = uart_sequencer::type_id::create("sequencer", this);
      driver    = uart_driver::type_id::create("driver", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active()) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction

endclass : uart_agent
