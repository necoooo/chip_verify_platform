//--------------------------------------------------------------
// UART Driver (uart_driver) V1.2
// V1.2: 使用@(posedge vif.hclk)同步时钟, 与DUT baud_tick对齐
//--------------------------------------------------------------

class uart_driver extends uvm_driver #(uart_sequence_item);
  `uvm_component_utils(uart_driver)

  virtual uart_if vif;

  int baud_div = 433;      // (50MHz/115200)-1
  int bit_cycles;          // 每bit的hclk周期数

  function new(string name = "uart_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual uart_if)::get(this, "", "uart_vif", vif)) begin
      `uvm_fatal(get_type_name(), "Virtual UART interface not found in config_db")
    end
    bit_cycles = baud_div + 1;  // 434 cycles @ 50MHz = 8680ns
  endfunction

  task run_phase(uvm_phase phase);
    `uvm_info(get_type_name(), "UART Driver starting...", UVM_MEDIUM)
    vif.uart_rx = 1'b1;  // 空闲

    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(get_type_name(), $sformatf("Driving UART_RX: 0x%02h", req.data), UVM_LOW)
      if (req.is_tx) send_byte(req.data);
      seq_item_port.item_done();
    end
  endtask

  // 发送一个字节 (8N1, LSB first, hclk同步)
  task send_byte(input [7:0] data);
    int i;
    vif.uart_rx = 1'b0;    repeat (bit_cycles) @(posedge vif.hclk);  // 起始位
    for (i = 0; i < 8; i++) begin
      vif.uart_rx = data[i]; repeat (bit_cycles) @(posedge vif.hclk);  // 数据位
    end
    vif.uart_rx = 1'b1;    repeat (bit_cycles) @(posedge vif.hclk);  // 停止位
  endtask

endclass : uart_driver
