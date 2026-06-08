// CMU AHB Interface V1.1: 随机读写+地址译码+STATUS只读(pll模式)
class cmu_ahb_seq extends ahb_base_sequence;
  `uvm_object_utils(cmu_ahb_seq)
  rand int num_iterations;
  constraint c_iter { num_iterations inside {[15:40]}; }
  function new(string name = "cmu_ahb_seq"); super.new(name); endfunction
  task body();
    bit [31:0] rd, orig;
    cmu_env_config cfg;
    if (!uvm_config_db #(cmu_env_config)::get(null, "uvm_test_top.env", "cfg", cfg)) begin
      `uvm_error(get_type_name(), "CMU config not found"); return;
    end
    `uvm_info(get_type_name(), $sformatf("=== AHB IF: %0d random iters ===", num_iterations), UVM_LOW)
    wait_cycles(50);
    ahb_read(cfg.base_addr + 12'h004, rd);
    orig = rd;
    ahb_write(cfg.base_addr + 12'h004, 32'hFFFF_FFFF);
    ahb_read(cfg.base_addr + 12'h004, rd);
    if (rd !== orig) `uvm_error(get_type_name(), $sformatf("STATUS RO fail: orig=0x%h got=0x%h", orig, rd))
    for (int off = 0; off < 16; off = off + 4) begin
      ahb_read(cfg.base_addr + off[11:0], rd);
      case (off) 0, 4: ; default: if (rd != 32'd0) `uvm_error(get_type_name(), $sformatf("Off 0x%0h: exp=0 got=0x%h", off, rd)) endcase
    end
    for (int i = 0; i < num_iterations; i++) begin
      if ($urandom_range(0, 1))
        ahb_read(cfg.base_addr + ($urandom_range(0,1) ? 12'h000 : 12'h004), rd);
      else
        ahb_write(cfg.base_addr + 12'h000, 32'h0);
      wait_cycles($urandom_range(0, 30));
    end
    `uvm_info(get_type_name(), "AHB IF PASS", UVM_LOW)
  endtask
endclass
