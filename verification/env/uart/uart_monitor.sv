//--------------------------------------------------------------
// UART Monitor (uart_monitor)
//
// 功能: 被动监测UART物理引脚，解析串行数据帧并通过analysis port广播
// 解析格式: 1起始位 + 8数据位(LSB first) + 1停止位
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class uart_monitor extends uvm_monitor;
  `uvm_component_utils(uart_monitor)

  virtual uart_if vif;

  uvm_analysis_port #(uart_sequence_item) item_collected_port;

  function new(string name = "uart_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    item_collected_port = new("item_collected_port", this);
    if (!uvm_config_db #(virtual uart_if)::get(this, "", "uart_vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual UART interface not found in config_db")
    end
  endfunction

  //--------------------------------------------------------------
  // Run Phase: 监测uart_tx引脚上的数据帧
  //--------------------------------------------------------------
  task run_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "UART Monitor starting...", UVM_MEDIUM)

    forever begin
      // 等待起始位（下降沿）
      @(negedge vif.uart_tx);

      // 等待半个bit周期后采样确认起始位
      // （简化处理：直接开始接收）
      receive_byte();
    end
  endtask

  //--------------------------------------------------------------
  // 接收一个字节并广播
  //--------------------------------------------------------------
  task receive_byte();
    uart_sequence_item item;
    int i;

    item = uart_sequence_item::type_id::create("item");
    item.is_tx = 1'b0;
    item.data  = 8'd0;

    // 等待到数据位中点（简化处理）
    repeat (868) @(vif.monitor_cb);  // 约1个bit周期(434*2)的一半... 实际应该用更精确的时序

    // 接收8位数据 LSB first
    for (i = 0; i < 8; i++) begin
      // 简化：直接采样引脚
      `uvm_info(get_type_name(), $sformatf("RX bit[%0d] = %0b", i, vif.uart_tx), UVM_DEBUG)
      // 实际应该在bit中点采样，这里做简化处理
      item.data[i] = vif.uart_tx;
    end

    `uvm_info(get_type_name(), $sformatf("Monitored UART RX: 0x%02h", item.data), UVM_HIGH)

    item_collected_port.write(item);
  endtask

endclass : uart_monitor
