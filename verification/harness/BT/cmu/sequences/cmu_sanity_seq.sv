class cmu_sanity_seq extends ahb_base_sequence;
  `uvm_object_utils(cmu_sanity_seq)
  function new(string name = "cmu_sanity_seq"); super.new(name); endfunction
  task body();
    bit [31:0] rd;
    cmu_env_config cfg;
    if (!uvm_config_db #(cmu_env_config)::get(null, "uvm_test_top.env", "cfg", cfg)) begin
      `uvm_error(get_type_name(), "CMU config not found"); return;
    end
    `uvm_info(get_type_name(), "=== CMU Sanity ===", UVM_LOW)
    wait_cycles(100);
    ahb_read(cfg.base_addr + 12'h000, rd);
    if (rd[0] !== 1'b0) `uvm_error(get_type_name(), $sformatf("CLK_SEL default: got %0b expect 0", rd[0]))
    ahb_write(cfg.base_addr + 12'h000, 32'h1);
    wait_cycles(200);
    ahb_read(cfg.base_addr + 12'h000, rd);
    if (rd[0] !== 1'b1) `uvm_error(get_type_name(), $sformatf("WR 1 fail: got %0b", rd[0]))
    `uvm_info(get_type_name(), "=== CMU Sanity PASS ===", UVM_LOW)
  endtask
endclass
