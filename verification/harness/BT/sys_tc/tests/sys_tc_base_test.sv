// SYS_TC Base Test (sys_tc_base_test) V1.0
class sys_tc_base_test extends uvm_test;
  `uvm_component_utils(sys_tc_base_test)
  sys_tc_env        env;
  sys_tc_env_config cfg;

  function new(string name = "sys_tc_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = sys_tc_env_config::type_id::create("cfg");
    if (!uvm_config_db #(virtual ahb_if)::get(this, "", "ahb_vif", cfg.ahb_vif))
      `uvm_fatal(get_type_name(), "AHB vif not found")
    uvm_config_db #(sys_tc_env_config)::set(this, "env", "cfg", cfg);
    env = sys_tc_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase); uvm_top.print_topology();
  endfunction
endclass
