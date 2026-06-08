// CMU CLK_SEL V1.2: 随机合法/非法值+长等待CDC安全
class cmu_clk_sel_seq extends ahb_base_sequence;
  `uvm_object_utils(cmu_clk_sel_seq)
  rand int num_iterations;
  constraint c_iter { num_iterations inside {[10:30]}; }
  function new(string name = "cmu_clk_sel_seq"); super.new(name); endfunction
  task body();
    bit [31:0] rd, wdata;
    bit v;
    cmu_env_config cfg;
    if (!uvm_config_db #(cmu_env_config)::get(null, "uvm_test_top.env", "cfg", cfg)) begin
      `uvm_error(get_type_name(), "CMU config not found"); return;
    end
    `uvm_info(get_type_name(), $sformatf("=== CLK_SEL: %0d random iters ===", num_iterations), UVM_LOW)
    wait_cycles(50);
    ahb_read(cfg.base_addr + 12'h000, rd);
    if (rd[0] !== 1'b0) `uvm_error(get_type_name(), "Def bit0!=0")
    if (rd[31:1] != 31'd0) `uvm_error(get_type_name(), $sformatf("Def high bits: 0x%08h", rd))
    for (int i = 0; i < num_iterations; i++) begin
      if ($urandom_range(0, 1)) begin
        v = $urandom_range(0, 1);
        ahb_write(cfg.base_addr + 12'h000, {31'h0, v});
        wait_cycles(500 + $urandom_range(0, 500));
        ahb_write(cfg.base_addr + 12'h000, 32'h0);
        wait_cycles(500 + $urandom_range(0, 500));
        ahb_read(cfg.base_addr + 12'h000, rd);
        if (rd[0] !== 1'b0) `uvm_error(get_type_name(), $sformatf("i%0d: exp=0 got=%b (wrote=%b)", i, rd[0], v))
      end else begin
        // 非法值: 高bit随机非零, bit0保持0(不触发切换)
        wdata = ($urandom() & 32'hFFFF_FFFE);  // bit0=0, 高bit随机
        ahb_write(cfg.base_addr + 12'h000, wdata);
        wait_cycles(50);
        ahb_read(cfg.base_addr + 12'h000, rd);
        if (rd[31:1] != 31'd0) `uvm_error(get_type_name(), $sformatf("i%0d high bits: 0x%h", i, rd))
        if (rd[0] !== 1'b0) `uvm_error(get_type_name(), $sformatf("i%0d bit0 should be 0: got=%b", i, rd[0]))
      end
    end
    `uvm_info(get_type_name(), "CLK_SEL PASS", UVM_LOW)
  endtask
endclass
