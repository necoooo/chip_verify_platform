// UART Sanity Sequence V2.1
// 验证: CTRL/BAUD默认值 + TX发送 + 回环RX接收
class uart_sanity_seq extends ahb_base_sequence;
  `uvm_object_utils(uart_sanity_seq)
  function new(string name = "uart_sanity_seq"); super.new(name); endfunction
  task body();
    bit [31:0] rd;
    uart_env_config cfg;
    if (!uvm_config_db #(uart_env_config)::get(null, "uvm_test_top.env", "cfg", cfg)) begin
      `uvm_error(get_type_name(), "UART config not found"); return;
    end
    `uvm_info(get_type_name(), "=== UART Sanity ===", UVM_LOW)
    wait_cycles(100);

    ahb_read(cfg.base_addr + 12'h00, rd);
    if (rd[0] !== 1'b1 || rd[1] !== 1'b1)
      `uvm_error(get_type_name(), $sformatf("CTRL default: got 0x%h", rd))
    ahb_read(cfg.base_addr + 12'h04, rd);
    if (rd[15:0] != 16'd433)
      `uvm_error(get_type_name(), $sformatf("BAUD default: got %0d", rd[15:0]))

    // TX: 写TXD=0x55 → 回环 → RX接收
    ahb_write(cfg.base_addr + 12'h0C, 32'h55);
    wait_cycles(10000);
    ahb_read(cfg.base_addr + 12'h08, rd);
    if (rd[1] !== 1'b1)
      `uvm_error(get_type_name(), $sformatf("TX_DONE: STATUS=0x%h", rd))
    if (rd[2] !== 1'b1)
      `uvm_error(get_type_name(), $sformatf("RX_VALID: STATUS=0x%h", rd))

    `uvm_info(get_type_name(), "UART Sanity PASS", UVM_LOW)
  endtask
endclass
