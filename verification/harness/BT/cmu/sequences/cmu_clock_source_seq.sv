// CMU Clock Source V1.3: 内联@(posedge cfg.ahb_vif.hclk)测量频率
class cmu_clock_source_seq extends ahb_base_sequence;
  `uvm_object_utils(cmu_clock_source_seq)
  rand int num_iterations;
  constraint c_iter { num_iterations inside {[5:20]}; }
  function new(string name = "cmu_clock_source_seq"); super.new(name); endfunction

  task body();
    bit [31:0] rd;
    bit target;
    real freq, t0, t1;
    cmu_env_config cfg;
    if (!uvm_config_db #(cmu_env_config)::get(null, "uvm_test_top.env", "cfg", cfg)) begin
      `uvm_error(get_type_name(), "CMU config not found"); return;
    end
    `uvm_info(get_type_name(), $sformatf("=== Clock Source V1.3: %0d iters ===", num_iterations), UVM_LOW)
    wait_cycles(50);

    ahb_read(cfg.base_addr + 12'h000, rd);
    if (rd[0] !== 1'b0) `uvm_error(get_type_name(), $sformatf("Def CLK: got=%b", rd[0]))
    t0=$realtime; repeat(100) @(posedge cfg.ahb_vif.hclk); t1=$realtime;
    freq=100.0*1000.0/(t1-t0);
    `uvm_info(get_type_name(), $sformatf("PLL freq: %.1f MHz (exp ~50)", freq), UVM_LOW)
    if (freq < 40.0 || freq > 60.0) `uvm_error(get_type_name(), $sformatf("PLL freq bad: %.1f", freq))

    ahb_write(cfg.base_addr + 12'h000, 32'h1); wait_cycles(500);
    t0=$realtime; repeat(100) @(posedge cfg.ahb_vif.hclk); t1=$realtime;
    freq=100.0*1000.0/(t1-t0);
    `uvm_info(get_type_name(), $sformatf("RCH freq: %.1f MHz (exp ~16)", freq), UVM_LOW)
    if (freq < 12.0 || freq > 20.0) `uvm_error(get_type_name(), $sformatf("RCH freq bad: %.1f", freq))

    ahb_write(cfg.base_addr + 12'h000, 32'h0); wait_cycles(500);
    ahb_read(cfg.base_addr + 12'h000, rd);
    if (rd[0] !== 1'b0) `uvm_error(get_type_name(), $sformatf("Back pll: got=%b", rd[0]))

    for (int i = 0; i < num_iterations; i++) begin
      target = $urandom_range(0, 1);
      ahb_write(cfg.base_addr + 12'h000, {31'h0, target});
      wait_cycles(500 + $urandom_range(0, 500));
      ahb_write(cfg.base_addr + 12'h000, 32'h0);
      wait_cycles(500 + $urandom_range(0, 500));
      ahb_read(cfg.base_addr + 12'h000, rd);
      if (rd[0] !== 1'b0) `uvm_error(get_type_name(), $sformatf("i%0d: exp=0 got=%b", i, rd[0]))
    end
    `uvm_info(get_type_name(), "Clock Source PASS", UVM_LOW)
  endtask
endclass
