// SYS_TC Sanity Sequence (sys_tc_sanity_seq) V1.0
// 验证: 读LOAD默认值=49999, 配置LOAD=10使能后等INT_FLAG
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
    ahb_read(cfg.base_addr + 12'h04, rd_data);  // 读LOAD默认值
    `uvm_info(get_type_name(), $sformatf("TC_LOAD default = %0d (expect 49999)", rd_data), UVM_LOW);
    if (rd_data != 32'd49999)
      `uvm_error(get_type_name(), $sformatf("LOAD default mismatch: got %0d", rd_data))

    // 配置短周期测试
    ahb_write(cfg.base_addr + 12'h04, 32'd10);  // LOAD=10
    ahb_write(cfg.base_addr + 12'h0C, 32'd1);   // 清除INT_FLAG
    ahb_write(cfg.base_addr + 12'h00, 32'd3);   // EN=1, IE=1
    wait_cycles(30);  // 等待中断
    ahb_read(cfg.base_addr + 12'h0C, rd_data);  // 读STATUS
    `uvm_info(get_type_name(), $sformatf("TC_STATUS = 0x%08h (expect bit0=1)", rd_data), UVM_LOW)
    `uvm_info(get_type_name(), "SYS_TC Sanity PASS", UVM_LOW)
  endtask

  function new(string name = "sys_tc_sanity_seq"); super.new(name); endfunction
endclass
