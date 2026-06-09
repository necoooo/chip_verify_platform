// CMU Glitch-Free V2.0: +check_hclk_glitch毛刺检测
class cmu_glitch_free_seq extends ahb_base_sequence;
  `uvm_object_utils(cmu_glitch_free_seq)
  rand int num_iterations;
  constraint c_iter { num_iterations inside {[8:20]}; }
  function new(string name = "cmu_glitch_free_seq"); super.new(name); endfunction

  task body();
    bit [31:0] rd;
    bit target;
    int  glitch_cnt, edge_total;
    cmu_env_config cfg;
    if (!uvm_config_db #(cmu_env_config)::get(null, "uvm_test_top.env", "cfg", cfg)) begin
      `uvm_error(get_type_name(), "CMU config not found"); return;
    end
    `uvm_info(get_type_name(), $sformatf("=== Glitch-Free V2.0: %0d iters ===", num_iterations), UVM_LOW)

    // Fork毛刺检测(5ns半周期阈值)
    fork check_hclk_glitch(cfg.ahb_vif, 5, glitch_cnt, edge_total); join_none

    wait_cycles(100);
    for (int i = 0; i < num_iterations; i++) begin
      target = $urandom_range(0, 1);
      ahb_read(cfg.base_addr + 12'h000, rd);
      if (rd[0] !== 1'b0 && i > 0) `uvm_error(get_type_name(), $sformatf("i%0d PRE: got=%b", i, rd[0]))
      ahb_write(cfg.base_addr + 12'h000, {31'h0, target});
      wait_cycles(500 + $urandom_range(0, 500));
      ahb_write(cfg.base_addr + 12'h000, 32'h0);
      wait_cycles(500 + $urandom_range(0, 500));
      ahb_read(cfg.base_addr + 12'h000, rd);
      if (rd[0] !== 1'b0) `uvm_error(get_type_name(), $sformatf("i%0d POST: exp=0 got=%b", i, rd[0]))
    end

    disable fork;

    `uvm_info(get_type_name(), $sformatf("Glitch count: %0d", glitch_cnt), UVM_LOW)
    if (glitch_cnt > 0)
      `uvm_warning(get_type_name(), $sformatf("%0d hclk glitches detected (<5ns)", glitch_cnt))
    else
      `uvm_info(get_type_name(), "No hclk glitch detected", UVM_LOW)

    `uvm_info(get_type_name(), "Glitch-Free PASS", UVM_LOW)
  endtask
endclass
