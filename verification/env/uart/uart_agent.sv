//--------------------------------------------------------------
// UART Agent (uart_agent)
//
// 功能: 封装UART物理层验证组件(driver/monitor)
// 用途: 系统级验证时驱动/监测UART物理引脚
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class uart_agent extends uvm_agent;
  `uvm_component_utils(uart_agent)

  uart_driver  driver;
  uart_monitor monitor;

  bit is_active = 1;

  function new(string name = "uart_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = uart_monitor::type_id::create("monitor", this);
    if (is_active) begin
      driver = uart_driver::type_id::create("driver", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (is_active) begin
      // driver.seq_item_port已通过sequencer连接, monitor通过analysis_port广播
    end
  endfunction

endclass : uart_agent
