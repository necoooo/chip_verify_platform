// SYS_TC Sanity Sequence (sys_tc_sanity_seq) V1.1
// 验证: 读LOAD默认值, 使能后等计数器到零 → 自动检查INT_FLAG
// V1.1: 修复伪PASS — STATUS寄存器增加自动对比, 等待50010周期
class sys_tc_sanity_seq extends ahb_base_sequence;
  `uvm_object_utils(sys_tc_sanity_seq)

  task body();
    bit [31:0] rd_data;
    sys_tc_env_config cfg;
    if (!uvm_config_db #(sys_tc_env_config)::get(null, "uvm_test_top.env", "cfg", cfg)) begin
      `uvm_error(get_type_name(), "SYS_TC config not found"); return;
    end
    `uvm_info(get_type_name(), "=== SYS_TC Sanity ===", UVM_LOW)
    wait_cycles(10);

    // 1. 读LOAD默认值 (reset=49999)
    ahb_read(cfg.base_addr + 12'h04, rd_data);
    `uvm_info(get_type_name(), $sformatf("TC_LOAD default = %0d (expect 49999)", rd_data), UVM_LOW);
    if (rd_data != 32'd49999)
      `uvm_error(get_type_name(), $sformatf("LOAD default mismatch: got %0d", rd_data))

    // 2. 读CTRL默认值 (EN=0, IE=0)
    ahb_read(cfg.base_addr + 12'h00, rd_data);
    if (rd_data[0] !== 1'b0 || rd_data[1] !== 1'b0)
      `uvm_error(get_type_name(), $sformatf("CTRL default mismatch: got 0x%h (expect 0)", rd_data))

    // 3. 读STATUS默认值 (INT_FLAG=0)
    ahb_read(cfg.base_addr + 12'h0C, rd_data);
    if (rd_data[0] !== 1'b0)
      `uvm_error(get_type_name(), $sformatf("STATUS default mismatch: got 0x%h (expect 0)", rd_data))

    // 4. 配置EN=1使能计数, 等待计数器从49999减到0 (需50000+周期)
    ahb_write(cfg.base_addr + 12'h00, 32'd1);   // EN=1, IE=0
    wait_cycles(50010);
    ahb_read(cfg.base_addr + 12'h0C, rd_data);
    `uvm_info(get_type_name(), $sformatf("STATUS after 50000+ cycles = 0x%h", rd_data), UVM_LOW);
    if (rd_data[0] !== 1'b1)
      `uvm_error(get_type_name(), $sformatf("INT_FLAG not set after timeout: STATUS=0x%h", rd_data))

    `uvm_info(get_type_name(), "SYS_TC Sanity PASS", UVM_LOW)
  endtask

  function new(string name = "sys_tc_sanity_seq"); super.new(name); endfunction
endclass
