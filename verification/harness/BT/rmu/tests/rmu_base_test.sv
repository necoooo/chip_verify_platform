// RMU Base Test (rmu_base_test) V1.0
class rmu_base_test extends uvm_test;
  `uvm_component_utils(rmu_base_test)
  rmu_env env; rmu_env_config cfg;
  function new(string name = "rmu_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = rmu_env_config::type_id::create("cfg");
    if (!uvm_config_db #(virtual ahb_if)::get(this, "", "ahb_vif", cfg.ahb_vif))
      `uvm_fatal(get_type_name(), "AHB vif not found")
    uvm_config_db #(rmu_env_config)::set(this, "env", "cfg", cfg);
    env = rmu_env::type_id::create("env", this);
  endfunction
endclass
