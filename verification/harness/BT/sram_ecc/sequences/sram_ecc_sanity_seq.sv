// SRAM_ECC Sanity Sequence (sram_ecc_sanity_seq) V1.0
class sram_ecc_sanity_seq extends ahb_base_sequence;
  `uvm_object_utils(sram_ecc_sanity_seq)
  task body();
    bit [31:0] rd;
    sram_ecc_env_config cfg;
    if (!uvm_config_db #(sram_ecc_env_config)::get(null, "uvm_test_top.env", "cfg", cfg)) begin
      `uvm_error(get_type_name(), "SRAM_ECC config not found"); return;
    end
    `uvm_info(get_type_name(), "=== SRAM_ECC Sanity ===", UVM_LOW)
    wait_cycles(10);
    ahb_write(cfg.base_addr + 32'h0, 32'hDEAD_BEEF);  // 写地址0
    ahb_read(cfg.base_addr + 32'h0, rd);                // 读回
    if (rd != 32'hDEAD_BEEF)
      `uvm_error(get_type_name(), $sformatf("SRAM sanity FAIL: exp=0xDEAD_BEEF, got=0x%08h", rd))
    else
      `uvm_info(get_type_name(), "SRAM_ECC Sanity PASS", UVM_LOW)
  endtask
  function new(string name = "sram_ecc_sanity_seq"); super.new(name); endfunction
endclass
