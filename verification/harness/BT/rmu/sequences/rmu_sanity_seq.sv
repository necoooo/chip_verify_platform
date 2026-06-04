// RMU Sanity Sequence (rmu_sanity_seq) V1.0
// 验证: 读RMU_SRST默认值=0x1F(全部释放), 读RMU_STATUS
class rmu_sanity_seq extends ahb_base_sequence;
  `uvm_object_utils(rmu_sanity_seq)
  task body();
    bit [31:0] rd;
    rmu_env_config cfg;
    if (!uvm_config_db #(rmu_env_config)::get(null, "uvm_test_top.env", "cfg", cfg)) begin
      `uvm_error(get_type_name(), "RMU config not found"); return;
    end
    `uvm_info(get_type_name(), "=== RMU Sanity ===", UVM_LOW)
    wait_cycles(10);
    ahb_read(cfg.base_addr + 12'h00, rd);
    `uvm_info(get_type_name(), $sformatf("RMU_SRST = 0x%08h (expect 0x1F)", rd), UVM_LOW)
    if (rd[4:0] != 5'b11111)
      `uvm_error(get_type_name(), $sformatf("RMU_SRST default mismatch: got 0x%h", rd[4:0]))
    ahb_read(cfg.base_addr + 12'h04, rd);
    `uvm_info(get_type_name(), $sformatf("RMU_STATUS = 0x%08h", rd), UVM_LOW)
    `uvm_info(get_type_name(), "RMU Sanity PASS", UVM_LOW)
  endtask
  function new(string name = "rmu_sanity_seq"); super.new(name); endfunction
endclass
