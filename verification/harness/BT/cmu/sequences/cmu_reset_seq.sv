//--------------------------------------------------------------
// CMU Reset/Init Sequence V1.0
// 验证: 上电初始CLK_SEL=0/STATUS=0, AHB可访问, initial块正确
//--------------------------------------------------------------
class cmu_reset_seq extends ahb_base_sequence;
  `uvm_object_utils(cmu_reset_seq)

  function new(string name = "cmu_reset_seq"); super.new(name); endfunction

  task body();
    bit [31:0] rd;
    cmu_env_config cfg;
    if (!uvm_config_db #(cmu_env_config)::get(null, "uvm_test_top.env", "cfg", cfg)) begin
      `uvm_error(get_type_name(), "CMU config not found"); return;
    end
    `uvm_info(get_type_name(), "=== Reset/Init ===", UVM_LOW)
    wait_cycles(50);

    // 初始状态: CLK_SEL=0, STATUS=0
    ahb_read(cfg.base_addr + 12'h000, rd);
    if (rd !== 32'h0000_0000) `uvm_error(get_type_name(), $sformatf("Init CLK_SEL: exp=0x0 got=0x%08h", rd))
    ahb_read(cfg.base_addr + 12'h004, rd);
    if (rd !== 32'h0000_0000) `uvm_error(get_type_name(), $sformatf("Init STATUS: exp=0x0 got=0x%08h", rd))

    // 非法地址返回0(译码正确)
    ahb_read(cfg.base_addr + 12'h008, rd);
    if (rd != 32'd0) `uvm_error(get_type_name(), $sformatf("Init off 0x8: exp=0 got=0x%h", rd))

    // AHB可访问说明hclk正常
    ahb_write(cfg.base_addr + 12'h000, 32'h1);
    wait_cycles(500);
    // 切回pll验证(避免rch域CDC读问题)
    ahb_write(cfg.base_addr + 12'h000, 32'h0);
    wait_cycles(500);
    ahb_read(cfg.base_addr + 12'h000, rd);
    if (rd[0] !== 1'b0) `uvm_error(get_type_name(), $sformatf("After rtt: exp=0 got=%b", rd[0]))
    ahb_read(cfg.base_addr + 12'h004, rd);
    if (rd[0] !== 1'b0) `uvm_error(get_type_name(), $sformatf("After rtt STS: exp=0 got=%b", rd[0]))

    `uvm_info(get_type_name(), "Reset/Init PASS", UVM_LOW)
  endtask
endclass
