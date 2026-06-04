// SRAM_ECC Sanity Sequence (sram_ecc_sanity_seq) V1.1
// V1.1: 多地址读写测试, 暴露读路径延迟问题
class sram_ecc_sanity_seq extends ahb_base_sequence;
  `uvm_object_utils(sram_ecc_sanity_seq)
  task body();
    bit [31:0] rd;
    sram_ecc_env_config cfg;
    if (!uvm_config_db #(sram_ecc_env_config)::get(null, "uvm_test_top.env", "cfg", cfg)) begin
      `uvm_error(get_type_name(), "SRAM_ECC config not found"); return;
    end
    `uvm_info(get_type_name(), "=== SRAM_ECC Sanity (multi-addr) ===", UVM_LOW)
    wait_cycles(10);

    // 测试多个地址的写入和读回
    ahb_write(cfg.base_addr + 12'h00, 32'hDEAD_BEEF);
    ahb_write(cfg.base_addr + 12'h04, 32'hCAFE_BABE);
    ahb_write(cfg.base_addr + 12'h08, 32'h1234_5678);
    ahb_write(cfg.base_addr + 12'h10, 32'hAAAA_5555);
    ahb_write(cfg.base_addr + 12'h20, 32'hFFFF_0000);
    wait_cycles(5);

    ahb_read(cfg.base_addr + 12'h00, rd);
    if (rd != 32'hDEAD_BEEF)
      `uvm_error(get_type_name(), $sformatf("addr0 FAIL: exp=0xDEAD_BEEF, got=0x%08h", rd))

    ahb_read(cfg.base_addr + 12'h04, rd);
    if (rd != 32'hCAFE_BABE)
      `uvm_error(get_type_name(), $sformatf("addr1 FAIL: exp=0xCAFE_BABE, got=0x%08h", rd))

    ahb_read(cfg.base_addr + 12'h08, rd);
    if (rd != 32'h1234_5678)
      `uvm_error(get_type_name(), $sformatf("addr2 FAIL: exp=0x1234_5678, got=0x%08h", rd))

    ahb_read(cfg.base_addr + 12'h10, rd);
    if (rd != 32'hAAAA_5555)
      `uvm_error(get_type_name(), $sformatf("addr4 FAIL: exp=0xAAAA_5555, got=0x%08h", rd))

    ahb_read(cfg.base_addr + 12'h20, rd);
    if (rd != 32'hFFFF_0000)
      `uvm_error(get_type_name(), $sformatf("addr8 FAIL: exp=0xFFFF_0000, got=0x%08h", rd))

    `uvm_info(get_type_name(), "SRAM_ECC Sanity PASS", UVM_LOW)
  endtask
  function new(string name = "sram_ecc_sanity_seq"); super.new(name); endfunction
endclass
