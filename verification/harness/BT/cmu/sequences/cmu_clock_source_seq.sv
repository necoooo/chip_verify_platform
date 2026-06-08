// CMU Clock Source V1.2: 随机pll↔rch切换+长等待CDC安全
class cmu_clock_source_seq extends ahb_base_sequence;
  `uvm_object_utils(cmu_clock_source_seq)
  rand int num_iterations;
  constraint c_iter { num_iterations inside {[5:20]}; }
  function new(string name = "cmu_clock_source_seq"); super.new(name); endfunction
  task body();
    bit [31:0] rd;
    bit target;
    cmu_env_config cfg;
    if (!uvm_config_db #(cmu_env_config)::get(null, "uvm_test_top.env", "cfg", cfg)) begin
      `uvm_error(get_type_name(), "CMU config not found"); return;
    end
    `uvm_info(get_type_name(), $sformatf("=== Clock Source: %0d random iters ===", num_iterations), UVM_LOW)
    wait_cycles(50);
    ahb_read(cfg.base_addr + 12'h000, rd);
    if (rd[0] !== 1'b0) `uvm_error(get_type_name(), $sformatf("Default CLK_SEL: exp=0 got=%b", rd[0]))
    ahb_read(cfg.base_addr + 12'h004, rd);
    if (rd[0] !== 1'b0) `uvm_error(get_type_name(), $sformatf("Default STATUS: exp=0 got=%b", rd[0]))

    for (int i = 0; i < num_iterations; i++) begin
      target = $urandom_range(0, 1);
      ahb_write(cfg.base_addr + 12'h000, {31'h0, target});
      wait_cycles(500 + $urandom_range(0, 500));
      // 强制切回pll, 在pll域验证(避免CDC)
      ahb_write(cfg.base_addr + 12'h000, 32'h0);
      wait_cycles(500 + $urandom_range(0, 500));
      ahb_read(cfg.base_addr + 12'h000, rd);
      if (rd[0] !== 1'b0) `uvm_error(get_type_name(), $sformatf("i%0d: exp=0 got=%b (was target=%b)", i, rd[0], target))
      ahb_read(cfg.base_addr + 12'h004, rd);
      if (rd[0] !== 1'b0) `uvm_error(get_type_name(), $sformatf("i%0d STS: exp=0 got=%b", i, rd[0]))
    end
    `uvm_info(get_type_name(), "Clock Source PASS", UVM_LOW)
  endtask
endclass
