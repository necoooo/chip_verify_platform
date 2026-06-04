// SRAM_ECC Base Test (sram_ecc_base_test) V1.0
class sram_ecc_base_test extends uvm_test;
  `uvm_component_utils(sram_ecc_base_test)
  sram_ecc_env env; sram_ecc_env_config cfg;
  function new(string n = "sram_ecc_base_test", uvm_component p = null); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = sram_ecc_env_config::type_id::create("cfg");
    if (!uvm_config_db #(virtual ahb_if)::get(this, "", "ahb_vif", cfg.ahb_vif))
      `uvm_fatal(get_type_name(), "AHB vif not found")
    uvm_config_db #(sram_ecc_env_config)::set(this, "env", "cfg", cfg);
    env = sram_ecc_env::type_id::create("env", this);
  endfunction
endclass
