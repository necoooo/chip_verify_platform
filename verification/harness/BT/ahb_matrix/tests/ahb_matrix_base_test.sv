// AHB Matrix Base Test (ahb_matrix_base_test) V1.0
class ahb_matrix_base_test extends uvm_test;
  `uvm_component_utils(ahb_matrix_base_test)
  ahb_matrix_env env; ahb_matrix_env_config cfg;
  function new(string n = "ahb_matrix_base_test", uvm_component p = null); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = ahb_matrix_env_config::type_id::create("cfg");
    if (!uvm_config_db #(virtual ahb_if)::get(this, "", "ahb_vif", cfg.ahb_vif))
      `uvm_fatal(get_type_name(), "AHB vif not found")
    uvm_config_db #(ahb_matrix_env_config)::set(this, "env", "cfg", cfg);
    env = ahb_matrix_env::type_id::create("env", this);
  endfunction
endclass
