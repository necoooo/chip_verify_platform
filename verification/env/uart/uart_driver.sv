//--------------------------------------------------------------
// UART Driver (uart_driver)
//
// 功能: 驱动UART物理引脚(uart_rx)，模拟外部设备发送串行数据
// 协议: 1起始位(0) + 8数据位(LSB first) + 1停止位(1)
// 波特率: 由UART_BAUD计算，默认115200@50MHz
// 版本: V1.0 2026.05.29
//--------------------------------------------------------------

class uart_driver extends uvm_driver #(uart_sequence_item);
  `uvm_component_utils(uart_driver)

  virtual uart_if vif;

  int baud_div = 433;      // 波特率分频(50MHz/115200-1)
  int tick_half;           // 半个bit周期的hclk数

  function new(string name = "uart_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual uart_if)::get(this, "", "uart_vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual UART interface not found in config_db")
    end
    tick_half = (baud_div + 1) / 2;
  endfunction

  //--------------------------------------------------------------
  // Run Phase: 驱动UART数据帧
  //--------------------------------------------------------------
  task run_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "UART Driver starting...", UVM_MEDIUM)
    vif.uart_rx <= 1'b1;  // 空闲状态为高

    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_type_name(), $sformatf("Driving UART TX: 0x%02h", req.data), UVM_HIGH)

      if (req.is_tx) begin
        send_byte(req.data);
      end

      seq_item_port.item_done();
    end
  endtask

  //--------------------------------------------------------------
  // 发送一个字节 (8N1格式)
  //--------------------------------------------------------------
  task send_byte(input [7:0] data);
    int i;
    // 起始位
    vif.uart_rx <= 1'b0;
    wait_bit_period();

    // 8位数据 LSB first
    for (i = 0; i < 8; i++) begin
      vif.uart_rx <= data[i];
      wait_bit_period();
    end

    // 停止位
    vif.uart_rx <= 1'b1;
    wait_bit_period();
  endtask

  //--------------------------------------------------------------
  // 等待一个bit周期(baud_div+1个hclk周期)
  //--------------------------------------------------------------
  task wait_bit_period();
    repeat (baud_div + 1) @(vif.monitor_cb);
  endtask

endclass : uart_driver
