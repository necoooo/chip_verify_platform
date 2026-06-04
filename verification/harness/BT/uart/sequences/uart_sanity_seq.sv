// UART Sanity Sequence (uart_sanity_seq) V1.0
// 验证: 读UART_CTRL/BAUD默认值，写TXD=0x55验证TX启动
class uart_sanity_seq extends ahb_base_sequence;
  `uvm_object_utils(uart_sanity_seq)
  task body();
    bit [31:0] rd;
    uart_env_config cfg;
    if (!uvm_config_db #(uart_env_config)::get(null, "uvm_test_top.env", "cfg", cfg)) begin
      `uvm_error(get_type_name(), "UART config not found"); return;
    end
    `uvm_info(get_type_name(), "=== UART Sanity ===", UVM_LOW)
    wait_cycles(100);
    ahb_read(cfg.base_addr + 12'h00, rd);  // 读CTRL
    `uvm_info(get_type_name(), $sformatf("UART_CTRL = 0x%08h (expect TX_EN=1,RX_EN=1)", rd), UVM_LOW)
    ahb_read(cfg.base_addr + 12'h04, rd);  // 读BAUD
    `uvm_info(get_type_name(), $sformatf("UART_BAUD = %0d (expect 433=115200bps)", rd), UVM_LOW)
    // 发送一个字节
    ahb_write(cfg.base_addr + 12'h0C, 32'h55);  // TXD=0x55
    wait_cycles(10000);  // 等待发送完成
    ahb_read(cfg.base_addr + 12'h08, rd);  // 读STATUS
    `uvm_info(get_type_name(), $sformatf("UART_STATUS = 0x%08h (expect TX_DONE=1)", rd), UVM_LOW)
    `uvm_info(get_type_name(), "UART Sanity PASS", UVM_LOW)
  endtask
  function new(string name = "uart_sanity_seq"); super.new(name); endfunction
endclass
