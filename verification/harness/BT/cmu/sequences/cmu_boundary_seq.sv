// CMU Boundary V1.2: 随机快速切换+不变切换+长等待pll域验证
class cmu_boundary_seq extends ahb_base_sequence;
  `uvm_object_utils(cmu_boundary_seq)
  rand int num_iterations;
  constraint c_iter { num_iterations inside {[10:25]}; }
  function new(string name = "cmu_boundary_seq"); super.new(name); endfunction
  task body();
    bit [31:0] rd;
    bit cur, target;
    cmu_env_config cfg;
    if (!uvm_config_db #(cmu_env_config)::get(null, "uvm_test_top.env", "cfg", cfg)) begin
      `uvm_error(get_type_name(), "CMU config not found"); return;
    end
    `uvm_info(get_type_name(), $sformatf("=== Boundary: %0d random iters ===", num_iterations), UVM_LOW)
    wait_cycles(50);
    ahb_read(cfg.base_addr + 12'h000, rd);
    cur = rd[0];
    ahb_write(cfg.base_addr + 12'h000, {31'h0, cur});
    wait_cycles(100);
    ahb_read(cfg.base_addr + 12'h000, rd);
    if (rd[0] !== cur) `uvm_error(get_type_name(), $sformatf("No-change: exp=%b got=%b", cur, rd[0]))
    for (int i = 0; i < num_iterations; i++) begin
      target = $urandom_range(0, 1);
      ahb_write(cfg.base_addr + 12'h000, {31'h0, target});
      wait_cycles($urandom_range(3, 20));
    end
    ahb_write(cfg.base_addr + 12'h000, 32'h0);
    wait_cycles(500);
    ahb_read(cfg.base_addr + 12'h000, rd);
    if (rd[0] !== 1'b0) `uvm_error(get_type_name(), $sformatf("After rapid: exp=0 got=%b", rd[0]))
    `uvm_info(get_type_name(), "Boundary PASS", UVM_LOW)
  endtask
endclass
