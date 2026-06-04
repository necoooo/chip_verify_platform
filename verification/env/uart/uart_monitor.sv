//--------------------------------------------------------------
// UART Monitor (uart_monitor) V1.1
// V1.1: 改用#delay中点采样, 移除clocking block依赖
//--------------------------------------------------------------

class uart_monitor extends uvm_monitor;
  `uvm_component_utils(uart_monitor)

  virtual uart_if vif;
  uvm_analysis_port #(uart_sequence_item) item_collected_port;

  int baud_div = 433;
  int bit_period_ns, half_bit_ns;

  function new(string name = "uart_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    item_collected_port = new("item_collected_port", this);
    if (!uvm_config_db #(virtual uart_if)::get(this, "", "uart_vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual UART interface not found in config_db")
    end
    bit_period_ns = (baud_div + 1) * 20;
    half_bit_ns   = bit_period_ns / 2;
  endfunction

  task run_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "UART Monitor starting...", UVM_MEDIUM)
    forever begin
      @(negedge vif.uart_tx);           // 检测起始位
      #(half_bit_ns * 1ns);             // 到起始位中点
      receive_byte();
    end
  endtask

  // 在bit中点采样8位数据 (LSB first)
  task receive_byte();
    uart_sequence_item item;
    int i;
    item = uart_sequence_item::type_id::create("item");
    item.is_tx = 1'b0;

    #(bit_period_ns * 1ns);             // 跳到bit0中点
    for (i = 0; i < 8; i++) begin
      item.data[i] = vif.uart_tx;
      #(bit_period_ns * 1ns);           // 下一bit中点
    end

    `uvm_info(get_type_name(), $sformatf("Monitored UART_TX: 0x%02h", item.data), UVM_HIGH)
    item_collected_port.write(item);
  endtask

endclass : uart_monitor
